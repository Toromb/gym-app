import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Request, ForbiddenException, UseInterceptors, UploadedFile, BadRequestException } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { existsSync, mkdirSync } from 'fs';
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
            throw new ForbiddenException('Only Super Admin can access this resource.');
        }
    }

    private validateAdminAccess(user: any, targetGymId: string) {
        if (user.role === UserRole.SUPER_ADMIN) return;
        if (user.role === UserRole.ADMIN) {
            // Check if user belongs to the target gym
            if (user.gym && user.gym.id === targetGymId) {
                return;
            }
        }
        throw new ForbiddenException('You do not have permission to modify this gym.');
    }

    @Post()
    create(@Body() createGymDto: CreateGymDto, @Request() req: any) {
        this.checkSuperAdmin(req.user);
        return this.gymsService.create(createGymDto);
    }

    @Get()
    findAll(@Request() req: any) {
        this.checkSuperAdmin(req.user);
        return this.gymsService.findAll();
    }

    @Get(':id')
    findOne(@Param('id') id: string, @Request() req: any) {
        // Allow user to see their own gym?
        // Current requirement says "Professional and Students just visualize".
        // If I am a student of Gym A, can I see Gym A details? Yes.
        // So validation should be: Super Admin OR (Any Role AND user.gym.id == id).
        if (req.user.role !== UserRole.SUPER_ADMIN) {
            if (!req.user.gym || req.user.gym.id !== id) {
                throw new ForbiddenException('Access denied to this gym data.');
            }
        }
        return this.gymsService.findOne(id);
    }

    @Patch(':id')
    update(@Param('id') id: string, @Body() updateGymDto: UpdateGymDto, @Request() req: any) {
        this.validateAdminAccess(req.user, id);
        return this.gymsService.update(id, updateGymDto);
    }

    @Delete(':id')
    remove(@Param('id') id: string, @Request() req: any) {
        this.checkSuperAdmin(req.user);
        return this.gymsService.remove(id);
    }

    @Post(':id/logo')
    @UseInterceptors(FileInterceptor('file', {
        storage: diskStorage({
            destination: (req, file, cb) => {
                const uploadPath = './uploads/logos';
                if (!existsSync(uploadPath)) {
                    mkdirSync(uploadPath, { recursive: true });
                }
                cb(null, uploadPath);
            },
            filename: (req, file, cb) => {
                const randomName = Array(32).fill(null).map(() => (Math.round(Math.random() * 16)).toString(16)).join('');
                cb(null, `${randomName}${extname(file.originalname)}`);
            },
        }),
        fileFilter: (req, file, cb) => {
            if (!file.mimetype.match(/\/(jpg|jpeg|png|gif)$/)) {
                return cb(new BadRequestException('Only image files are allowed!'), false);
            }
            cb(null, true);
        },
        limits: {
            fileSize: 5 * 1024 * 1024 // 5MB
        }
    }))
    async uploadLogo(@Param('id') id: string, @UploadedFile() file: any, @Request() req: any) { // Using any for file to avoid express types hassle if not imported
        this.validateAdminAccess(req.user, id);
        if (!file) throw new BadRequestException('File is not an image or was rejected');

        const logoUrl = `/uploads/logos/${file.filename}`;
        await this.gymsService.update(id, { logoUrl } as any);
        return { logoUrl };
    }
}
