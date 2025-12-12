import { UserRole } from '../entities/user.entity';
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
}
