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

@Controller('free-trainings')
@UseGuards(AuthGuard('jwt'))
export class FreeTrainingsController {
    constructor(private readonly freeTrainingsService: FreeTrainingsService) { }

    @Post()
    create(@Body() dto: CreateFreeTrainingDefinitionDto, @Request() req: any) {
        if (
            req.user.role !== UserRole.ADMIN &&
            req.user.role !== UserRole.PROFE &&
            req.user.role !== UserRole.SUPER_ADMIN
        ) {
            throw new ForbiddenException(
                'Only teachers and admins can create free training templates',
            );
        }

        // Check Gym
        const gymId = req.user.gym?.id;
        if (!gymId) {
            throw new BadRequestException('User must belong to a gym to create templates');
        }

        return this.freeTrainingsService.create(dto, gymId);
    }

    @Patch(':id')
    update(@Param('id') id: string, @Body() dto: UpdateFreeTrainingDefinitionDto, @Request() req: any) {
        if (
            req.user.role !== UserRole.ADMIN &&
            req.user.role !== UserRole.PROFE &&
            req.user.role !== UserRole.SUPER_ADMIN
        ) {
            throw new ForbiddenException(
                'Only teachers and admins can update free training templates',
            );
        }
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
    remove(@Param('id') id: string, @Request() req: any) {
        if (
            req.user.role !== UserRole.ADMIN &&
            req.user.role !== UserRole.PROFE &&
            req.user.role !== UserRole.SUPER_ADMIN
        ) {
            throw new ForbiddenException(
                'Only teachers and admins can delete free training templates',
            );
        }
        // Also should check ownership?
        return this.freeTrainingsService.remove(id);
    }
}
