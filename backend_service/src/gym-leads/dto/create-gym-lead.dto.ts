import { IsNotEmpty, IsEmail, IsOptional, IsInt, IsString, IsIn, Min } from 'class-validator';

export class CreateGymLeadDto {
    @IsNotEmpty()
    @IsString()
    fullName: string;

    @IsNotEmpty()
    @IsString()
    gymName: string;

    @IsNotEmpty()
    @IsString()
    city: string;

    @IsNotEmpty()
    @IsEmail()
    email: string;

    @IsNotEmpty()
    @IsString()
    phone: string;

    @IsOptional()
    @IsInt()
    @Min(0)
    studentsCount?: number;

    @IsOptional()
    @IsString()
    message?: string;

    @IsOptional()
    @IsIn(['mobile_app', 'web_app'])
    source?: 'mobile_app' | 'web_app';
}
