import { Repository } from 'typeorm';
import { Plan } from './entities/plan.entity';
import { StudentPlan } from './entities/student-plan.entity';
import { User } from '../users/entities/user.entity';
import { CreatePlanDto } from './dto/create-plan.dto';
import { UpdatePlanDto } from './dto/update-plan.dto';
export declare class PlansService {
    private plansRepository;
    private studentPlanRepository;
    constructor(plansRepository: Repository<Plan>, studentPlanRepository: Repository<StudentPlan>);
    create(createPlanDto: CreatePlanDto, teacher: User): Promise<Plan>;
    findAll(): Promise<Plan[]>;
    findAllByTeacher(teacherId: string): Promise<Plan[]>;
    findOne(id: string): Promise<Plan | null>;
    assignPlan(planId: string, studentId: string, professorId: string): Promise<StudentPlan>;
    update(id: string, updatePlanDto: UpdatePlanDto, user: User): Promise<Plan>;
    findStudentPlan(studentId: string): Promise<Plan | null>;
    findAllAssignmentsByStudent(studentId: string): Promise<StudentPlan[]>;
    findStudentAssignments(studentId: string): Promise<StudentPlan[]>;
    removeAssignment(assignmentId: string, user: User): Promise<void>;
    remove(id: string, user: User): Promise<void>;
    updateProgress(studentPlanId: string, userId: string, payload: {
        type: 'exercise' | 'day';
        id: string;
        completed: boolean;
        date?: string;
    }): Promise<StudentPlan>;
}
