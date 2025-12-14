import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Request, ForbiddenException } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { UserRole } from '../users/entities/user.entity';
import { GymsService } from './gyms.service';
import { RequestWithUser } from '../auth/interfaces/request-with-user.interface';
import { CreateGymDto } from './dto/create-gym.dto';
import { UpdateGymDto } from './dto/update-gym.dto';

@Controller('gyms')
@UseGuards(AuthGuard('jwt'))
export class GymsController {
    constructor(private readonly gymsService: GymsService) { }

    private checkSuperAdmin(user: any) {
        if (user.role !== UserRole.SUPER_ADMIN) {
            throw new ForbiddenException('Only Super Admin can access gyms.');
        }
    }

    @Post()
    create(@Body() createGymDto: CreateGymDto, @Request() req: RequestWithUser) {
        this.checkSuperAdmin(req.user);
        return this.gymsService.create(createGymDto);
    }

    @Get()
    findAll(@Request() req: RequestWithUser) {
        this.checkSuperAdmin(req.user);
        return this.gymsService.findAll();
    }

    @Get(':id')
    findOne(@Param('id') id: string, @Request() req: RequestWithUser) {
        this.checkSuperAdmin(req.user);
        return this.gymsService.findOne(id);
    }

    @Patch(':id')
    update(@Param('id') id: string, @Body() updateGymDto: UpdateGymDto, @Request() req: RequestWithUser) {
        this.checkSuperAdmin(req.user);
        return this.gymsService.update(id, updateGymDto);
    }

    @Delete(':id')
    remove(@Param('id') id: string, @Request() req: RequestWithUser) {
        this.checkSuperAdmin(req.user);
        // Maybe check if gym has users before delete? 
        // Service handles delete, but we should be careful.
        // For MVP, just allow if SA wants it.
        return this.gymsService.remove(id);
    }
}
