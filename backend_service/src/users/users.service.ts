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

    // Auto-assign membershipStartDate for Students if left null
    if (
      user.role === UserRole.ALUMNO &&
      user.paysMembership !== false &&
      !user.membershipStartDate
    ) {
      // Use the actual creation date as the billing anchor (not the 1st of the month)
      const now = new Date();
      now.setHours(0, 0, 0, 0);
      user.membershipStartDate = now;
    }

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
    return this.usersRepository.findOne({
      where: { providerUserId },
      relations: ['gym'],
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
    // 1. Exempt users always show as paid
    if (user.paysMembership === false) {
      return 'paid';
    }

    // 2. If there is a valid future expiration date → paid
    if (user.membershipExpirationDate) {
      const now = new Date();
      const exp = new Date(user.membershipExpirationDate);
      now.setHours(0, 0, 0, 0);
      exp.setHours(0, 0, 0, 0);

      if (exp >= now) {
        return 'paid';
      }
      // Expiration date exists but is in the past → fall through to anchor check
    }

    // 3. Fallback: no expirationDate (user never paid) or expiration is past.
    //    Determine status using real elapsed days from the last theoretical anchor.
    if (!user.membershipStartDate) {
      return 'pending'; // No anchor data at all → show as pending (new user)
    }

    const now = new Date();
    now.setHours(0, 0, 0, 0);

    const startDate = new Date(user.membershipStartDate);
    startDate.setHours(0, 0, 0, 0);

    const anchorDay = startDate.getDate();

    // Build the last theoretical anchor date:
    //   - Try the anchor day in the CURRENT calendar month
    //   - If that date is in the future (anchor hasn't arrived yet this month),
    //     use the anchor day in the PREVIOUS calendar month instead.
    const year = now.getFullYear();
    const month = now.getMonth(); // 0-indexed

    // Clamp anchorDay to the last day of the target month (e.g. anchor=31 in Feb → 28/29)
    const clampToMonth = (y: number, m: number, d: number): Date => {
      const lastDay = new Date(y, m + 1, 0).getDate();
      return new Date(y, m, Math.min(d, lastDay));
    };

    let lastAnchor = clampToMonth(year, month, anchorDay);

    if (lastAnchor > now) {
      // Anchor day of this month is still in the future → last anchor was previous month
      const prevMonth = month === 0 ? 11 : month - 1;
      const prevYear = month === 0 ? year - 1 : year;
      lastAnchor = clampToMonth(prevYear, prevMonth, anchorDay);
    }

    // Also ensure lastAnchor is not before membershipStartDate
    // (edge case: user was created after the anchor day of the current month)
    if (lastAnchor < startDate) {
      lastAnchor = startDate;
    }

    // Days elapsed since the last anchor
    const msPerDay = 1000 * 60 * 60 * 24;
    const daysElapsed = Math.floor((now.getTime() - lastAnchor.getTime()) / msPerDay);

    if (daysElapsed <= 10) {
      return 'pending'; // Within grace period
    }

    return 'overdue'; // Grace period exhausted
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
