import { Plan, PlanDay } from './plan.entity';
export declare class PlanWeek {
    id: string;
    plan: Plan;
    weekNumber: number;
    days: PlanDay[];
}
