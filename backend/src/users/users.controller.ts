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

        // Professor can only update their students
        if (requestor.role === UserRole.PROFE) {
            const userToUpdate = await this.usersService.findOne(id);
            if (!userToUpdate) throw new NotFoundException('User not found');

            if (userToUpdate.professor?.id !== requestor.id) {
                throw new ForbiddenException('You can only edit your own students');
            }
            return this.usersService.update(id, updateUserDto);
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
