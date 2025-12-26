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
} from '@nestjs/common';
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

  @Get()
  async findAll(@Request() req: any, @Query('muscleId') muscleId?: string) {
    if (req.user.role === UserRole.SUPER_ADMIN) {
      return this.exercisesService.findAll(undefined, muscleId);
    }
    const gymId = req.user.gym?.id;
    console.log(`[Exercises] DEBUG: User ${req.user.email} (Role: ${req.user.role}). Gym Object:`, req.user.gym);
    console.log(`[Exercises] DEBUG: Gym ID extracted: ${gymId}`);

    if (!gymId) {
      console.log('[Exercises] No Gym ID found for user');
      return [];
    }
    const results = await this.exercisesService.findAll(gymId, muscleId);
    console.log(`[Exercises] Found ${results.length} exercises for Gym ${gymId}`);
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
