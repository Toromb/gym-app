import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  UseGuards,
  Request,
  ForbiddenException,
  Delete,
  Query,
  NotFoundException,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { RequestWithUser } from '../auth/interfaces/request-with-user.interface';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { AuthGuard } from '@nestjs/passport';
import { UserRole } from './entities/user.entity';

@Controller('users')
@UseGuards(AuthGuard('jwt'))
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  create(@Body() createUserDto: CreateUserDto, @Request() req: any) {
    const creator = req.user;

    // Super Admin can create any role
    if (creator.role === UserRole.SUPER_ADMIN) {
      // If creating Admin or other roles, gymId must be handled by Service (from DTO)
      // SA can basically do anything.
      return this.usersService.create(createUserDto, undefined); // No creator to inherit from, explicity gymId expected in DTO if needed
    }

    // Admin can create any role (except SA/Admin generally? Logic says Admin creates Profe/Alumno)
    if (creator.role === UserRole.ADMIN) {
      // Allow setting role from DTO, default to ALUMNO if not set
      if (!createUserDto.role) {
        createUserDto.role = UserRole.ALUMNO;
      }
      if (createUserDto.role === UserRole.SUPER_ADMIN) {
        throw new ForbiddenException('Admin cannot create Super Admin');
      }
      return this.usersService.create(createUserDto, creator);
    }

    // Professor can only create Alumno
    if (creator.role === UserRole.PROFE) {
      createUserDto.role = UserRole.ALUMNO; // Force role
      return this.usersService.create(createUserDto, creator); // Assign professor and inherit gym
    }

    throw new ForbiddenException('You do not have permission to create users');
  }

  @Get()
  findAll(
    @Request() req: any,
    @Query('role') role?: string,
    @Query('gymId') gymId?: string,
  ) {
    const user = req.user;

    if (user.role === UserRole.SUPER_ADMIN) {
      // SA can see all, or filter by gymId if provided
      return this.usersService.findAllStudents(undefined, role, gymId);
    }

    if (user.role === UserRole.ADMIN) {
      const gymId = user.gym?.id;
      if (!gymId) return []; // Safety: If no gym assigned, show nothing instead of everything
      return this.usersService.findAllStudents(undefined, role, gymId);
    }

    if (user.role === UserRole.PROFE) {
      const gymId = user.gym?.id;
      // Professor sees only their students.
      // Also restrict to their gym just in case
      if (!gymId) return []; // Safety
      return this.usersService.findAllStudents(user.id, role, gymId);
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
  async updateProfile(
    @Body() updateUserDto: UpdateUserDto,
    @Request() req: any,
  ) {
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

  private async validateAccess(
    user: any,
    requestor: any,
    action: 'view' | 'update' | 'delete',
  ) {
    if (requestor.role === UserRole.SUPER_ADMIN) return true;

    // Check Tenancy (Admin/Profe/Student must match Gym)
    if (user.gym?.id !== requestor.gym?.id) {
      // Exception: maybe User has no gym (system)?
      // But for now, strict isolation.
      throw new ForbiddenException('Access denied (Different Gym)');
    }

    if (requestor.role === UserRole.ADMIN) return true; // Admin manages all in their gym

    if (requestor.role === UserRole.PROFE) {
      // Profe sees own students
      // Self access?
      if (action === 'view' && user.id === requestor.id) return true;

      if (user.professor?.id === requestor.id) return true;
      throw new ForbiddenException('You can only access your own students');
    }

    if (requestor.role === UserRole.ALUMNO) {
      // Alumno only self
      if (user.id === requestor.id) return true;
    }

    throw new ForbiddenException('Access denied');
  }

  @Get(':id')
  async findOne(@Param('id') id: string, @Request() req: any) {
    const user = await this.usersService.findOne(id);
    const requestor = req.user;

    if (!user) throw new NotFoundException('User not found');

    await this.validateAccess(user, requestor, 'view');
    return user;
  }

  @Patch(':id')
  async update(
    @Param('id') id: string,
    @Body() updateUserDto: UpdateUserDto,
    @Request() req: any,
  ) {
    const requestor = req.user;
    const userToUpdate = await this.usersService.findOne(id); // Fetch first to check gym
    if (!userToUpdate) throw new NotFoundException('User not found');

    await this.validateAccess(userToUpdate, requestor, 'update');

    // Field restrictions logic
    if (requestor.role === UserRole.PROFE) {
      // Professors can likely edit typical student management fields
      const allowedStudentFields = [
        'trainingGoal',
        'professorObservations',
        'notes',
      ];
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

    // Admin/SA Update
    return this.usersService.update(id, updateUserDto);
  }

  @Patch(':id/payment-status')
  async updatePaymentStatus(@Param('id') id: string, @Request() req: any) {
    const requestor = req.user;
    // Only Admin/SuperAdmin can mark as paid
    if (
      requestor.role !== UserRole.ADMIN &&
      requestor.role !== UserRole.SUPER_ADMIN
    ) {
      throw new ForbiddenException('Only Admins can update payment status');
    }

    const user = await this.usersService.findOne(id);
    if (!user) throw new NotFoundException('User not found');

    await this.validateAccess(user, requestor, 'update');

    return this.usersService.markAsPaid(id);
  }

  @Delete(':id')
  async remove(@Param('id') id: string, @Request() req: any) {
    const requestor = req.user;
    const userToDelete = await this.usersService.findOne(id); // Fetch to check gym
    if (!userToDelete) throw new NotFoundException('User not found');

    await this.validateAccess(userToDelete, requestor, 'delete');

    return this.usersService.remove(id);
  }
}
