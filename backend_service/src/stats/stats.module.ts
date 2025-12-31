import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { StatsController } from './stats.controller';
import { UsersModule } from '../users/users.module';
import { GymsModule } from '../gyms/gyms.module';
import { ExercisesModule } from '../exercises/exercises.module';
import { MuscleLoadController } from './muscle-load.controller';
import { MuscleLoadService } from './muscle-load.service';
import { MuscleLoadLedger } from './entities/muscle-load-ledger.entity';
import { MuscleLoadState } from './entities/muscle-load-state.entity';
import { Muscle } from '../exercises/entities/muscle.entity';
import { ExerciseMuscle } from '../exercises/entities/exercise-muscle.entity';
import { UserStats } from './entities/user-stats.entity';
import { TrainingSession } from '../plans/entities/training-session.entity';
import { StatsService } from './stats.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      MuscleLoadLedger,
      MuscleLoadState,
      Muscle,
      ExerciseMuscle,
      UserStats, // Added
      TrainingSession // Added for StatsService queries
    ]),
    UsersModule,
    GymsModule,
    ExercisesModule, // For Muscle/ExerciseMuscle repos
  ],
  controllers: [StatsController, MuscleLoadController],
  providers: [MuscleLoadService, StatsService], // Added StatsService
  exports: [MuscleLoadService, StatsService], // Exported
})
export class StatsModule { }

