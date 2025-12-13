import { Controller, Get, Post, Body, Patch, Param, UseGuards, Request, ForbiddenException, Delete, Query, NotFoundException } from '@nestjs/common';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { AuthGuard } from '@nestjs/passport';
import { UserRole } from './entities/user.entity';

@Controller('users')
@UseGuards(AuthGuard('jwt'))
export class UsersController {
    constructor(private readonly usersService: UsersService) { }

    @Post()
    create(@Body() createUserDto: CreateUserDto, @Request() req: any) {
        const creator = req.user;

        // Admin can create any role
        if (creator.role === UserRole.ADMIN) {
            // Allow setting role from DTO, default to ALUMNO if not set
            if (!createUserDto.role) {
                createUserDto.role = UserRole.ALUMNO;
            }
            return this.usersService.create(createUserDto);
        }

        // Professor can only create Alumno
        if (creator.role === UserRole.PROFE) {
            createUserDto.role = UserRole.ALUMNO; // Force role
            return this.usersService.create(createUserDto, creator); // Assign professor
        }

        // Alumno cannot create users (should be handled by Guard, but safety check)
        throw new ForbiddenException('You do not have permission to create users');
    }

    @Get()
    findAll(@Request() req: any, @Query('role') role?: string) {
        const user = req.user;
        if (user.role === UserRole.ADMIN) {
            return this.usersService.findAllStudents(undefined, role); // Admin sees all, optional role filter
        }
        if (user.role === UserRole.PROFE) {
            // Professor sees only their students. 
            // If they ask for 'admin' or 'profe', they get nothing or error. 
            // For now, let's just ignore the role param or enforce it must be 'student' effectively.
            return this.usersService.findAllStudents(user.id, role);
        }
        throw new ForbiddenException('You do not have permission to view users');
    }

    @Get('profile')
    async getProfile(@Request() req: any) {
        const userId = req.user.id;
        const user = await this.usersService.findOne(userId);
        if (!user) throw new NotFoundException('User not found');
        return user;
    }

    @Patch('profile')
    async updateProfile(@Body() updateUserDto: UpdateUserDto, @Request() req: any) {
        const userId = req.user.id;
        const userRole = req.user.role;
        const user = await this.usersService.findOne(userId);

        if (!user) throw new NotFoundException('User not found');

        // Define allowed fields per role
        const allowedFields: string[] = ['phone', 'age', 'gender', 'height'];

        if (userRole === UserRole.ALUMNO) {
            allowedFields.push('currentWeight', 'personalComment');
            // If currentWeight is updated, update the date
            if (updateUserDto.currentWeight) {
                updateUserDto.weightUpdateDate = new Date();
            }
        } else if (userRole === UserRole.PROFE) {
            allowedFields.push('specialty', 'internalNotes');
        } else if (userRole === UserRole.ADMIN) {
            // Admin can edit everything in their own profile?
            // "Acceso total al sistema" usually implies they can edit their profile freely.
            // But let's stick to the common editable ones + admin notes?
            // "Notas administrativas (opcional)"
            allowedFields.push('adminNotes');
        }

        // Filter the DTO
        const filteredDto: UpdateUserDto = {};
        for (const key of Object.keys(updateUserDto)) {
            if (allowedFields.includes(key)) {
                (filteredDto as any)[key] = (updateUserDto as any)[key];
            }
        }

        if (Object.keys(filteredDto).length === 0) {
            return user; // Nothing to update
        }

        return this.usersService.update(userId, filteredDto);
    }

    @Get(':id')
    async findOne(@Param('id') id: string, @Request() req: any) {
        const user = await this.usersService.findOne(id);
        const requestor = req.user;

        if (!user) throw new NotFoundException('User not found');

        if (requestor.role === UserRole.ADMIN) return user;
        if (requestor.role === UserRole.PROFE) {
            // Check if student belongs to professor
            if (user.professor?.id === requestor.id || user.id === requestor.id) {
                return user;
            }
            throw new ForbiddenException('You can only view your own students');
        }
        if (requestor.id === user.id) return user; // Users can view themselves

        throw new ForbiddenException('Access denied');
    }

    @Patch(':id')
    async update(@Param('id') id: string, @Body() updateUserDto: UpdateUserDto, @Request() req: any) {
        const requestor = req.user;

        // Admin can update anyone
        if (requestor.role === UserRole.ADMIN) {
            return this.usersService.update(id, updateUserDto);
        }

        // Professor can update specific fields of their students
        if (requestor.role === UserRole.PROFE) {
            const userToUpdate = await this.usersService.findOne(id);
            if (!userToUpdate) throw new NotFoundException('User not found');

            if (userToUpdate.professor?.id !== requestor.id) {
                throw new ForbiddenException('You can only edit your own students');
            }

            // Professors can likely edit typical student management fields
            // "Objetivo general", "Observaciones del profesor"
            const allowedStudentFields = ['trainingGoal', 'professorObservations', 'notes'];
            const filteredDto: UpdateUserDto = {};
            for (const key of Object.keys(updateUserDto)) {
                if (allowedStudentFields.includes(key)) {
                    (filteredDto as any)[key] = (updateUserDto as any)[key];
                }
            }
            if (Object.keys(filteredDto).length === 0) {
                return userToUpdate;
            }

            return this.usersService.update(id, filteredDto);
        }

        throw new ForbiddenException('Permission denied');
    }

    @Delete(':id')
    async remove(@Param('id') id: string, @Request() req: any) {
        const requestor = req.user;

        // Admin can delete anyone
        if (requestor.role === UserRole.ADMIN) {
            return this.usersService.remove(id);
        }

        // Professor can only delete their students
        if (requestor.role === UserRole.PROFE) {
            const userToDelete = await this.usersService.findOne(id);
            if (!userToDelete) throw new NotFoundException('User not found');

            if (userToDelete.professor?.id !== requestor.id) {
                throw new ForbiddenException('You can only delete your own students');
            }
            return this.usersService.remove(id);
        }

        throw new ForbiddenException('Permission denied');
    }
}
