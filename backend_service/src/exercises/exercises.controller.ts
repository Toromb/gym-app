import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Request } from '@nestjs/common';
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

    @Get()
    findAll(@Request() req: any) {
        if (req.user.role === UserRole.SUPER_ADMIN) {
            return this.exercisesService.findAll();
        }
        const gymId = req.user.gym?.id;
        if (!gymId) return [];
        return this.exercisesService.findAll(gymId);
    }

    @Get(':id')
    findOne(@Param('id') id: string) {
        return this.exercisesService.findOne(id);
    }

    @Patch(':id')
    update(@Param('id') id: string, @Body() updateExerciseDto: UpdateExerciseDto) {
        return this.exercisesService.update(id, updateExerciseDto);
    }

    @Delete(':id')
    remove(@Param('id') id: string) {
        return this.exercisesService.remove(id);
    }
}
