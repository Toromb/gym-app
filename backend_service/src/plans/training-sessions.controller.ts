import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  UseGuards,
  Request,
  Query,
  BadRequestException,
  ForbiddenException,
  Delete,
} from '@nestjs/common';
import { TrainingSessionsService } from './training-sessions.service';
import { AuthGuard } from '@nestjs/passport';
import { UserRole } from '../users/entities/user.entity';

@Controller('executions')
@UseGuards(AuthGuard('jwt'))
export class TrainingSessionsController {
  constructor(private readonly sessionsService: TrainingSessionsService) { }

  // POST /executions/start
  @Post('start')
  async startSession(
    @Request() req: any,
    @Body()
    body: {
      planId?: string; // Optional now
      weekNumber?: number;
      dayOrder?: number;
      date?: string;
    },
  ) {
    if (!body.date) body.date = new Date().toISOString().split('T')[0];

    return this.sessionsService.startSession(
      req.user.id,
      body.planId || null,
      body.weekNumber,
      body.dayOrder,
      body.date,
    );
  }

  // PATCH /executions/exercises/:id
  @Patch('exercises/:id')
  async updateExercise(
    @Request() req: any,
    @Param('id') exerciseExecId: string,
    @Body() body: any,
  ) {
    return this.sessionsService.updateExercise(exerciseExecId, body);
  }

  // DELETE /executions/exercises/:id
  @Delete('exercises/:id')
  async deleteExercise(
    @Request() req: any,
    @Param('id') exerciseExecId: string
  ) {
    // Authorization logic moved to service
    return this.sessionsService.deleteSessionExercise(exerciseExecId, req.user);
  }

  // PATCH /executions/:id/complete
  @Patch(':id/complete')
  async completeSession(
    @Request() req: any,
    @Param('id') id: string,
    @Body() body: { date: string },
  ) {
    if (req.user.role !== UserRole.ALUMNO && req.user.role !== UserRole.PROFE) {
      throw new ForbiddenException(
        'Only Student or Professor can complete sessions',
      );
    }

    if (!body.date)
      throw new BadRequestException('Date is required to complete session');

    return this.sessionsService.completeSession(id, req.user.id, body.date);
  }

  // POST /executions/:id/exercises
  @Post(':id/exercises')
  async addExercise(
    @Request() req: any,
    @Param('id') sessionId: string,
    @Body() body: { exerciseId: string; sets?: number; reps?: string; weight?: string },
  ) {
    if (!body.exerciseId) throw new BadRequestException('exerciseId required');
    return this.sessionsService.addSessionExercise(sessionId, body.exerciseId, body);
  }

  // POST /executions/:id/debug-sync (Temporary Debug)
  @Post(':id/debug-sync')
  async debugSync(@Param('id') id: string) {
    return this.sessionsService.syncSession(id);
  }

  // GET /executions/calendar
  @Get('calendar')
  async getCalendar(
    @Request() req: any,
    @Query('from') from: string,
    @Query('to') to: string,
  ) {
    if (!from || !to)
      throw new BadRequestException('from and to dates required');

    return this.sessionsService.getCalendar(req.user.id, from, to);
  }

  // GET /executions/:id
  @Get(':id')
  async getSession(@Request() req: any, @Param('id') id: string) {
    return this.sessionsService.findOne(id);
  }

  @Get('history/structure')
  async getSessionByStructure(
    @Request() req: any,
    @Query('studentId') studentId: string,
    @Query('planId') planId: string,
    @Query('week') week: number,
    @Query('day') day: number,
    @Query('startDate') startDate?: string,
  ) {
    if (
      req.user.role !== UserRole.PROFE &&
      req.user.role !== UserRole.ADMIN &&
      req.user.role !== UserRole.SUPER_ADMIN
    ) {
      if (req.user.id !== studentId) {
        throw new ForbiddenException('Access denied');
      }
    }

    return this.sessionsService.findSessionByStructure(
      studentId,
      planId,
      Number(week),
      Number(day),
      startDate,
    );
  }
}
