import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Plan, PlanDay, PlanExercise } from './entities/plan.entity';
import { PlanWeek } from './entities/plan-week.entity';
import { StudentPlan } from './entities/student-plan.entity';
import { User } from '../users/entities/user.entity';
import { CreatePlanDto } from './dto/create-plan.dto';
import { UpdatePlanDto } from './dto/update-plan.dto';

@Injectable()
export class PlansService {
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
        const where: any = {};
        if (gymId) {
            where.teacher = { gym: { id: gymId } };
        }
        return this.plansRepository.find({
            where,
            relations: ['weeks', 'weeks.days', 'weeks.days.exercises', 'weeks.days.exercises.exercise', 'teacher']
        });
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

    async assignPlan(planId: string, studentId: string, professorId: string): Promise<StudentPlan> {
        const plan = await this.findOne(planId);
        if (!plan) throw new NotFoundException('Plan not found');

        // Validate Plan Ownership (Allow own plans OR Admin/Global plans)
        const planTeacherId = plan.teacher?.id;
        const planTeacherRole = plan.teacher?.role;

        // Allow if:
        // 1. Plan belongs to the professor
        // 2. Plan belongs to an Admin (Global)
        // 3. Plan has no teacher (orphan/legacy) -> Decide policy. Let's forbid for now or allow Admin.
        // For safety/strictness: fail if not owner and not admin.

        const isOwner = planTeacherId === professorId;
        const isAdminPlan = planTeacherRole === 'admin';

        if (!isOwner && !isAdminPlan) {
            throw new ForbiddenException('You can only assign your own plans or library plans');
        }

        // Validate Student Ownership 
        const student = await this.plansRepository.manager.findOne(User, { where: { id: studentId }, relations: ['professor'] });
        if (!student) throw new NotFoundException('Student not found');

        const studentProfessorId = student.professor?.id;

        if (studentProfessorId !== professorId) {
            throw new ForbiddenException('You can only assign plans to your own students');
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

        // Full structure replacement if structure provided
        if (updatePlanDto.weeks && updatePlanDto.weeks.length > 0) {
            // Delete existing structure deeply
            // Because of cascade: true on OneToMany, removing them from the array and saving *might* work if orphanRemoval is on.
            // But TypeORM often struggles with deep orphan removal. 
            // Safer: Explicitly delete weeks (cascade deletes days/exs).

            // Actually, best way:
            // 1. Delete all weeks associated with this plan.
            await this.plansRepository.manager.delete(PlanWeek, { plan: { id: plan.id } });

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
                        console.log('Mapping Exercise (Update):', { id: e.exerciseId, video: e.videoUrl, result: exercise.videoUrl });
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

        const saved = await this.plansRepository.save(plan);
        return this.findOne(saved.id) as Promise<Plan>;
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
            order: { assignedAt: 'DESC' }
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

        // Permission: Admin or Plan Owner
        if (user.role !== 'admin' && plan.teacher.id !== user.id) {
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
}


