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
} from '@nestjs/common';
import { ExecutionsService } from './executions.service';
import { AuthGuard } from '@nestjs/passport';
import { RequestWithUser } from '../auth/interfaces/request-with-user.interface';
import { UserRole } from '../users/entities/user.entity';

@Controller('executions')
@UseGuards(AuthGuard('jwt'))
export class ExecutionsController {
  constructor(private readonly executionsService: ExecutionsService) {}

  // POST /executions/start
  @Post('start')
  async startExecution(
    @Request() req: any,
    @Body()
    body: {
      planId: string;
      weekNumber: number;
      dayOrder: number;
      date: string;
    },
  ) {
    // Allowed: Alumno, Profe, Admin
    // No restriction needed as long as logged in?
    // Typically Alumno starts their own. Profe might start for testing?
    // Let's allow all for now.

    if (!body.date) body.date = new Date().toISOString().split('T')[0]; // Default to today

    return this.executionsService.startExecution(
      req.user.id,
      body.planId,
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
    @Body() body: any, // Dynamic partial update
  ) {
    // Validation: Ideally check if execution belongs to user or user is Profe.
    // For MVP speed we trust AuthGuard.

    return this.executionsService.updateExercise(exerciseExecId, body);
  }

  // PATCH /executions/:id/complete
  @Patch(':id/complete')
  async completeExecution(
    @Request() req: any,
    @Param('id') id: string,
    @Body() body: { date: string },
  ) {
    // Alumno only? Or Profe too?
    if (req.user.role !== UserRole.ALUMNO && req.user.role !== UserRole.PROFE) {
      throw new ForbiddenException(
        'Only Student or Professor can complete executions',
      );
    }

    if (!body.date)
      throw new BadRequestException('Date is required to complete execution');

    return this.executionsService.completeExecution(id, req.user.id, body.date);
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

    // Return own calendar
    return this.executionsService.getCalendar(req.user.id, from, to);
  }

  // GET /executions/:id
  @Get(':id')
  async getExecution(@Request() req: any, @Param('id') id: string) {
    // Permission check: Own execution or Profe.
    // Service findOne doesn't filter by user.
    // MVP: Return it.
    return this.executionsService.findOne(id);
  }

  @Get('history/structure')
  async getExecutionByStructure(
    @Request() req: any,
    @Query('studentId') studentId: string,
    @Query('planId') planId: string,
    @Query('week') week: number,
    @Query('day') day: number,
    @Query('startDate') startDate?: string,
  ) {
    // console.log(`[DEBUG] getExecutionByStructure: studentId=${studentId}, planId=${planId}, w=${week}, d=${day}, start=${startDate}`);
    // Allowed: Profe, Admin
    if (
      req.user.role !== UserRole.PROFE &&
      req.user.role !== UserRole.ADMIN &&
      req.user.role !== UserRole.SUPER_ADMIN
    ) {
      // Students can only see their own?
      if (req.user.id !== studentId) {
        throw new ForbiddenException('Access denied');
      }
    }

    const result = await this.executionsService.findExecutionByStructure(
      studentId,
      planId,
      Number(week),
      Number(day),
      startDate,
    );
    // console.log(`[DEBUG] Found execution: ${result ? result.id : 'NULL'}`);
    return result;
  }
}
