import { UserRole, PaymentStatus } from '../entities/user.entity';
export declare class CreateUserDto {
    firstName: string;
    lastName: string;
    email: string;
    password?: string;
    phone?: string;
    age?: number;
    gender?: string;
    notes?: string;
    role?: UserRole;
    height?: number;
    trainingGoal?: string;
    professorObservations?: string;
    initialWeight?: number;
    currentWeight?: number;
    weightUpdateDate?: Date;
    personalComment?: string;
    isActive?: boolean;
    membershipStartDate?: Date;
    membershipExpirationDate?: Date;
    specialty?: string;
    internalNotes?: string;
    adminNotes?: string;
    paymentStatus?: PaymentStatus;
    lastPaymentDate?: string;
    gymId?: string;
    professorId?: string;
}
