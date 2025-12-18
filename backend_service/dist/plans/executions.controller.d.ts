import { ExecutionsService } from './executions.service';
export declare class ExecutionsController {
    private readonly executionsService;
    constructor(executionsService: ExecutionsService);
    startExecution(req: any, body: {
        planId: string;
        weekNumber: number;
        dayOrder: number;
        date: string;
    }): Promise<import("./entities/plan-execution.entity").PlanExecution>;
    updateExercise(req: any, exerciseExecId: string, body: any): Promise<import("./entities/exercise-execution.entity").ExerciseExecution>;
    completeExecution(req: any, id: string, body: {
        date: string;
    }): Promise<import("./entities/plan-execution.entity").PlanExecution>;
    getCalendar(req: any, from: string, to: string): Promise<import("./entities/plan-execution.entity").PlanExecution[]>;
    getExecution(req: any, id: string): Promise<import("./entities/plan-execution.entity").PlanExecution | null>;
    getExecutionByStructure(req: any, studentId: string, planId: string, week: number, day: number, startDate?: string): Promise<import("./entities/plan-execution.entity").PlanExecution | null>;
}
