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
        height: number;
        trainingGoal: string;
        professorObservations: string;
        initialWeight: number;
        currentWeight: number;
        weightUpdateDate: Date;
        personalComment: string;
        isActive: boolean;
        membershipStartDate: Date;
        membershipExpirationDate: Date;
        specialty: string;
        internalNotes: string;
        adminNotes: string;
        role: import("../users/entities/user.entity").UserRole;
        paymentStatus: import("../users/entities/user.entity").PaymentStatus;
        lastPaymentDate: string;
        createdAt: Date;
        updatedAt: Date;
        studentPlans: import("../plans/entities/student-plan.entity").StudentPlan[];
        professor: import("../users/entities/user.entity").User | null;
        students: import("../users/entities/user.entity").User[];
        gym: import("../gyms/entities/gym.entity").Gym;
    }>;
    login(loginDto: LoginDto): Promise<{
        access_token: string;
        user: any;
    }>;
    getProfile(req: any): any;
}
