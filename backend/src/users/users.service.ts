import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserRole } from './entities/user.entity';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import * as bcrypt from 'bcrypt';


@Injectable()
export class UsersService {
    constructor(
        @InjectRepository(User)
        private usersRepository: Repository<User>,
    ) { }

    async create(createUserDto: CreateUserDto, professor?: User): Promise<User> {
        const { password, ...rest } = createUserDto;
        const passwordToHash = password || '123456'; // Default password
        const passwordHash = await bcrypt.hash(passwordToHash, 10);
        const user = this.usersRepository.create({
            ...rest,
            passwordHash,
            professor: professor, // Assign professor if provided
        });
        return this.usersRepository.save(user);
    }

    async findAllStudents(professorId?: string, roleFilter?: string): Promise<User[]> {
        const where: any = {};

        // If a specific role is requested, filter by it. Cannot filter if restricting to students of a professor (unless logic demands).
        // Actually, if professorId is present, they ARE students (role=ALUMNO). 
        // But for Admin, they might want to filter 'profe', 'admin', 'alumno'.

        if (roleFilter) {
            where.role = roleFilter;
        } else if (professorId) {
            // If professor is asking, and didn't specify, default to only showing ALUMNO? 
            // Or maybe they can see other things? 
            // Requirement: "Profe: solo ve sus alumnos".
            where.role = UserRole.ALUMNO;
        }

        if (professorId) {
            where.professor = { id: professorId };
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
        return this.usersRepository.findOne({ where: { id } });
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

