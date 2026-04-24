import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PaymentRecord } from './entities/payment-record.entity';
import { RegisterPaymentDto } from './dto/register-payment.dto';
import { User } from '../users/entities/user.entity';

@Injectable()
export class PaymentsService {
  constructor(
    @InjectRepository(PaymentRecord)
    private readonly paymentRecordRepository: Repository<PaymentRecord>,
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
  ) {}

  /**
   * Registers N monthly payment records for a user.
   *
   * Business rules:
   * - Creates N separate PaymentRecord rows (one per month)
   * - membershipExpirationDate advances N anchor-aligned months
   * - Anchor day is preserved from membershipStartDate
   * - If the current expirationDate is in the future, we extend FROM it
   * - If expired or never set, we start FROM today
   */
  async registerPayment(
    userId: string,
    dto: RegisterPaymentDto,
    adminUser: User,
  ): Promise<PaymentRecord[]> {
    const user = await this.usersRepository.findOne({
      where: { id: userId },
      relations: ['gym'],
    });

    if (!user) {
      throw new NotFoundException(`User ${userId} not found`);
    }

    const periodMonths = dto.periodMonths ?? 1;

    // Determine the billing anchor day from membershipStartDate
    const anchorDay = user.membershipStartDate
      ? new Date(user.membershipStartDate).getDate()
      : new Date().getDate();

    // Determine the starting point for period calculation:
    //   - If expirationDate exists and is in the future → extend from there
    //   - Otherwise (expired or never paid) → start from today
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let periodStart: Date;

    if (user.membershipExpirationDate) {
      const expDate = new Date(user.membershipExpirationDate);
      expDate.setHours(0, 0, 0, 0);
      periodStart = expDate > today ? expDate : today;
    } else {
      periodStart = today;
    }

    // Helper: advance a date by N months, clamping the day to the anchor
    const advanceMonth = (from: Date, months: number): Date => {
      const result = new Date(from);
      result.setMonth(result.getMonth() + months);
      // Clamp day to anchor (handles month-end overflow: e.g. Jan 31 + 1 month → Feb 28)
      const lastDayOfMonth = new Date(
        result.getFullYear(),
        result.getMonth() + 1,
        0,
      ).getDate();
      result.setDate(Math.min(anchorDay, lastDayOfMonth));
      return result;
    };

    // Helper: format Date to 'YYYY-MM-DD'
    const toDateString = (d: Date): string => d.toISOString().split('T')[0];

    // Build N records
    const records: PaymentRecord[] = [];
    let currentFrom = periodStart;

    for (let i = 1; i <= periodMonths; i++) {
      const periodTo = advanceMonth(periodStart, i);
      periodTo.setHours(0, 0, 0, 0);

      const record = this.paymentRecordRepository.create({
        user,
        amount: dto.amount ?? null,
        method: dto.method ?? null,
        notes: dto.notes ?? null,
        periodFrom: toDateString(currentFrom),
        periodTo: toDateString(periodTo),
        registeredBy: adminUser,
      });

      records.push(record);
      currentFrom = periodTo;
    }

    await this.paymentRecordRepository.save(records);

    // Update the user's expirationDate and lastPaymentDate
    const lastPeriodTo = records[records.length - 1].periodTo;
    user.membershipExpirationDate = new Date(lastPeriodTo) as any;
    user.lastPaymentDate = toDateString(today);
    await this.usersRepository.save(user);

    // Return records with registeredBy populated (for the response)
    return this.paymentRecordRepository.find({
      where: { user: { id: userId } },
      relations: ['registeredBy'],
      order: { paidAt: 'DESC' },
      take: periodMonths,
    });
  }

  /**
   * Returns all payment records for a user, newest first.
   */
  async getPaymentHistory(userId: string): Promise<PaymentRecord[]> {
    const user = await this.usersRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException(`User ${userId} not found`);
    }

    return this.paymentRecordRepository.find({
      where: { user: { id: userId } },
      relations: ['registeredBy'],
      order: { paidAt: 'DESC' },
    });
  }
}
