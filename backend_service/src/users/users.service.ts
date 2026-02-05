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

    let passwordHash = null;
    let isActive = false;

    if (password) {
      passwordHash = await bcrypt.hash(password, 10);
      isActive = true;
    }

    // Respect DTO isActive if provided, otherwise default to logic above
    if (createUserDto.isActive !== undefined) {
      isActive = createUserDto.isActive;
    }

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
      passwordHash: passwordHash as any,
      isActive,
      professor: professor || undefined,
      gym: gym || undefined,
    });
    const savedUser = await this.usersRepository.save(user);
    const status = this.calculatePaymentStatus(savedUser);
    savedUser.paymentStatus = status as any;
    return savedUser;
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
      // Calculate status for everyone, handling exemption inside the method
      u.paymentStatus = this.calculatePaymentStatus(u) as any;
      return u;
    });
  }

  async findOneByProviderUserId(providerUserId: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { providerUserId } });
  }

  async findOneByEmail(email: string): Promise<User | null> {
    const user = await this.usersRepository
      .createQueryBuilder('user')
      .addSelect('user.passwordHash') // Explicitly select hidden column
      .leftJoinAndSelect('user.gym', 'gym') // load relation
      .where('user.email = :email', { email })
      .getOne();

    if (user) {
      const status = this.calculatePaymentStatus(user);
      user.paymentStatus = status as any;
    }

    return user;
  }

  async findOne(id: string): Promise<User | null> {
    const user = await this.usersRepository.findOne({
      where: { id },
      relations: ['gym', 'professor'], // Load helpful relations
    });

    if (user) {
      const status = this.calculatePaymentStatus(user);
      user.paymentStatus = status as any;
    }

    if (user) {
      console.log(`[UsersService] findOne(${id}) found user with Gym:`, user.gym?.id);
    } else {
      console.log(`[UsersService] findOne(${id}) - User NOT FOUND`);
    }
    return user;
  }

  async findOneWithSecrets(id: string): Promise<User | null> {
    const user = await this.usersRepository.createQueryBuilder('user')
      .addSelect('user.passwordHash')
      .where('user.id = :id', { id })
      .getOne();

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

    const validExpiration = user.membershipExpirationDate
      ? new Date(user.membershipExpirationDate)
      : null;

    if (validExpiration && validExpiration > now) {
      // Case A: Not expired yet. Extend from current expiration.
      targetMonth = new Date(validExpiration);
      targetMonth.setMonth(targetMonth.getMonth() + 1);
    } else {
      // Case B: Expired or First Time.
      targetMonth = new Date(now);
      targetMonth.setMonth(targetMonth.getMonth() + 1);
      targetMonth.setDate(anchorDay);
    }

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
  calculatePaymentStatus(user: User): 'paid' | 'overdue' | 'pending' {
    // 1. Check if user is exempt
    if (user.paysMembership === false) {
      return 'paid';
    }

    // 2. Check if membership is explicitly valid (Expiration Date in the future)
    if (user.membershipExpirationDate) {
      const now = new Date();
      const exp = new Date(user.membershipExpirationDate);
      now.setHours(0, 0, 0, 0);
      exp.setHours(0, 0, 0, 0);

      if (exp >= now) {
        return 'paid';
      }
    }

    // 3. Fallback Logic: Strict Day-of-Month check (Per User Request)
    // Status depends ONLY on the current day relative to the anchor day in the CURRENT month.
    // History does not matter. Use reset every month.

    if (!user.membershipStartDate) {
      return 'pending';
    }

    const now = new Date();
    const startDate = new Date(user.membershipStartDate);

    // We only care about the DAY component.
    const currentDay = now.getDate();
    const anchorDay = startDate.getDate();

    // "La cuota solo debe figurar como VENCIDA cuando, en el ciclo actual, 
    // hayan pasado más de 10 días desde el día de membresía."
    // Example: Start=25. Current=20.
    // Limit = 25 + 10 = 35. 
    // 20 > 35? False. -> Pending.

    // Logic for month wrap-around (e.g. Start=25, Current=5 of next month)
    // If currentDay (5) < anchorDay (25), we are physically in the 'next' month relative to anchor.
    // Theoretically limit is 25+10 = 35 (of prev month) aka 5th of current month.
    // Let's stick to the SIMPLEST interpretation requested:
    // "Comparison by real days elapsed... wait, user changed mind to: cycle control."

    // User SAID: "La cuota solo debe figurar como VENCIDA cuando, en el ciclo actual (enero), aún no se llegó al día 25 ni se superaron los 10 días de gracia."

    // Let's implement logic:
    // Calculate "Last theoretical start date"
    // If today is 20th Jan, and anchor is 25th. Last start was 25th Dec.
    // Days elapsed since 25th Dec = 26 days. -> Vencido?

    // User SAID: "Ejemplo: Fecha membresía: 25/08/2025. Hoy: 20/01/2026. Resultado esperado: CUOTA POR VENCER. Porque en el ciclo actual (enero), aún no se llegó al día 25"

    // This implies: Cycle runs from 25th to 24th.
    // If today (20) < Anchor (25) -> We are in the "tail" of the previous month's cycle?
    // Or does the cycle START on the 25th?
    // If cycle starts on 25th Jan, and current date is 20th Jan.
    // Then we are in the cycle that started 25th Dec.
    // Dec 25th + 10 days = Jan 4th.
    // So on Jan 20th, we are WAY past the grace period of the Dec cycle.

    // BUT User says: "Aún no se llegó al día 25... Estado: CUOTA POR VENCER".
    // This implies that BEFORE the anchor day in the current month, IT IS NOT VENCIDO.
    // It basically resets to "Pending" as soon as the month flips? Or strictly assumes "If we haven't reached the cutoff day yet".

    // Let's interpret strictly:
    // "La cuota solo debe figurar como VENCIDA cuando, en el ciclo actual, hayan pasado más de 10 días desde el día de membresía."

    // If today is 20. Anchor is 25.
    // Cycle determines: "This month's payment".
    // Deadline for "This Month" is 25th + 10 = 35th? Or next month 5th?

    // If user says "25/08... Hoy 20/01... POR VENCER", it means:
    // "I haven't reached my billing date (25th) for January yet, so I'm fine."
    // (Implies current status is valid until 25th).

    // What about the PREVIOUS bill (Dec 25th)?? The user seems to imply historical debt doesn't show 'Overdue'.
    // Or maybe they assume they Paid Dec?

    // Let's implement the specific requested check:
    // "Vencida ONLY IF days_since_anchor_THIS_month > 10"

    // Case 1: Today=20. Anchor=25.
    // Check: Is (Today - Anchor) > 10?  (20 - 25 = -5). No. -> Pending.

    // Case 2: Today=5. Anchor=25.
    // Check: (5 - 25 = -20). No. -> Pending.

    // Case 3: Today=28. Anchor=25.
    // Check: (28 - 25 = 3). 3 > 10? No. -> Pending.

    // Case 4: Today=15. Anchor=1.
    // Check: (15 - 1 = 14). 14 > 10? YES. -> OVERDUE.

    // This seems to be the logic requested. "Has the grace period passed for THIS CALENDAR MONTH'S anchor day?"

    let daysDiff = currentDay - anchorDay;

    // If daysDiff is negative (e.g. today 20, anchor 25), it means we are BEFORE the date.
    if (daysDiff > 10) {
      return 'overdue';
    }

    return 'pending';
  }

  async findOneByActivationTokenHash(hash: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { activationTokenHash: hash },
    });
  }

  async findOneByResetTokenHash(hash: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { resetTokenHash: hash },
    });
  }

  async updateTokens(id: string, updates: Partial<User>): Promise<void> {
    await this.usersRepository.update(id, updates);
  }
}
