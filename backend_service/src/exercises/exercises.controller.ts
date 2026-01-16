import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  Request,
  Query,
  UseInterceptors,
} from '@nestjs/common';
import { CacheInterceptor } from '@nestjs/cache-manager';
import { ExercisesService } from './exercises.service';
import { RequestWithUser } from '../auth/interfaces/request-with-user.interface';
import { CreateExerciseDto } from './dto/create-exercise.dto';
import { UpdateExerciseDto } from './dto/update-exercise.dto';
import { AuthGuard } from '@nestjs/passport';
import { UserRole } from '../users/entities/user.entity';

@Controller('exercises')
@UseGuards(AuthGuard('jwt'))
export class ExercisesController {
  constructor(private readonly exercisesService: ExercisesService) { }

  @Post()
  create(@Body() createExerciseDto: CreateExerciseDto, @Request() req: any) {
    // Check if user is PROFE or ADMIN (can be done with a custom decorator/guard)
    // For MVP, assuming any authenticated user can create for now, or check role here
    if (req.user.role === UserRole.ALUMNO) {
      // throw new ForbiddenException('Only teachers can create exercises');
    }
    return this.exercisesService.create(createExerciseDto, req.user);
  }

  @Get('muscles')
  getMuscles() {
    return this.exercisesService.findAllMuscles();
  }

  @Get('equipments')
  getEquipments(@Request() req: any) {
    const gymId = req.user.gym?.id;
    return this.exercisesService.findAllEquipments(gymId);
  }

  @Post('equipments')
  createEquipment(@Body() body: { name: string }, @Request() req: any) {
    const gymId = req.user.gym?.id;
    // Access the internal service directly until I expose it better? 
    // exercisesService wraps it now? No, I didn't add create/delete wrappers.
    // I should add wrappers in ExercisesService or inject EquipmentsService here.
    // ExercisesWrapper is better for now to avoid multiple injections if not needed.
    return this.exercisesService.createEquipment(body.name, gymId);
  }

  @Delete('equipments/:id')
  removeEquipment(@Param('id') id: string, @Request() req: any) {
    const gymId = req.user.gym?.id;
    return this.exercisesService.removeEquipment(id, gymId);
  }

  @Get()
  @UseInterceptors(CacheInterceptor)
  async findAll(
    @Request() req: any,
    @Query('muscleId') muscleId?: string,
    @Query('role') role?: string,
    @Query('equipmentIds') equipmentIds?: string | string[],
  ) {
    // Normalize equipmentIds to array
    let eIds: string[] | undefined;
    if (equipmentIds) {
      eIds = Array.isArray(equipmentIds) ? equipmentIds : [equipmentIds];
    }

    if (req.user.role === UserRole.SUPER_ADMIN) {
      return this.exercisesService.findAllFiltered({ muscleId, role, equipmentIds: eIds });
    }
    const gymId = req.user.gym?.id;
    // console.log(`[Exercises] DEBUG: User ${req.user.email} (Role: ${req.user.role}). Gym Object:`, req.user.gym);
    // console.log(`[Exercises] DEBUG: Gym ID extracted: ${gymId}`);

    if (!gymId) {
      // console.log('[Exercises] No Gym ID found for user');
      return [];
    }

    const results = await this.exercisesService.findAllFiltered({ gymId, muscleId, role, equipmentIds: eIds });
    // console.log(`[Exercises] Found ${results.length} exercises for Gym ${gymId}`);
    return results;
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.exercisesService.findOne(id);
  }

  @Patch(':id')
  update(
    @Param('id') id: string,
    @Body() updateExerciseDto: UpdateExerciseDto,
  ) {
    return this.exercisesService.update(id, updateExerciseDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.exercisesService.remove(id);
  }
}
