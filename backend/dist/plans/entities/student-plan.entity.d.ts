import { User } from '../../users/entities/user.entity';
import { Plan } from './plan.entity';
export declare class StudentPlan {
    id: string;
    student: User;
    plan: Plan;
    assignedAt: string;
    startDate: string;
    endDate: string;
    isActive: boolean;
    progress: any;
    createdAt: Date;
    updatedAt: Date;
}
