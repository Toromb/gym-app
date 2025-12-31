import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Request,
  NotFoundException,
  ForbiddenException,
  UseInterceptors,
  ClassSerializerInterceptor,
  Patch,
  Delete,
} from '@nestjs/common';
import { PlansService } from './plans.service';
import { RequestWithUser } from '../auth/interfaces/request-with-user.interface';
import { AuthGuard } from '@nestjs/passport';
import { CreatePlanDto } from './dto/create-plan.dto';
import { UserRole } from '../users/entities/user.entity';

import { UpdatePlanDto } from './dto/update-plan.dto';

@Controller('plans')
@UseGuards(AuthGuard('jwt'))
@UseInterceptors(ClassSerializerInterceptor)
export class PlansController {
  constructor(private readonly plansService: PlansService) { }

  @Post()
  create(@Body() createPlanDto: CreatePlanDto, @Request() req: any) {
    // Only Teacher/Admin can create plans
    // Ideally use a custom Guard or check role here
    if (req.user.role === UserRole.ALUMNO) {
      throw new ForbiddenException('Only teachers and admins can create plans');
    }
    return this.plansService.create(createPlanDto, req.user);
  }

  @Get()
  findAll(@Request() req: any) {
    if (req.user.role === UserRole.SUPER_ADMIN) {
      return this.plansService.findAll();
    }

    if (req.user.role === UserRole.PROFE || req.user.role === UserRole.ADMIN) {
      const gymId = req.user.gym?.id;
      // console.log(`[PlansController] findAll - User: ${req.user.email}, Role: ${req.user.role}, Gym: ${gymId}`);
      if (!gymId) {
        return [];
      }
      return this.plansService.findAll(gymId);
    }

    return [];
  }

  @Get('student/my-plan')
  async getMyPlan(@Request() req: any) {
    const plan = await this.plansService.findStudentPlan(req.user.id);
    if (!plan) {
      throw new NotFoundException('No active plan found');
    }
    return plan;
  }

  @Get('student/history')
  async getMyHistory(@Request() req: any) {
    // Allow student to see their own history
    return this.plansService.findStudentAssignments(req.user.id);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.plansService.findOne(id);
  }

<<<<<<< HEAD
    @Post('assign')
    assignPlan(@Body() body: { planId: string; studentId: string }, @Request() req: any) {
        if (req.user.role !== UserRole.PROFE && req.user.role !== UserRole.ADMIN) {
            throw new ForbiddenException('Only professors and admins can assign plans');
        }
        return this.plansService.assignPlan(body.planId, body.studentId, req.user);
=======
  @Patch(':id')
  update(
    @Param('id') id: string,
    @Body() updatePlanDto: UpdatePlanDto,
    @Request() req: any,
  ) {
    // Allow Admin or Profe (any Profe can edit any plan per requirements)
    if (req.user.role !== UserRole.ADMIN && req.user.role !== UserRole.PROFE) {
      throw new ForbiddenException('Only admins and professors can edit plans');
>>>>>>> feature/payment-info
    }
    console.log('Update Payload RAW:', JSON.stringify(updatePlanDto, null, 2));
    return this.plansService.update(id, updatePlanDto, req.user);
  }

  @Post('assign')
  assignPlan(
    @Body() body: { planId: string; studentId: string },
    @Request() req: any,
  ) {
    if (req.user.role !== UserRole.PROFE && req.user.role !== UserRole.ADMIN) {
      throw new ForbiddenException(
        'Only professors and admins can assign plans',
      );
    }
    return this.plansService.assignPlan(
      body.planId,
      body.studentId,
      req.user.id,
    );
  }

  @Get('assignments/student/:studentId')
  getStudentAssignments(
    @Param('studentId') studentId: string,
    @Request() req: any,
  ) {
    // Teacher/Admin can view.
    // Permission check is implicit in Service (if we move logic there) or here.
    // For 'Profe' role, ideally verify that the student belongs to them.
    // But for MVP, allowing them to fetch plans for a known ID might be acceptable, OR we enforce it.
    // Let's enforce it loosely or assume UI handles navigation context.
    if (req.user.role !== UserRole.PROFE && req.user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Access denied');
    }
    return this.plansService.findAllAssignmentsByStudent(studentId);
  }

  @Delete('assignments/:id')
  deleteAssignment(@Param('id') id: string, @Request() req: any) {
    return this.plansService.removeAssignment(id, req.user);
  }

  @Delete(':id')
  remove(@Param('id') id: string, @Request() req: any) {
    return this.plansService.remove(id, req.user);
  }

  @Patch('student/progress')
  updateProgress(
    @Body()
    body: {
      studentPlanId: string;
      type: 'exercise' | 'day';
      id: string;
      completed: boolean;
      date?: string;
    },
    @Request() req: any,
  ) {
    return this.plansService.updateProgress(
      body.studentPlanId,
      req.user.id,
      body,
    );
  }

  @Post('student/restart/:assignmentId')
  restartAssignment(
    @Param('assignmentId') assignmentId: string,
    @Request() req: any,
  ) {
    return this.plansService.restartAssignment(assignmentId, req.user.id);
  }
}
