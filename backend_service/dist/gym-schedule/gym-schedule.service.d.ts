import { OnModuleInit } from '@nestjs/common';
import { Repository } from 'typeorm';
import { GymSchedule } from './entities/gym-schedule.entity';
import { UpdateGymScheduleDto } from './dto/update-gym-schedule.dto';
export declare class GymScheduleService implements OnModuleInit {
    private readonly gymScheduleRepository;
    constructor(gymScheduleRepository: Repository<GymSchedule>);
    onModuleInit(): Promise<void>;
    seedDefaults(): Promise<void>;
    findAll(): Promise<GymSchedule[]>;
    update(updateGymScheduleDtos: UpdateGymScheduleDto[]): Promise<GymSchedule[]>;
}
