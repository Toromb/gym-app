import { User } from '../../users/entities/user.entity';
import { Plan } from './plan.entity';
import { ExerciseExecution } from './exercise-execution.entity';
export declare enum ExecutionStatus {
    IN_PROGRESS = "IN_PROGRESS",
    COMPLETED = "COMPLETED"
}
export declare class PlanExecution {
    id: string;
    student: User;
    plan: Plan;
    date: string;
    dayKey: string;
    weekNumber: number;
    dayOrder: number;
    status: ExecutionStatus;
    finishedAt: Date | null;
    details: any;
    exercises: ExerciseExecution[];
    createdAt: Date;
    updatedAt: Date;
}
