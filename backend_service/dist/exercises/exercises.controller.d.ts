import { ExercisesService } from './exercises.service';
import { CreateExerciseDto } from './dto/create-exercise.dto';
import { UpdateExerciseDto } from './dto/update-exercise.dto';
export declare class ExercisesController {
    private readonly exercisesService;
    constructor(exercisesService: ExercisesService);
    create(createExerciseDto: CreateExerciseDto, req: any): Promise<import("./entities/exercise.entity").Exercise>;
    findAll(): Promise<import("./entities/exercise.entity").Exercise[]>;
    findOne(id: string): Promise<import("./entities/exercise.entity").Exercise | null>;
    update(id: string, updateExerciseDto: UpdateExerciseDto): Promise<import("./entities/exercise.entity").Exercise | null>;
    remove(id: string): Promise<void>;
}
