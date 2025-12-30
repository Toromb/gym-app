import { Type } from 'class-transformer';
import {
  IsArray,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  ValidateNested,
  IsUUID,
  IsEnum,
} from 'class-validator';
import { TrainingIntent } from '../entities/plan.entity';

export class CreatePlanExerciseDto {
  @IsOptional()
  @IsUUID()
  id?: string;

  @IsUUID()
  exerciseId: string;

  @IsInt()
  sets: number;

  @IsString()
  reps: string;

  @IsOptional()
  @IsString()
  suggestedLoad?: string;

  @IsOptional()
  @IsString()
  rest?: string;

  @IsOptional()
  @IsString()
  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsString()
  videoUrl?: string;

  @IsInt()
  order: number;

  @IsOptional()
  @IsArray()
  @IsUUID('all', { each: true })
  equipmentIds?: string[];
}

export class CreatePlanDayDto {
  @IsOptional()
  @IsUUID()
  id?: string;

  @IsOptional()
  @IsString()
  title?: string;

  @IsInt()
  dayOfWeek: number;

  @IsInt()
  order: number;

  @IsOptional()
  @IsString()
  dayNotes?: string;

  @IsOptional()
  @IsEnum(TrainingIntent)
  trainingIntent?: TrainingIntent;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreatePlanExerciseDto)
  exercises: CreatePlanExerciseDto[];
}

export class CreatePlanWeekDto {
  @IsOptional()
  @IsUUID()
  id?: string;

  @IsInt()
  weekNumber: number;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreatePlanDayDto)
  days: CreatePlanDayDto[];
}

export class CreatePlanDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsOptional()
  @IsString()
  objective?: string;

  @IsInt()
  durationWeeks: number;

  @IsOptional()
  @IsString()
  generalNotes?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreatePlanWeekDto)
  weeks: CreatePlanWeekDto[];
}
