import {
  Controller,
  Get,
  UseGuards,
  ForbiddenException,
  Request,
  Param,
} from '@nestjs/common';
import { RequestWithUser } from '../auth/interfaces/request-with-user.interface';
import { AuthGuard } from '@nestjs/passport';
import { UsersService } from '../users/users.service';
import { GymsService } from '../gyms/gyms.service';
import { StatsService } from './stats.service';
import { UserRole } from '../users/entities/user.entity';

import { Roles } from '../auth/decorators/roles.decorator';
import { RolesGuard } from '../auth/guards/roles.guard';

@Controller('stats')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class StatsController {
  constructor(
    private readonly usersService: UsersService,
    private readonly gymsService: GymsService,
    private readonly statsService: StatsService,
  ) { }

  @Get('progress')
  async getMyProgress(@Request() req: any) {
    console.log(`[StatsController] GET /progress for user ${req.user.id}`);
    const result = await this.statsService.getProgress(req.user.id);
    console.log(`[StatsController] Result:`, JSON.stringify(result));
    return result;
  }

  @Get('progress/:userId')
  async getUserProgress(@Request() req: any, @Param('userId') userId: string) {
    // Check permissions: User must be PROFE, ADMIN, SUPER_ADMIN or the user themselves
    const requestingUser = req.user;
    if (
      requestingUser.role === UserRole.ALUMNO &&
      requestingUser.id !== userId
    ) {
      throw new ForbiddenException('You can only view your own progress');
    }
    return this.statsService.getProgress(userId);
  }

  @Get()
  @Roles(UserRole.SUPER_ADMIN)
  async getPlatformStats(@Request() req: any) {
    const user = req.user;
    // Removed manual check

    const stats = {
      totalGyms: await this.gymsService.countAll(),
      activeGyms: await this.gymsService.countActive(),
      totalUsers: await this.usersService.countAll(),
    };

    return stats;
  }
}
