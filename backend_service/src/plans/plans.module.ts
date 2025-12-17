import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PlansController } from './plans.controller';
import { PlansService } from './plans.service';
import { Plan, PlanDay, PlanExercise } from './entities/plan.entity';
import { PlanWeek } from './entities/plan-week.entity';
import { StudentPlan } from './entities/student-plan.entity';
import { ExercisesModule } from '../exercises/exercises.module';
import { UsersModule } from '../users/users.module';
import { PlanExecution } from './entities/plan-execution.entity';
import { ExerciseExecution } from './entities/exercise-execution.entity';
import { ExecutionsController } from './executions.controller';
import { ExecutionsService } from './executions.service';

@Module({
    imports: [
        TypeOrmModule.forFeature([
            Plan,
            PlanWeek,
            PlanDay,
            PlanExercise,
            StudentPlan,
            PlanExecution,
            ExerciseExecution
        ]),
        ExercisesModule,
        UsersModule,
    ],
    controllers: [PlansController, ExecutionsController],
    providers: [PlansService, ExecutionsService],
    exports: [PlansService],
})
export class PlansModule { }
