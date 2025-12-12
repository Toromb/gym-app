import { AuthService } from './auth.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { LoginDto } from './dto/login.dto';
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
    register(createUserDto: CreateUserDto): Promise<{
        id: string;
        firstName: string;
        lastName: string;
        email: string;
        phone: string;
        age: number;
        gender: string;
        notes: string;
        role: import("../users/entities/user.entity").UserRole;
        paymentStatus: import("../users/entities/user.entity").PaymentStatus;
        lastPaymentDate: string;
        createdAt: Date;
        updatedAt: Date;
        studentPlans: import("../plans/entities/student-plan.entity").StudentPlan[];
        professor: import("../users/entities/user.entity").User;
        students: import("../users/entities/user.entity").User[];
    }>;
    login(loginDto: LoginDto): Promise<{
        access_token: string;
        user: {
            id: any;
            email: any;
            role: any;
            firstName: any;
            lastName: any;
        };
    }>;
    getProfile(req: any): any;
}
