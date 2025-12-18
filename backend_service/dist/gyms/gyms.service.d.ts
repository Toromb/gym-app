import { Repository } from 'typeorm';
import { Gym } from './entities/gym.entity';
import { CreateGymDto } from './dto/create-gym.dto';
import { UpdateGymDto } from './dto/update-gym.dto';
export declare class GymsService {
    private gymsRepository;
    constructor(gymsRepository: Repository<Gym>);
    create(createGymDto: CreateGymDto): Promise<Gym>;
    findAll(): Promise<Gym[]>;
    findOne(id: string): Promise<Gym | null>;
    update(id: string, updateGymDto: UpdateGymDto): Promise<import("typeorm").UpdateResult>;
    remove(id: string): Promise<import("typeorm").DeleteResult>;
    countAll(): Promise<number>;
    countActive(): Promise<number>;
}
