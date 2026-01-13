import { Controller, Get, Param, Req, UseGuards, ForbiddenException, Inject } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { MuscleLoadService } from './muscle-load.service';
import { UsersService } from '../users/users.service';

@Controller('students')
export class MuscleLoadController {
    constructor(
        private readonly muscleLoadService: MuscleLoadService,
        private readonly usersService: UsersService,
    ) { }

    @Get('me/muscle-loads')
    @UseGuards(AuthGuard('jwt'))
    async getMyLoad(@Req() req: any) {
        return this.muscleLoadService.getLoadsForStudent(req.user.id);
    }

    @Get(':studentId/muscle-loads')
    @UseGuards(AuthGuard('jwt'))
    async getStudentLoad(@Param('studentId') studentId: string, @Req() req: any) {
        const user = req.user;

        // Permission Check
        if (user.role === 'admin' || user.role === 'super_admin') {
            // Allow
        } else if (user.role === 'profe') {
            // Strict Check: Professor must belong to same Gym as Student
            const requestingUser = await this.usersService.findOne(user.id);
            const targetStudent = await this.usersService.findOne(studentId);

            if (!requestingUser || !targetStudent) {
                throw new ForbiddenException('User not found');
            }

            if (requestingUser.gym?.id !== targetStudent.gym?.id) {
                throw new ForbiddenException('You can only view stats for students in your Gym');
            }

        } else if (user.id !== studentId) {
            throw new ForbiddenException('You can only view your own stats');
        }

        return this.muscleLoadService.getLoadsForStudent(studentId);
    }
}
