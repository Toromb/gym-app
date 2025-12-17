import { UsersService } from '../users/users.service';
import { GymsService } from '../gyms/gyms.service';
export declare class StatsController {
    private readonly usersService;
    private readonly gymsService;
    constructor(usersService: UsersService, gymsService: GymsService);
    getPlatformStats(req: any): Promise<{
        totalGyms: number;
        activeGyms: number;
        totalUsers: number;
    }>;
}
