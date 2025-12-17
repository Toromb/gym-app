import { StudentPlan } from '../../plans/entities/student-plan.entity';
import { Gym } from '../../gyms/entities/gym.entity';
export declare enum UserRole {
    ADMIN = "admin",
    PROFE = "profe",
    ALUMNO = "alumno",
    SUPER_ADMIN = "super_admin"
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
    role: UserRole;
    paymentStatus: PaymentStatus;
    lastPaymentDate: string;
    createdAt: Date;
    updatedAt: Date;
    studentPlans: StudentPlan[];
    professor: User | null;
    students: User[];
    gym: Gym;
}
