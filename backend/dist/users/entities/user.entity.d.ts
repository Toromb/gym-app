import { StudentPlan } from '../../plans/entities/student-plan.entity';
export declare enum UserRole {
    ADMIN = "admin",
    PROFE = "profe",
    ALUMNO = "alumno"
}
export declare enum PaymentStatus {
    PENDING = "pending",
    PAID = "paid",
    OVERDUE = "overdue"
}
export declare class User {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
    passwordHash: string;
    phone: string;
    age: number;
    gender: string;
    notes: string;
    role: UserRole;
    paymentStatus: PaymentStatus;
    lastPaymentDate: string;
    createdAt: Date;
    updatedAt: Date;
    studentPlans: StudentPlan[];
    professor: User;
    students: User[];
}
