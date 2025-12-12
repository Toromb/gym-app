import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import { CreateUserDto } from '../users/dto/create-user.dto';
export declare class AuthService {
    private usersService;
    private jwtService;
    constructor(usersService: UsersService, jwtService: JwtService);
    validateUser(email: string, pass: string): Promise<any>;
    login(user: any): Promise<{
        access_token: string;
        user: {
            id: any;
            email: any;
            role: any;
            firstName: any;
            lastName: any;
        };
    }>;
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
}
