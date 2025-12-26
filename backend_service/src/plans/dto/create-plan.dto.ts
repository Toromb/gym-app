import { Type } from 'class-transformer';
import {
  IsArray,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  ValidateNested,
  IsUUID,
} from 'class-validator';

export class CreatePlanExerciseDto {
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
  @IsString()
  title?: string;

  @IsInt()
  dayOfWeek: number;

  @IsInt()
  order: number;

  @IsOptional()
  @IsString()
  dayNotes?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreatePlanExerciseDto)
  exercises: CreatePlanExerciseDto[];
}

export class CreatePlanWeekDto {
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
