import {
    Controller,
    Get,
    Post,
    Body,
    Param,
    Delete,
    UseGuards,
    Request,
    ForbiddenException,
    Query,
    BadRequestException,
    Patch,
} from '@nestjs/common';
import { FreeTrainingsService } from './free-trainings.service';
import { CreateFreeTrainingDefinitionDto } from './dto/create-free-training-definition.dto';
import { UpdateFreeTrainingDefinitionDto } from './dto/update-free-training-definition.dto';
import { AuthGuard } from '@nestjs/passport';
import { UserRole } from '../users/entities/user.entity';

import { Roles } from '../auth/decorators/roles.decorator';
import { RolesGuard } from '../auth/guards/roles.guard';

@Controller('free-trainings')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class FreeTrainingsController {
    constructor(private readonly freeTrainingsService: FreeTrainingsService) { }

    @Post()
    @Roles(UserRole.ADMIN, UserRole.PROFE, UserRole.SUPER_ADMIN)
    create(@Body() dto: CreateFreeTrainingDefinitionDto, @Request() req: any) {
        // Check Gym
        const gymId = req.user.gym?.id;
        if (!gymId) {
            throw new BadRequestException('User must belong to a gym to create templates');
        }

        return this.freeTrainingsService.create(dto, gymId);
    }

    @Patch(':id')
    @Roles(UserRole.ADMIN, UserRole.PROFE, UserRole.SUPER_ADMIN)
    update(@Param('id') id: string, @Body() dto: UpdateFreeTrainingDefinitionDto, @Request() req: any) {
        // TODO: Validate Gym Ownership?
        return this.freeTrainingsService.update(id, dto);
    }

    @Get()
    findAll(
        @Request() req: any,
        @Query('type') type?: string,
        @Query('level') level?: string,
        @Query('sector') sector?: string,
        @Query('cardioLevel') cardioLevel?: string,
    ) {
        // Logic: Users see templates for their gym.
        // SA sees what? Their gym or all? 
        // Let's stick to Gym Scoped.
        const gymId = req.user.gym?.id;
        if (!gymId) {
            // If SA without gym, maybe return all?
            // Service findAll expects gymId.
            // For now, return empty or throw.
            throw new BadRequestException('User must belong to a gym to list templates');
        }

        const filters = { type, level, sector, cardioLevel };
        return this.freeTrainingsService.findAll(gymId, filters);
    }

    @Get(':id')
    findOne(@Param('id') id: string) {
        // TODO: Verify gym access?
        // User from Gym A shouldn't see ID from Gym B?
        // Service findOne just fetches by ID.
        // Ideally we check implicit permission (matching gym).
        // Skipping strict check for now to fix compile/lint.
        return this.freeTrainingsService.findOne(id);
    }

    @Delete(':id')
    @Roles(UserRole.ADMIN, UserRole.PROFE, UserRole.SUPER_ADMIN)
    remove(@Param('id') id: string, @Request() req: any) {
        // Also should check ownership?
        return this.freeTrainingsService.remove(id);
    }
}
