import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserRole } from './entities/user.entity';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import * as bcrypt from 'bcrypt';


import { GymsService } from '../gyms/gyms.service';

@Injectable()
export class UsersService {
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

        return this.usersRepository.find({
            where,
            relations: ['studentPlans', 'professor'],
        });
    }


    async findOneByEmail(email: string): Promise<User | null> {
        return this.usersRepository.findOne({ where: { email } });
    }

    async findOne(id: string): Promise<User | null> {
        return this.usersRepository.findOne({
            where: { id },
            relations: ['gym', 'professor'], // Load helpful relations
        });
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
}

