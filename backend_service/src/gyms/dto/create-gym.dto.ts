import { IsString, IsNotEmpty, IsOptional, IsEnum, IsEmail, IsInt } from 'class-validator';
import { GymPlan, GymStatus } from '../entities/gym.entity';

export class CreateGymDto {
    @IsString()
    @IsNotEmpty()
    businessName: string;

    @IsString()
    @IsNotEmpty()
    address: string;

    @IsOptional()
    @IsString()
    phone?: string;

    @IsOptional()
    @IsEmail()
    email?: string;

    @IsOptional()
    @IsEnum(GymStatus)
    status?: GymStatus;

    @IsOptional()
    @IsString()
    suspensionReason?: string;

    @IsOptional()
    @IsEnum(GymPlan)
    subscriptionPlan?: GymPlan;

    @IsOptional()
    expirationDate?: Date;

    @IsOptional()
    @IsInt()
    maxProfiles?: number;

    @IsOptional()
    @IsString()
    logoUrl?: string;

    @IsOptional()
    @IsString()
    primaryColor?: string;

    @IsOptional()
    @IsString()
    secondaryColor?: string;

    @IsOptional()
    @IsString()
    welcomeMessage?: string;

    @IsOptional()
    @IsString()
    openingHours?: string;
}
