import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ExercisesService } from './exercises.service';
import { ExercisesController } from './exercises.controller';
import { Exercise } from './entities/exercise.entity';
import { Muscle } from './entities/muscle.entity';
import { ExerciseMuscle } from './entities/exercise-muscle.entity';
import { Equipment } from './entities/equipment.entity';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Exercise, Muscle, ExerciseMuscle, Equipment]),
    forwardRef(() => UsersModule),
  ],
  controllers: [ExercisesController],
  providers: [ExercisesService],
  exports: [ExercisesService],
})
export class ExercisesModule { }
