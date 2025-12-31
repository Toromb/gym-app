import { IsNotEmpty, IsOptional, IsString, IsUrl, IsUUID, IsEnum, IsNumber, Min, Max, ValidateNested, IsArray } from 'class-validator';
import { Type } from 'class-transformer';
import { MuscleRole } from '../entities/exercise-muscle.entity';

export class ExerciseMuscleDto {
  @IsUUID()
  muscleId: string;

  @IsEnum(MuscleRole)
  role: MuscleRole;

  @IsNumber()
  @Min(0)
  @Max(100)
  loadPercentage: number;
}

export class CreateExerciseDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsUrl()
  videoUrl?: string;

  @IsOptional()
  @IsUrl()
  imageUrl?: string;

  // Legacy field - made optional as it will be auto-calculated
  @IsOptional()
  @IsString()
  muscleGroup?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ExerciseMuscleDto)
  muscles: ExerciseMuscleDto[];

  @IsOptional()
  @IsEnum(['REPS', 'TIME', 'DISTANCE'])
  metricType?: 'REPS' | 'TIME' | 'DISTANCE';

  @IsOptional()
  @IsNumber()
  defaultTime?: number;

  @IsOptional()
  @IsNumber()
  minTime?: number;

  @IsOptional()
  @IsNumber()
  maxTime?: number;

  @IsOptional()
  @IsNumber()
  defaultDistance?: number;

  @IsOptional()
  @IsNumber()
  minDistance?: number;

  @IsOptional()
  @IsNumber()
  maxDistance?: number;

  @IsOptional()
  @IsString()
  type?: string;

  @IsOptional()
  sets?: number;

  @IsOptional()
  @IsString()
  reps?: string;

  @IsOptional()
  @IsString()
  rest?: string;

  @IsOptional()
  @IsString()
  load?: string;

  @IsOptional()
  @IsString()
  notes?: string;

  // Professional Exercise Change System Config
  @IsOptional()
  @IsNumber()
  loadFactor?: number;

  @IsOptional()
  @IsNumber()
  defaultSets?: number;

  @IsOptional()
  @IsNumber()
  minReps?: number;

  @IsOptional()
  @IsNumber()
  maxReps?: number;
}
