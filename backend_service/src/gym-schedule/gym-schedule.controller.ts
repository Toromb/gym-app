import { Body, Controller, Get, Put, UseGuards, Request, ForbiddenException } from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation, ApiResponse, ApiBody } from '@nestjs/swagger';
import { GymScheduleService } from './gym-schedule.service';
import { UpdateGymScheduleDto } from './dto/update-gym-schedule.dto';
import { AuthGuard } from '@nestjs/passport';
import { UserRole } from '../users/entities/user.entity';

@ApiTags('gym-schedule')
@ApiBearerAuth()
@Controller('gym-schedule')
@UseGuards(AuthGuard('jwt'))
export class GymScheduleController {
    constructor(private readonly gymScheduleService: GymScheduleService) { }

    @Get()
    @ApiOperation({ summary: 'Get gym schedule' })
    @ApiResponse({ status: 200, description: 'Return all gym schedules.' })
    findAll(@Request() req: any) {
        const gymId = req.user.gym?.id;
        // If SA and query param? For MVP, just use user's gym.
        // If no gym (e.g. fresh SA), return empty.
        return this.gymScheduleService.findAll(gymId);
    }

    @Put()
    @ApiOperation({ summary: 'Update gym schedule' })
    @ApiBody({ type: [UpdateGymScheduleDto] })
    @ApiResponse({ status: 200, description: 'The gym schedule has been successfully updated.' })
    update(@Body() updateGymScheduleDtos: UpdateGymScheduleDto[], @Request() req: any) {
        if (req.user.role !== UserRole.ADMIN) {
            throw new ForbiddenException('Only admin can update schedule');
        }
        const gymId = req.user.gym?.id;
        if (!gymId) throw new ForbiddenException('No gym associated with admin');

        return this.gymScheduleService.update(updateGymScheduleDtos, gymId);
    }
}
