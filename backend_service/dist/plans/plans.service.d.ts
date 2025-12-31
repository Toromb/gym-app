import { Repository } from 'typeorm';
import { Plan } from './entities/plan.entity';
import { StudentPlan } from './entities/student-plan.entity';
import { User } from '../users/entities/user.entity';
import { CreatePlanDto } from './dto/create-plan.dto';
export declare class PlansService {
    private plansRepository;
    private studentPlanRepository;
    private readonly logger;
    constructor(plansRepository: Repository<Plan>, studentPlanRepository: Repository<StudentPlan>);
    create(createPlanDto: CreatePlanDto, teacher: User): Promise<Plan>;
    findAll(gymId?: string): Promise<Plan[]>;
    findAllByTeacher(teacherId: string): Promise<Plan[]>;
    findOne(id: string): Promise<Plan | null>;
    assignPlan(planId: string, studentId: string, professorId: string): Promise<StudentPlan>;
    const saved: any;
}
