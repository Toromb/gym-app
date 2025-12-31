import {
  Controller,
  Get,
  UseGuards,
  ForbiddenException,
  Request,
} from '@nestjs/common';
import { RequestWithUser } from '../auth/interfaces/request-with-user.interface';
import { AuthGuard } from '@nestjs/passport';
import { UsersService } from '../users/users.service';
import { GymsService } from '../gyms/gyms.service';
import { UserRole } from '../users/entities/user.entity';

@Controller('stats')
@UseGuards(AuthGuard('jwt'))
export class StatsController {
  constructor(
    private readonly usersService: UsersService,
    private readonly gymsService: GymsService,
  ) {}

  @Get()
  async getPlatformStats(@Request() req: any) {
    const user = req.user;
    if (user.role !== UserRole.SUPER_ADMIN) {
      throw new ForbiddenException(
        'Only Super Admin can access platform stats',
      );
    }

    const stats = {
      totalGyms: await this.gymsService.countAll(),
      activeGyms: await this.gymsService.countActive(),
      totalUsers: await this.usersService.countAll(),
    };

    return stats;
  }
}
