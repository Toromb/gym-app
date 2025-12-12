import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Exercise } from './entities/exercise.entity';
import { CreateExerciseDto } from './dto/create-exercise.dto';
import { User } from '../users/entities/user.entity';

@Injectable()
export class ExercisesService {
    constructor(
        @InjectRepository(Exercise)
        private exercisesRepository: Repository<Exercise>,
    ) { }

    async create(createExerciseDto: CreateExerciseDto, user: User): Promise<Exercise> {
        const exercise = this.exercisesRepository.create({
            ...createExerciseDto,
            createdBy: user,
        });
        return this.exercisesRepository.save(exercise);
    }

    async findAll(): Promise<Exercise[]> {
        return this.exercisesRepository.find();
    }

    async findOne(id: string): Promise<Exercise | null> {
        return this.exercisesRepository.findOne({ where: { id } });
    }

    async remove(id: string): Promise<void> {
        await this.exercisesRepository.delete(id);
    }
}
