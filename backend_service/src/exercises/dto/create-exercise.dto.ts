import { IsNotEmpty, IsOptional, IsString, IsUrl } from 'class-validator';

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
    @IsOptional()
    @IsUrl()
    imageUrl?: string;

    @IsString()
    @IsNotEmpty()
    muscleGroup?: string;

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
