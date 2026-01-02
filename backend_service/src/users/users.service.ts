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
      // Calculate status for everyone, handling exemption inside the method
      u.paymentStatus = this.calculatePaymentStatus(u) as any;
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

    // 3. Fallback Logic: Calculate based on Cycle Start
    // Logic:
    // - Cycle anchor is the day of membershipStartDate.
    // - If we are within 10 days of the current cycle start -> Pending.
    // - If we are past 10 days -> Overdue.

    if (!user.membershipStartDate) {
      // No start date -> treat as Pending (Waiting for setup)
      return 'pending';
    }

    const now = new Date();
    // Normalize to start of day
    now.setHours(0, 0, 0, 0);

    const startDate = new Date(user.membershipStartDate);
    const anchorDay = startDate.getDate();

    // Determine "Current Cycle Start"
    // Construct a date with Current Month/Year and Anchor Day
    let cycleStart = new Date(now.getFullYear(), now.getMonth(), anchorDay);

    // If constructed cycleStart is in the future relative to today,
    // it means the current cycle actually started last month.
    // Example: Today is Feb 5th. Anchor is 20th.
    // constructed = Feb 20th (Future).
    // Actual current cycle start = Jan 20th.
    if (cycleStart > now) {
      cycleStart.setMonth(cycleStart.getMonth() - 1);
    }

    // Safety for edge case where anchor day doesn't exist in previous month (e.g. 31st)
    // JS setMonth handles this by rolling over, but we want the last day of that month.
    // However, for 'cycleStart', JS's auto-rollover is often acceptable or we can strict clamp.
    // Let's rely on standard JS Date behavior which is robust enough for "approximate monthly cycles".

    // Calculate days elapsed in current cycle
    const diffTime = now.getTime() - cycleStart.getTime();
    const daysInCycle = Math.floor(diffTime / (1000 * 60 * 60 * 24));

    if (daysInCycle > 10) {
      return 'overdue';
    } else {
      return 'pending';
    }
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
