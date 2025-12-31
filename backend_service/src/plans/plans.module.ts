import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PlansController } from './plans.controller';
import { PlansService } from './plans.service';
import { Plan, PlanDay, PlanExercise } from './entities/plan.entity';
import { PlanWeek } from './entities/plan-week.entity';
import { StudentPlan } from './entities/student-plan.entity';
import { ExercisesModule } from '../exercises/exercises.module';
import { Exercise } from '../exercises/entities/exercise.entity';
import { UsersModule } from '../users/users.module';
import { StatsModule } from '../stats/stats.module';
import { TrainingSession } from './entities/training-session.entity';
import { SessionExercise } from './entities/session-exercise.entity';
import { TrainingSessionsController } from './training-sessions.controller';
import { TrainingSessionsService } from './training-sessions.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Plan,
      PlanWeek,
      PlanDay,
      PlanExercise,
      StudentPlan,
      TrainingSession,
      SessionExercise,
      Exercise, // Added for Free Session injection
    ]),
    ExercisesModule,
    UsersModule,
    StatsModule,
  ],
  controllers: [PlansController, TrainingSessionsController],
  providers: [PlansService, TrainingSessionsService],
  exports: [PlansService, TrainingSessionsService],
})
export class PlansModule { }
