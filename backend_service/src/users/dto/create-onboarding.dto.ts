import { IsEnum, IsString, IsOptional, IsArray, IsDateString, IsNumber, IsBoolean, IsNotEmpty } from 'class-validator';
import { TrainingGoal, ExperienceLevel, ActivityLevel, TrainingFrequency } from '../entities/onboarding-profile.entity';

export class CreateOnboardingDto {
    // --- Profile Fields ---
    @IsEnum(TrainingGoal)
    goal: TrainingGoal;

    @IsOptional()
    @IsString()
    goalDetails?: string;

    @IsEnum(ExperienceLevel)
    experience: ExperienceLevel;

    @IsArray()
    @IsString({ each: true })
    injuries: string[];

    @IsOptional()
    @IsString()
    injuryDetails?: string;

    @IsEnum(ActivityLevel)
    activityLevel: ActivityLevel;

    @IsEnum(TrainingFrequency)
    desiredFrequency: TrainingFrequency;

    @IsOptional()
    @IsString()
    preferences?: string;

    @IsNotEmpty()
    @IsBoolean()
    canLieDown: boolean;

    @IsNotEmpty()
    @IsBoolean()
    canKneel: boolean;

    // --- User Update Fields ---
    @IsOptional()
    @IsDateString()
    birthDate?: string;

    @IsOptional()
    @IsNumber()
    weight?: number;

    @IsOptional()
    @IsNumber()
    height?: number;

    @IsOptional()
    @IsString()
    phone?: string;

    @IsOptional()
    @IsString()
    gender?: string;
}
