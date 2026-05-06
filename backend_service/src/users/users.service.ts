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

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Si la expiración actual es futura, extender desde ese 1ro de mes
    // Si está vencida o sin pagar, usar el 1ro del mes actual
    const validExpiration = user.membershipExpirationDate
      ? new Date(user.membershipExpirationDate)
      : null;

    let targetMonth: Date;

    if (validExpiration && validExpiration > today) {
      // Extender: el próximo 1ro desde la expiración futura
      targetMonth = new Date(
        validExpiration.getFullYear(),
        validExpiration.getMonth() + 1,
        1,
      );
    } else {
      // Vencida o sin pagar: 1ro del mes siguiente al actual
      targetMonth = new Date(today.getFullYear(), today.getMonth() + 1, 1);
    }

    user.membershipExpirationDate = targetMonth;
    user.lastPaymentDate = today.toISOString().split('T')[0];

    await this.usersRepository.save(user);
    return this.findOne(id) as Promise<User>;
  }

  // Helper: calcula el estado de pago del alumno en tiempo real.
  //
  // Regla de negocio:
  //   - Los períodos de membresía van siempre del 1ro al 1ro del siguiente mes.
  //   - Hay 10 días de gracia: del 1 al 10 de cada mes el estado es "pending"
  //     (el alumno aún puede pagar sin consecuencias).
  //   - Después del día 10 sin pagar → "overdue".
  calculatePaymentStatus(user: User): 'paid' | 'overdue' | 'pending' {
    // 1. Usuarios exentos (paysMembership = false) siempre muestran "paid"
    if (user.paysMembership === false) {
      return 'paid';
    }

    const now = new Date();
    now.setHours(0, 0, 0, 0);

    // 2. Si tiene una fecha de expiración válida en el futuro → "paid"
    if (user.membershipExpirationDate) {
      const exp = new Date(user.membershipExpirationDate);
      exp.setHours(0, 0, 0, 0);
      if (exp >= now) {
        return 'paid';
      }
    }

    // 3. Membresía vencida o nunca pagada.
    //    Aplicar la regla de los 10 días de gracia del 1 al 10 de cada mes.
    //    Si hoy es día 1..10 → "pending" (en período de gracia).
    //    Si hoy es día 11 en adelante → "overdue".
    const dayOfMonth = now.getDate();

    if (dayOfMonth <= 10) {
      return 'pending'; // Dentro del período de gracia
    }

    return 'overdue'; // Vencido y sin pagar tras el día 10
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
