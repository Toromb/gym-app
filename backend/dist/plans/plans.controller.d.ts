import { PlansService } from './plans.service';
import { CreatePlanDto } from './dto/create-plan.dto';
import { UpdatePlanDto } from './dto/update-plan.dto';
export declare class PlansController {
    private readonly plansService;
    constructor(plansService: PlansService);
    create(createPlanDto: CreatePlanDto, req: any): Promise<import("./entities/plan.entity").Plan>;
    findAll(req: any): Promise<import("./entities/plan.entity").Plan[]> | never[];
    getMyPlan(req: any): Promise<import("./entities/plan.entity").Plan>;
    getMyHistory(req: any): Promise<import("./entities/student-plan.entity").StudentPlan[]>;
    findOne(id: string): Promise<import("./entities/plan.entity").Plan | null>;
    update(id: string, updatePlanDto: UpdatePlanDto, req: any): Promise<import("./entities/plan.entity").Plan>;
    assignPlan(body: {
        planId: string;
        studentId: string;
    }, req: any): Promise<import("./entities/student-plan.entity").StudentPlan>;
    getStudentAssignments(studentId: string, req: any): Promise<import("./entities/student-plan.entity").StudentPlan[]>;
    deleteAssignment(id: string, req: any): Promise<void>;
    remove(id: string, req: any): Promise<void>;
    updateProgress(body: {
        studentPlanId: string;
        type: 'exercise' | 'day';
        id: string;
        completed: boolean;
        date?: string;
    }, req: any): Promise<import("./entities/student-plan.entity").StudentPlan>;
}
