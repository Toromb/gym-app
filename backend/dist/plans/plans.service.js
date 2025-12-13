"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PlansService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const plan_entity_1 = require("./entities/plan.entity");
const plan_week_entity_1 = require("./entities/plan-week.entity");
const student_plan_entity_1 = require("./entities/student-plan.entity");
const user_entity_1 = require("../users/entities/user.entity");
let PlansService = class PlansService {
    plansRepository;
    studentPlanRepository;
    constructor(plansRepository, studentPlanRepository) {
        this.plansRepository = plansRepository;
        this.studentPlanRepository = studentPlanRepository;
    }
    async create(createPlanDto, teacher) {
        const plan = new plan_entity_1.Plan();
        plan.name = createPlanDto.name;
        plan.objective = createPlanDto.objective;
        plan.durationWeeks = createPlanDto.durationWeeks;
        plan.generalNotes = createPlanDto.generalNotes;
        plan.teacher = teacher;
        plan.weeks = createPlanDto.weeks.map(w => {
            const week = new plan_week_entity_1.PlanWeek();
            week.weekNumber = w.weekNumber;
            week.days = w.days.map(d => {
                const day = new plan_entity_1.PlanDay();
                day.title = d.title;
                day.dayOfWeek = d.dayOfWeek;
                day.order = d.order;
                day.dayNotes = d.dayNotes;
                day.week = week;
                day.exercises = d.exercises.map(e => {
                    const exercise = new plan_entity_1.PlanExercise();
                    exercise.sets = e.sets;
                    exercise.reps = e.reps;
                    exercise.suggestedLoad = e.suggestedLoad;
                    exercise.rest = e.rest;
                    exercise.notes = e.notes;
                    exercise.videoUrl = e.videoUrl;
                    exercise.order = e.order;
                    exercise.exercise = { id: e.exerciseId };
                    exercise.day = day;
                    return exercise;
                });
                return day;
            });
            week.plan = plan;
            return week;
        });
        const saved = await this.plansRepository.save(plan);
        return this.findOne(saved.id);
    }
    async findAll() {
        return this.plansRepository.find({
            relations: ['weeks', 'weeks.days', 'weeks.days.exercises', 'weeks.days.exercises.exercise', 'teacher']
        });
    }
    async findAllByTeacher(teacherId) {
        return this.plansRepository.find({
            where: { teacher: { id: teacherId } },
            relations: ['weeks', 'weeks.days', 'weeks.days.exercises', 'weeks.days.exercises.exercise'],
            order: { createdAt: 'DESC' }
        });
    }
    async findOne(id) {
        return this.plansRepository.findOne({
            where: { id },
            relations: ['weeks', 'weeks.days', 'weeks.days.exercises', 'weeks.days.exercises.exercise', 'teacher'],
        });
    }
    async assignPlan(planId, studentId, professorId) {
        const plan = await this.findOne(planId);
        if (!plan)
            throw new common_1.NotFoundException('Plan not found');
        const planTeacherId = plan.teacher?.id;
        const planTeacherRole = plan.teacher?.role;
        const isOwner = planTeacherId === professorId;
        const isAdminPlan = planTeacherRole === 'admin';
        if (!isOwner && !isAdminPlan) {
            throw new common_1.ForbiddenException('You can only assign your own plans or library plans');
        }
        const student = await this.plansRepository.manager.findOne(user_entity_1.User, { where: { id: studentId }, relations: ['professor'] });
        if (!student)
            throw new common_1.NotFoundException('Student not found');
        const studentProfessorId = student.professor?.id;
        if (studentProfessorId !== professorId) {
            throw new common_1.ForbiddenException('You can only assign plans to your own students');
        }
        const studentPlan = this.studentPlanRepository.create({
            plan: { id: planId },
            student: { id: studentId },
            assignedAt: new Date().toISOString(),
            startDate: new Date().toISOString(),
            isActive: true,
        });
        return this.studentPlanRepository.save(studentPlan);
    }
    async update(id, updatePlanDto, user) {
        const plan = await this.findOne(id);
        if (!plan)
            throw new common_1.NotFoundException('Plan not found');
        plan.name = updatePlanDto.name ?? plan.name;
        plan.objective = updatePlanDto.objective ?? plan.objective;
        plan.durationWeeks = updatePlanDto.durationWeeks ?? plan.durationWeeks;
        plan.generalNotes = updatePlanDto.generalNotes ?? plan.generalNotes;
        if (updatePlanDto.weeks && updatePlanDto.weeks.length > 0) {
            await this.plansRepository.manager.delete(plan_week_entity_1.PlanWeek, { plan: { id: plan.id } });
            plan.weeks = updatePlanDto.weeks.map(w => {
                const week = new plan_week_entity_1.PlanWeek();
                week.weekNumber = w.weekNumber;
                week.days = w.days.map(d => {
                    const day = new plan_entity_1.PlanDay();
                    day.title = d.title;
                    day.dayOfWeek = d.dayOfWeek;
                    day.order = d.order;
                    day.dayNotes = d.dayNotes;
                    day.week = week;
                    day.exercises = d.exercises.map(e => {
                        const exercise = new plan_entity_1.PlanExercise();
                        exercise.sets = e.sets;
                        exercise.reps = e.reps;
                        exercise.suggestedLoad = e.suggestedLoad;
                        exercise.rest = e.rest;
                        exercise.notes = e.notes;
                        exercise.videoUrl = e.videoUrl;
                        exercise.order = e.order;
                        console.log('Mapping Exercise (Update):', { id: e.exerciseId, video: e.videoUrl, result: exercise.videoUrl });
                        exercise.exercise = { id: e.exerciseId };
                        exercise.day = day;
                        return exercise;
                    });
                    return day;
                });
                week.plan = plan;
                return week;
            });
        }
        const saved = await this.plansRepository.save(plan);
        return this.findOne(saved.id);
    }
    async findStudentPlan(studentId) {
        const studentPlan = await this.studentPlanRepository.findOne({
            where: { student: { id: studentId }, isActive: true },
            relations: ['plan', 'plan.weeks', 'plan.weeks.days', 'plan.weeks.days.exercises', 'plan.weeks.days.exercises.exercise'],
            order: {
                assignedAt: 'DESC',
                plan: {
                    weeks: {
                        weekNumber: 'ASC',
                        days: {
                            order: 'ASC',
                            exercises: {
                                order: 'ASC'
                            }
                        }
                    }
                }
            }
        });
        return studentPlan ? studentPlan.plan : null;
    }
    async findAllAssignmentsByStudent(studentId) {
        return this.studentPlanRepository.find({
            where: { student: { id: studentId } },
            relations: ['plan'],
            order: { assignedAt: 'DESC' }
        });
    }
    async findStudentAssignments(studentId) {
        return this.studentPlanRepository.find({
            where: { student: { id: studentId } },
            relations: ['plan', 'plan.weeks', 'plan.weeks.days', 'plan.weeks.days.exercises', 'plan.weeks.days.exercises.exercise'],
            order: { assignedAt: 'DESC' }
        });
    }
    async removeAssignment(assignmentId, user) {
        const assignment = await this.studentPlanRepository.findOne({
            where: { id: assignmentId },
            relations: ['student', 'student.professor']
        });
        if (!assignment)
            throw new common_1.NotFoundException('Assignment not found');
        if (user.role === 'admin') {
        }
        else if (user.role === 'profe') {
            const student = assignment.student;
            if (!student.professor || student.professor.id !== user.id) {
                throw new common_1.ForbiddenException('You can only remove plans for your own students');
            }
        }
        else {
            throw new common_1.ForbiddenException('Not authorized');
        }
        await this.studentPlanRepository.remove(assignment);
    }
    async remove(id, user) {
        const plan = await this.findOne(id);
        if (!plan)
            throw new common_1.NotFoundException('Plan not found');
        if (user.role !== 'admin' && plan.teacher.id !== user.id) {
            throw new common_1.ForbiddenException('You can only delete your own plans');
        }
        await this.plansRepository.remove(plan);
    }
};
exports.PlansService = PlansService;
exports.PlansService = PlansService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(plan_entity_1.Plan)),
    __param(1, (0, typeorm_1.InjectRepository)(student_plan_entity_1.StudentPlan)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository])
], PlansService);
//# sourceMappingURL=plans.service.js.map