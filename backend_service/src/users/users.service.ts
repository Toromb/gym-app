import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserRole } from './entities/user.entity';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import * as bcrypt from 'bcrypt';

import { GymsService } from '../gyms/gyms.service';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    private gymsService: GymsService,
  ) { }

  async create(createUserDto: CreateUserDto, creator?: User): Promise<User> {
    const { password, gymId, professorId, ...rest } = createUserDto;
    const passwordToHash = password || '123456'; // Default password
    const passwordHash = await bcrypt.hash(passwordToHash, 10);

    let gym = null;
    if (gymId) {
      gym = await this.gymsService.findOne(gymId);
    } else if (creator && creator.gym) {
      gym = creator.gym;
    }

    let professor: User | null | undefined =
      creator && creator.role === UserRole.PROFE ? creator : undefined;
    if (professorId) {
      professor = await this.usersRepository.findOne({
        where: { id: professorId },
      });
    }

    const user = this.usersRepository.create({
      ...rest,
      passwordHash,
      professor: professor || undefined, // TypeORM create usually prefers undefined over null for "not set", but allows null for "empty relation"
      gym: gym || undefined,
    });
    return this.usersRepository.save(user);
  }

  async findAllStudents(
    professorId?: string,
    roleFilter?: string,
    gymId?: string,
  ): Promise<User[]> {
    const where: any = {};

    if (roleFilter) {
      where.role = roleFilter;
    } else if (professorId) {
      where.role = UserRole.ALUMNO;
    }

    if (professorId) {
      where.professor = { id: professorId };
    }

    if (gymId) {
      where.gym = { id: gymId };
    }

    const users = await this.usersRepository.find({
      where,
      relations: ['studentPlans', 'professor', 'gym'],
    });

    // Inject computed status
    return users.map((u) => {
      // TS ignore or DTO usage would be cleaner, but modifying entity is fine for JSON serialization if @AfterLoad not used
      // Actually, typeorm entities are objects.
      if (u.membershipExpirationDate) {
        const status = this.calculatePaymentStatus(u.membershipExpirationDate);
        u.paymentStatus = status as any;
      }
      return u;
    });
  }

  async findOneByEmail(email: string): Promise<User | null> {
    const user = await this.usersRepository
      .createQueryBuilder('user')
      .addSelect('user.passwordHash') // Explicitly select hidden column
      .leftJoinAndSelect('user.gym', 'gym') // load relation
      .where('user.email = :email', { email })
      .getOne();

    if (user && user.membershipExpirationDate) {
      const status = this.calculatePaymentStatus(user.membershipExpirationDate);
      user.paymentStatus = status as any;
    }

    return user;
  }

  async findOne(id: string): Promise<User | null> {
    const user = await this.usersRepository.findOne({
      where: { id },
      relations: ['gym', 'professor'], // Load helpful relations
    });

    if (user && user.membershipExpirationDate) {
      const status = this.calculatePaymentStatus(user.membershipExpirationDate);
      user.paymentStatus = status as any;
    }

    return user;
  }

  async update(id: string, updateUserDto: UpdateUserDto): Promise<User> {
    const user = await this.findOne(id);
    if (!user) {
      throw new Error('User not found');
    }

    const { password, professorId, ...rest } = updateUserDto;
    if (password) {
      user.passwordHash = await bcrypt.hash(password, 10);
    }

    if (professorId !== undefined) {
      if (professorId === null) {
        user.professor = null;
      } else {
        user.professor = await this.usersRepository.findOne({
          where: { id: professorId },
        });
      }
    }

    Object.assign(user, rest);

    const saved = await this.usersRepository.save(user);

    return this.findOne(id) as Promise<User>;
  }

  async remove(id: string): Promise<void> {
    try {
      await this.usersRepository.delete(id);
    } catch (error) {
      this.logger.error(`Failed to delete User ${id}`, error.stack);
      if (error.code === '23503') { // ForeignKeyViolation
        this.logger.error(`Foreign Key Violation details: ${error.detail}`);
        const { ConflictException } = require('@nestjs/common');
        throw new ConflictException(`No se puede eliminar el usuario porque tiene registros relacionados (Planes, Ejercicios, etc). Detalle: ${error.detail}`);
      }
      throw error;
    }
  }

  async countAll(): Promise<number> {
    return this.usersRepository.count();
  }

  async markAsPaid(id: string): Promise<User> {
    const user = await this.findOne(id);
    if (!user) throw new Error('User not found');

    // Anchor Date: The day of the month the membership started.
    // If not set, use today as the start date anchor.
    const anchorDate = user.membershipStartDate
      ? new Date(user.membershipStartDate)
      : new Date();
    // If user had no start date, save this anchor
    if (!user.membershipStartDate) {
      user.membershipStartDate = anchorDate;
    }

    const anchorDay = anchorDate.getDate(); // e.g. 5
    const now = new Date();
    let targetMonth: Date;

    // Determine the target month for the new expiration.
    // Rule:
    // 1. If currently expired (or null expiration), the new expiration should be NEXT month from TODAY (but respecting anchor day).
    //    Actually, more fair:
    //    - If expired Long ago: Restart cycle from Today? --> User said "The date is determined by start date".
    //    - Strict interpretation: If I started on Jan 5th, I always pay for "5th to 5th".
    //      If I pay on March 10th (late), I am arguably paying for "March 5th - April 5th" (retroactive) OR "April 5th - May 5th"?
    //      Most gyms do: "You pay for the upcoming month".
    //      If I am expired, and I pay today (March 10), and my anchor is 5.
    //      Should it expire April 5 (less than a month)? Or May 5?
    //      Let's assume "Next occurence of Anchor Day that is at least ~28 days away?"
    //      OR simpler: "One month from the *Current Expiration Date* if it's in the future".
    //      "One month from *Today* aligned to Anchor" if it's in the past.

    // Plan:
    // A. If user has active expiration in future -> Add 1 month to THAT date.
    // B. If user is expired -> Calculate next occurrence of Anchor Day that is at least 1 month from Last Valid Period?
    //    Or simply: New Expiration = (Today + 1 Month) aligned to Anchor Day.

    // Let's go with a robust approach for "Cycle Maintenance":

    const validExpiration = user.membershipExpirationDate
      ? new Date(user.membershipExpirationDate)
      : null;

    if (validExpiration && validExpiration > now) {
      // Case A: Not expired yet. Extend from current expiration.
      // e.g. Expires April 5. Paid today (March 20). New Exp: May 5.
      targetMonth = new Date(validExpiration);
      targetMonth.setMonth(targetMonth.getMonth() + 1);
    } else {
      // Case B: Expired or First Time.
      // We want the new expiration to be in the future, respecting the anchor day.
      // Start from Today. Move to next month. Set Day.
      targetMonth = new Date(now);
      targetMonth.setMonth(targetMonth.getMonth() + 1);

      // Adjust day
      // If resulting month has fewer days than anchorDay (e.g. Feb 28 vs 30), JS auto-adjusts to Mar 2.
      // We usually want to stick to the month.
      // setDate handles overflow, but let's try to set strictly.
      targetMonth.setDate(anchorDay);

      // If the adjustment pushed us deeper (e.g. Feb 30 -> Mar 2), and we wanted Feb end...
      // Complexity: standardized 30 days or calendar strict?
      // Simple JS setDate is usually accepted behavior for simple apps.
      // BUT, if Today is Jan 30, Anchor is 5.
      // targetMonth (Feb 30) -> March 2. Set Day 5 -> March 5.
      // Result: Paid Jan 30, Expire March 5. (> 1 month). Correct.

      // What if Today is Jan 20. Anchor is 25.
      // targetMonth (Feb 20). Set Day 25. -> Feb 25.
      // Result: Paid Jan 20. Expire Feb 25. (1 month + 5 days). OK.
    }

    // Final Safeguard: Ensure day matches Anchor (unless month doesn't have it)
    // We trust JS setMonth/setDate logic to be "good enough" for MVP.
    // Just ensuring we use the Anchor Day is the key requirement.

    // Refined Logic for "Start Date Determines Date":
    // We strictly take the Year/Month we calculated, and FORCE the day to be AnchorDay.
    // (Handling the Feb 28 issue: if Anchor is 31, and we are in Feb, expires Feb 28/29).

    const year = targetMonth.getFullYear();
    const month = targetMonth.getMonth();
    // Get last day of that month
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const finalDay = Math.min(anchorDay, daysInMonth);

    targetMonth.setDate(finalDay); // Set strict day

    user.membershipExpirationDate = targetMonth;
    user.lastPaymentDate = new Date().toISOString().split('T')[0];

    await this.usersRepository.save(user);
    return this.findOne(id) as Promise<User>;
  }

  // Helper to compute status on the fly
  // Note: This logic could be used to populate a virtual field or DTO
  calculatePaymentStatus(
    expirationDate: Date | string,
  ): 'paid' | 'overdue' | 'pending' {
    if (!expirationDate) return 'pending'; // Or handle as they wish

    const now = new Date();
    const exp = new Date(expirationDate);

    // Normalize to YYYY-MM-DD to avoid time issues
    now.setHours(0, 0, 0, 0);
    exp.setHours(0, 0, 0, 0);

    const diffTime = now.getTime() - exp.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays <= 0) return 'paid'; // Green
    if (diffDays <= 10) return 'pending'; // Yellow (reusing pending as "Por vencer" maps to 'Yellow') -> Wait, user said Yellow is Por Vencer. Pending usually means unpaid initially.
    // Let's map to existing Enum?
    // PaymentStatus: PENDING, PAID, OVERDUE.
    // Green -> PAID
    // Yellow -> PENDING (Por vencer/Grace Period)
    // Red -> OVERDUE

    return 'overdue';
  }
}
