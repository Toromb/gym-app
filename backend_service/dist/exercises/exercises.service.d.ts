import { Repository } from 'typeorm';
import { Exercise } from './entities/exercise.entity';
import { CreateExerciseDto } from './dto/create-exercise.dto';
import { User } from '../users/entities/user.entity';
import { UpdateExerciseDto } from './dto/update-exercise.dto';
export declare class ExercisesService {
    private exercisesRepository;
    constructor(exercisesRepository: Repository<Exercise>);
    create(createExerciseDto: CreateExerciseDto, user: User): Promise<Exercise>;
    findAll(gymId?: string): Promise<Exercise[]>;
    findOne(id: string): Promise<Exercise | null>;
    update(id: string, updateExerciseDto: UpdateExerciseDto): Promise<Exercise | null>;
    remove(id: string): Promise<void>;
}
