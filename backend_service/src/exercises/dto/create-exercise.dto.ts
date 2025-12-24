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
}
