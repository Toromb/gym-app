import {
  Injectable,
  NotFoundException,
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
   * Registra N meses de pago para un usuario.
   *
   * Reglas de negocio:
   * - Los períodos siempre van del 1ro al 1ro del siguiente mes.
   * - Si el alumno tiene expiración futura → el nuevo período arranca desde ese 1ro.
   * - Si está vencido o nunca pagó → arranca desde el 1ro del mes actual.
   * - Se crean N PaymentRecord encadenados (periodTo[i] = periodFrom[i+1]).
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

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let periodStart: Date;

    if (user.membershipExpirationDate) {
      const expDate = new Date(user.membershipExpirationDate);
      expDate.setHours(0, 0, 0, 0);
      // Si la expiración es futura, extendemos desde ese 1ro de mes.
      // Si está vencida, arrancamos desde el 1ro del mes actual.
      periodStart = expDate > today
        ? expDate
        : new Date(today.getFullYear(), today.getMonth(), 1);
    } else {
      // Primera vez que paga: el período arranca el 1ro del mes actual
      periodStart = new Date(today.getFullYear(), today.getMonth(), 1);
    }

    // Cada período va del 1ro al 1ro del mes siguiente (siempre día 1)
    const advanceMonth = (from: Date, months: number): Date =>
      new Date(from.getFullYear(), from.getMonth() + months, 1);

    const toDateString = (d: Date): string => d.toISOString().split('T')[0];

    // Construye N registros encadenados
    const records: PaymentRecord[] = [];
    let currentFrom = periodStart;

    for (let i = 1; i <= periodMonths; i++) {
      const periodTo = advanceMonth(periodStart, i);

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

    // Actualiza la fecha de expiración y el último pago del usuario
    const lastPeriodTo = records[records.length - 1].periodTo;
    user.membershipExpirationDate = new Date(lastPeriodTo) as any;
    user.lastPaymentDate = toDateString(today);
    await this.usersRepository.save(user);

    return this.paymentRecordRepository.find({
      where: { user: { id: userId } },
      relations: ['registeredBy'],
      order: { paidAt: 'DESC' },
      take: periodMonths,
    });
  }

  /**
   * Retorna el historial de pagos de un usuario, del más reciente al más antiguo.
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
