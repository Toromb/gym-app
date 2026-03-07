import { Controller, Post, Get, Body, UseGuards } from '@nestjs/common';
import { GymLeadsService } from './gym-leads.service';
import { CreateGymLeadDto } from './dto/create-gym-lead.dto';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';
import { RolesGuard } from '../auth/guards/roles.guard';
import { AuthGuard } from '@nestjs/passport';
import { Throttle } from '@nestjs/throttler';

@Controller('gym-leads')
export class GymLeadsController {
    constructor(private readonly gymLeadsService: GymLeadsService) { }

    @Throttle({ default: { limit: 3, ttl: 60000 } }) // 3 leads per minute per IP to prevent spam
    @Post()
    async create(@Body() createGymLeadDto: CreateGymLeadDto) {
        return await this.gymLeadsService.create(createGymLeadDto);
    }

    // Only global SUPER_ADMINs should be able to list business leads
    @UseGuards(AuthGuard('jwt'), RolesGuard)
    @Roles(UserRole.SUPER_ADMIN)
    @Get()
    async findAll() {
        return await this.gymLeadsService.findAll();
    }
}
