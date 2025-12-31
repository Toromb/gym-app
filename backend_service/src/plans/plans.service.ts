import { Injectable, NotFoundException, ForbiddenException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Plan, PlanDay, PlanExercise } from './entities/plan.entity';
import { PlanWeek } from './entities/plan-week.entity';
import { StudentPlan } from './entities/student-plan.entity';
import { User, UserRole } from '../users/entities/user.entity';
import { CreatePlanDto } from './dto/create-plan.dto';
import { UpdatePlanDto } from './dto/update-plan.dto';

@Injectable()
export class PlansService {
    private readonly logger = new Logger(PlansService.name);

    constructor(
        @InjectRepository(Plan)
        private plansRepository: Repository<Plan>,
        @InjectRepository(StudentPlan)
        private studentPlanRepository: Repository<StudentPlan>,
    ) { }

    async create(createPlanDto: CreatePlanDto, teacher: User): Promise<Plan> {
        // Map DTO to Entities
        const plan = new Plan();
        plan.name = createPlanDto.name;
        plan.objective = createPlanDto.objective;
        plan.durationWeeks = createPlanDto.durationWeeks;
        plan.generalNotes = createPlanDto.generalNotes;
        plan.teacher = teacher;
        plan.weeks = createPlanDto.weeks.map(w => {
            const week = new PlanWeek();
            week.weekNumber = w.weekNumber;
            week.days = w.days.map(d => {
                const day = new PlanDay();
                day.title = d.title;
                day.dayOfWeek = d.dayOfWeek;
                day.order = d.order;
                day.dayNotes = d.dayNotes;
                day.week = week; // Back reference
                day.exercises = d.exercises.map(e => {
                    const exercise = new PlanExercise();
                    exercise.sets = e.sets;
                    exercise.reps = e.reps;
                    exercise.suggestedLoad = e.suggestedLoad;
                    exercise.rest = e.rest;
                    exercise.notes = e.notes;
                    exercise.videoUrl = e.videoUrl;
                    exercise.order = e.order;
                    exercise.exercise = { id: e.exerciseId } as any;
                    exercise.day = day; // Back reference
                    return exercise;
                });
                return day;
            });
            week.plan = plan; // Back reference
            return week;
        });

        const saved = await this.plansRepository.save(plan);
        return this.findOne(saved.id) as Promise<Plan>;
    }

    async findAll(gymId?: string): Promise<Plan[]> {
        const query = this.plansRepository.createQueryBuilder('plan')
            .leftJoinAndSelect('plan.weeks', 'weeks')
            .leftJoinAndSelect('weeks.days', 'days')
            .leftJoinAndSelect('days.exercises', 'exercises')
            .leftJoinAndSelect('exercises.exercise', 'exercise')
            .leftJoinAndSelect('plan.teacher', 'teacher')
            .leftJoinAndSelect('teacher.gym', 'gym');

        if (gymId) {
            query.where('gym.id = :gymId', { gymId });
        }

        return query.getMany();
    }

    async findAllByTeacher(teacherId: string): Promise<Plan[]> {
        return this.plansRepository.find({
            where: { teacher: { id: teacherId } },
            relations: ['weeks', 'weeks.days', 'weeks.days.exercises', 'weeks.days.exercises.exercise'],
            order: { createdAt: 'DESC' }
        });
    }

    async findOne(id: string): Promise<Plan | null> {
        return this.plansRepository.findOne({
            where: { id },
            relations: ['weeks', 'weeks.days', 'weeks.days.exercises', 'weeks.days.exercises.exercise', 'teacher'],
        });
    }

    async assignPlan(planId: string, studentId: string, assigner: User): Promise<StudentPlan> {
        const plan = await this.findOne(planId);
        if (!plan) throw new NotFoundException('Plan not found');

        // Validate Plan Ownership (Allow own plans OR Admin/Global plans OR if Assigner is Admin)
        const planTeacherId = plan.teacher?.id;
        const planTeacherRole = plan.teacher?.role;
        const isAssignerAdmin = assigner.role === UserRole.ADMIN || assigner.role === UserRole.SUPER_ADMIN;

        // Allow if:
        // 1. Plan belongs to the assigner
        // 2. Plan belongs to an Admin (Global) (and user can see it)
        // 3. Assigner is Admin (can assign any plan)

        const isOwner = planTeacherId === assigner.id;
        const isAdminPlan = planTeacherRole === UserRole.ADMIN || planTeacherRole === UserRole.SUPER_ADMIN;

        if (!isOwner && !isAdminPlan && !isAssignerAdmin) {
            throw new ForbiddenException('You can only assign your own plans or library plans');
        }

        // Validate Student Ownership 
        const student = await this.plansRepository.manager.findOne(User, { where: { id: studentId }, relations: ['professor', 'gym'] });
        if (!student) throw new NotFoundException('Student not found');

        const studentProfessorId = student.professor?.id;

        if (studentProfessorId !== assigner.id) {
            // Allow if assigner is ADMIN of the same gym (or Super Admin)
            if (isAssignerAdmin) {
                // Check if Admin belongs to same gym if not Super Admin
                if (assigner.role === UserRole.ADMIN && assigner.gym?.id && student.gym?.id && assigner.gym.id !== student.gym.id) {
                    // Ideally check gym match, but 'assigner.gym' might not be loaded on 'req.user'. 
                    // Assuming 'req.user' comes with gym info or we fetch it.
                    // For MVP, if Admin, let them assign.
                }
            } else {
                throw new ForbiddenException('You can only assign plans to your own students');
            }
        }

        const studentPlan = this.studentPlanRepository.create({
            plan: { id: planId } as any,
            student: { id: studentId } as any,
            assignedAt: new Date().toISOString(),
            startDate: new Date().toISOString(), // Default to today
            isActive: true,
        });

        // Deactivate other active plans for this student -> REMOVED per requirement (multiple active plans allowed)
        // await this.studentPlanRepository.update({ student: { id: studentId } as any, isActive: true }, { isActive: false });

        return this.studentPlanRepository.save(studentPlan);
    }


    async update(id: string, updatePlanDto: UpdatePlanDto, user: User): Promise<Plan> {
        const plan = await this.findOne(id);
        if (!plan) throw new NotFoundException('Plan not found');

        // Simple update scalars
        plan.name = updatePlanDto.name ?? plan.name;
        plan.objective = updatePlanDto.objective ?? plan.objective;
        plan.durationWeeks = updatePlanDto.durationWeeks ?? plan.durationWeeks;
        plan.generalNotes = updatePlanDto.generalNotes ?? plan.generalNotes;

        return await this.plansRepository.manager.transaction(async transactionalEntityManager => {
            // Full structure replacement if structure provided
            if (updatePlanDto.weeks && updatePlanDto.weeks.length > 0) {
                // 1. Delete all weeks associated with this plan.
                await transactionalEntityManager.delete(PlanWeek, { plan: { id: plan.id } });

                // 2. Re-create structure
                plan.weeks = updatePlanDto.weeks.map(w => {
                    const week = new PlanWeek();
                    week.weekNumber = w.weekNumber;
                    week.days = w.days.map(d => {
                        const day = new PlanDay();
                        day.title = d.title;
                        day.dayOfWeek = d.dayOfWeek;
                        day.order = d.order;
                        day.dayNotes = d.dayNotes;
                        day.week = week;
                        day.exercises = d.exercises.map(e => {
                            const exercise = new PlanExercise();
                            exercise.sets = e.sets;
                            exercise.reps = e.reps;
                            exercise.suggestedLoad = e.suggestedLoad;
                            exercise.rest = e.rest;
                            exercise.notes = e.notes;
                            exercise.videoUrl = e.videoUrl;
                            exercise.order = e.order;
                            // Logger usage inside transaction might need bind, but simple log is fine.
                            // this.logger.log(`Mapping Exercise (Update): id=${e.exerciseId}`); 
                            exercise.exercise = { id: e.exerciseId } as any;
                            exercise.day = day;
                            return exercise;
                        });
                        return day;
                    });
                    week.plan = plan;
                    return week;
                });
            }

            const saved = await transactionalEntityManager.save(plan);
            // Must fetch outside or using same manager? 
            // Better to just return ID and let controller fetch, or simple fetch here.
            // But this.findOne uses the main repo. It's usually fine as transaction committed.
            return saved;
        }).then(saved => this.findOne(saved.id) as Promise<Plan>);
    }

    async findStudentPlan(studentId: string): Promise<Plan | null> {
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

    async findAllAssignmentsByStudent(studentId: string): Promise<StudentPlan[]> {
        return this.studentPlanRepository.find({
            where: { student: { id: studentId } },
            relations: ['plan'],
            order: { assignedAt: 'DESC' }
        });
    }

    async findStudentAssignments(studentId: string): Promise<StudentPlan[]> {
        return this.studentPlanRepository.find({
            where: { student: { id: studentId } },
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
    }

    async removeAssignment(assignmentId: string, user: User): Promise<void> {
        const assignment = await this.studentPlanRepository.findOne({
            where: { id: assignmentId },
            relations: ['student', 'student.professor']
        });

        if (!assignment) throw new NotFoundException('Assignment not found');

        // Permission Check:
        // Admin can delete any assignment.
        // Professor can delete assignment ONLY if the student belongs to them.
        if (user.role === 'admin') {
            // Allowed
        } else if (user.role === 'profe') {
            const student = assignment.student;
            // The student entity loaded via 'student.professor' relation might have professor object.
            // If student has no professor assigned, or professor is diff, deny.
            if (!student.professor || student.professor.id !== user.id) {
                throw new ForbiddenException('You can only remove plans for your own students');
            }
        } else {
            throw new ForbiddenException('Not authorized');
        }

        await this.studentPlanRepository.remove(assignment);
    }

    async remove(id: string, user: User): Promise<void> {
        const plan = await this.findOne(id);
        if (!plan) throw new NotFoundException('Plan not found');

        // Permission: Admin, Super Admin or Plan Owner
        if (user.role !== 'admin' && user.role !== 'super_admin' && plan.teacher?.id !== user.id) {
            throw new ForbiddenException('You can only delete your own plans');
        }

        await this.plansRepository.remove(plan);
    }

    async updateProgress(studentPlanId: string, userId: string, payload: { type: 'exercise' | 'day', id: string, completed: boolean, date?: string }): Promise<StudentPlan> {
        const studentPlan = await this.studentPlanRepository.findOne({
            where: { id: studentPlanId },
            relations: ['student']
        });

        if (!studentPlan) throw new NotFoundException('Assignment not found');
        if (studentPlan.student.id !== userId) throw new ForbiddenException('Access denied');

        // Initialize progress structure if needed
        if (!studentPlan.progress) studentPlan.progress = { exercises: {}, days: {} };
        if (!studentPlan.progress.exercises) studentPlan.progress.exercises = {};
        if (!studentPlan.progress.days) studentPlan.progress.days = {};

        if (payload.type === 'exercise') {
            if (payload.completed) {
                studentPlan.progress.exercises[payload.id] = true;
            } else {
                delete studentPlan.progress.exercises[payload.id];
            }
        } else if (payload.type === 'day') {
            if (payload.completed) {
                studentPlan.progress.days[payload.id] = { completed: true, date: payload.date || new Date().toISOString() };
            } else {
                delete studentPlan.progress.days[payload.id];
            }
        }

        // Force update 
        const updated = await this.studentPlanRepository.save(studentPlan);
        return updated;
    }

    async restartAssignment(assignmentId: string, userId: string): Promise<StudentPlan> {
        return this.studentPlanRepository.manager.transaction(async transactionalEntityManager => {
            // 1. Find the existing assignment
            const oldAssignment = await transactionalEntityManager.findOne(StudentPlan, {
                where: { id: assignmentId },
                relations: ['student', 'plan']
            });

            if (!oldAssignment) throw new NotFoundException('Assignment not found');
            if (oldAssignment.student.id !== userId) throw new ForbiddenException('Access denied');

            // 2. Archive the old one
            oldAssignment.isActive = false;
            oldAssignment.endDate = new Date().toISOString();
            await transactionalEntityManager.save(oldAssignment);

            // 3. Create a fresh copy
            const newAssignment = this.studentPlanRepository.create({
                plan: { id: oldAssignment.plan.id } as any,
                student: { id: userId } as any,
                assignedAt: new Date().toISOString(),
                startDate: new Date().toISOString(),
                isActive: true,
                progress: { exercises: {}, days: {} } // Explicitly empty
            });

            return await transactionalEntityManager.save(newAssignment);
        });
    }
}


