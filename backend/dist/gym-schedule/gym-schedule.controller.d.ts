import { GymScheduleService } from './gym-schedule.service';
import { UpdateGymScheduleDto } from './dto/update-gym-schedule.dto';
export declare class GymScheduleController {
    private readonly gymScheduleService;
    constructor(gymScheduleService: GymScheduleService);
    findAll(): Promise<import("./entities/gym-schedule.entity").GymSchedule[]>;
    update(updateGymScheduleDtos: UpdateGymScheduleDto[], req: any): Promise<import("./entities/gym-schedule.entity").GymSchedule[]>;
}
