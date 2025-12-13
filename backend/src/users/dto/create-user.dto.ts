import { IsEmail, IsEnum, IsInt, IsNotEmpty, IsOptional, IsString, MinLength, IsNumber, IsBoolean, IsDateString } from 'class-validator';
import { UserRole, PaymentStatus } from '../entities/user.entity';

export class CreateUserDto {
    @IsString()
    @IsNotEmpty()
    firstName: string;

    @IsString()
    @IsNotEmpty()
    lastName: string;

    @IsEmail()
    email: string;

    @IsOptional()
    @IsString()
    @MinLength(6)
    password?: string;


    @IsOptional()
    @IsString()
    phone?: string;

    @IsOptional()
    @IsInt()
    age?: number;

    @IsOptional()
    @IsString()
    gender?: string;

    @IsOptional()
    @IsString()
    notes?: string;

    @IsOptional()
    @IsEnum(UserRole)
    role?: UserRole;

    @IsOptional()
    @IsNumber()
    height?: number;

    // Student Specific
    @IsOptional()
    @IsString()
    trainingGoal?: string;

    @IsOptional()
    @IsString()
    professorObservations?: string;

    @IsOptional()
    @IsNumber()
    initialWeight?: number;

    @IsOptional()
    @IsNumber()
    currentWeight?: number;

    @IsOptional()
    @IsDateString()
    weightUpdateDate?: Date;

    @IsOptional()
    @IsString()
    personalComment?: string;

    @IsOptional()
    @IsBoolean()
    isActive?: boolean;

    @IsOptional()
    @IsDateString()
    membershipStartDate?: Date;

    @IsOptional()
    @IsDateString()
    membershipExpirationDate?: Date;

    // Professor Specific
    @IsOptional()
    @IsString()
    specialty?: string;

    @IsOptional()
    @IsString()
    internalNotes?: string;

    // Admin Specific
    @IsOptional()
    @IsString()
    adminNotes?: string;

    @IsOptional()
    @IsEnum(PaymentStatus)
    paymentStatus?: PaymentStatus;

    @IsOptional()
    @IsDateString()
    lastPaymentDate?: string; // string 'YYYY-MM-DD'
}

