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
    imageUrl?: string;
}
