import { PlansService } from './plans.service';
import { CreatePlanDto } from './dto/create-plan.dto';
export declare class PlansController {
    private readonly plansService;
    constructor(plansService: PlansService);
    create(createPlanDto: CreatePlanDto, req: any): Promise<import("./entities/plan.entity").Plan>;
    findAll(req: any): never[] | Promise<import("./entities/plan.entity").Plan[]>;
    getMyPlan(req: any): Promise<any>;
    getMyHistory(req: any): Promise<any>;
    findOne(id: string): Promise<import("./entities/plan.entity").Plan | null>;
    assignPlan(body: {
        planId: string;
        studentId: string;
    }, req: any): Promise<import("./entities/student-plan.entity").StudentPlan>;
    console: any;
    log(: any, JSON: any, stringify: any): any;
}
