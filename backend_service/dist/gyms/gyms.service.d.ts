import { Repository } from 'typeorm';
import { Gym } from './entities/gym.entity';
import { CreateGymDto } from './dto/create-gym.dto';
import { UpdateGymDto } from './dto/update-gym.dto';
import { ExercisesService } from '../exercises/exercises.service';
export declare class GymsService {
    private gymsRepository;
    private exercisesService;
    constructor(gymsRepository: Repository<Gym>, exercisesService: ExercisesService);
    create(createGymDto: CreateGymDto): Promise<Gym>;
    findAll(): Promise<Gym[]>;
    findOne(id: string): Promise<Gym | null>;
    update(id: string, updateGymDto: UpdateGymDto): Promise<Gym | null>;
    remove(id: string): Promise<import("typeorm").DeleteResult>;
    countAll(): Promise<number>;
    debugGenerateExercises(gymId: string): Promise<{
        error: string;
        success?: undefined;
        logs?: undefined;
        result?: undefined;
    } | {
        success: boolean;
        logs: string[];
        result: import("../exercises/entities/exercise.entity").Exercise;
        error?: undefined;
    } | {
        success: boolean;
        logs: string[];
        error: any;
        result?: undefined;
    }>;
    countActive(): Promise<number>;
}
