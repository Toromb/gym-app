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
        const { password, gymId, ...rest } = createUserDto;
        const passwordToHash = password || '123456'; // Default password
        const passwordHash = await bcrypt.hash(passwordToHash, 10);

        let gym = null;
        if (gymId) {
            gym = await this.gymsService.findOne(gymId);
        } else if (creator && creator.gym) {
            gym = creator.gym;
        }

        const user = this.usersRepository.create({
            ...rest,
            passwordHash,
            professor: (creator && creator.role === UserRole.PROFE) ? creator : undefined,
            gym: gym || undefined,
        });
        return this.usersRepository.save(user);
    }

    async findAllStudents(professorId?: string, roleFilter?: string, gymId?: string): Promise<User[]> {
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
        return users.map(u => {
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
        const user = await this.usersRepository.findOne({ where: { email } });

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

        const { password, ...rest } = updateUserDto;
        if (password) {
            user.passwordHash = await bcrypt.hash(password, 10);
        }

        Object.assign(user, rest);
        return this.usersRepository.save(user);
    }

    async remove(id: string): Promise<void> {
        await this.usersRepository.delete(id);
    }

    async countAll(): Promise<number> {
        return this.usersRepository.count();
    }

    async markAsPaid(id: string): Promise<User> {
        const user = await this.findOne(id);
        if (!user) throw new Error('User not found');

        const referenceDate = user.membershipExpirationDate ? new Date(user.membershipExpirationDate) : new Date(user.membershipStartDate);

        // Increment by 1 month
        referenceDate.setMonth(referenceDate.getMonth() + 1);

        user.membershipExpirationDate = referenceDate;
        // Also update LastPaymentDate for record keeping
        user.lastPaymentDate = new Date().toISOString().split('T')[0];

        return this.usersRepository.save(user);
    }

    // Helper to compute status on the fly
    // Note: This logic could be used to populate a virtual field or DTO
    calculatePaymentStatus(expirationDate: Date | string): 'paid' | 'overdue' | 'pending' {
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

