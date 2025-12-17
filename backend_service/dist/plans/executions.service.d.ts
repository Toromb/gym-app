import { Repository } from 'typeorm';
import { PlanExecution } from './entities/plan-execution.entity';
import { ExerciseExecution } from './entities/exercise-execution.entity';
import { Plan, PlanExercise } from './entities/plan.entity';
import { StudentPlan } from './entities/student-plan.entity';
export declare class ExecutionsService {
    private executionRepo;
    private exerciseRepo;
    private planRepo;
    private studentPlanRepo;
    private planExerciseRepo;
    constructor(executionRepo: Repository<PlanExecution>, exerciseRepo: Repository<ExerciseExecution>, planRepo: Repository<Plan>, studentPlanRepo: Repository<StudentPlan>, planExerciseRepo: Repository<PlanExercise>);
    startExecution(userId: string, planId: string, weekNumber: number, dayOrder: number, date: string): Promise<PlanExecution>;
    updateExercise(exerciseId: string, updateData: Partial<ExerciseExecution>): Promise<ExerciseExecution>;
    completeExecution(executionId: string, userId: string, finalDate: string): Promise<PlanExecution>;
    getCalendar(userId: string, from: string, to: string): Promise<PlanExecution[]>;
    findOne(id: string): Promise<PlanExecution | null>;
    findExecutionByStructure(userId: string, planId: string, weekNumber: number, dayOrder: number, startDate?: string): Promise<PlanExecution | null>;
    private _syncVideoUrls;
}
