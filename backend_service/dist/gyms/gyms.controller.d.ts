import { GymsService } from './gyms.service';
import { CreateGymDto } from './dto/create-gym.dto';
import { UpdateGymDto } from './dto/update-gym.dto';
export declare class GymsController {
    private readonly gymsService;
    constructor(gymsService: GymsService);
    private checkSuperAdmin;
    private validateAdminAccess;
    create(createGymDto: CreateGymDto, req: any): Promise<import("./entities/gym.entity").Gym>;
    findAll(req: any): Promise<import("./entities/gym.entity").Gym[]>;
    findOne(id: string, req: any): Promise<import("./entities/gym.entity").Gym | null>;
    update(id: string, updateGymDto: UpdateGymDto, req: any): Promise<import("./entities/gym.entity").Gym | null>;
    remove(id: string, req: any): Promise<import("typeorm").DeleteResult>;
    uploadLogo(id: string, file: any, req: any): Promise<{
        logoUrl: string;
    }>;
}
