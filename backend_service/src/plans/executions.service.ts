import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, MoreThanOrEqual } from 'typeorm';
import { PlanExecution, ExecutionStatus } from './entities/plan-execution.entity';
import { ExerciseExecution } from './entities/exercise-execution.entity';
import { Plan, PlanExercise } from './entities/plan.entity';
import { User } from '../users/entities/user.entity';
import { StudentPlan } from './entities/student-plan.entity';

@Injectable()
export class ExecutionsService {
    constructor(
        @InjectRepository(PlanExecution)
        private executionRepo: Repository<PlanExecution>,
        @InjectRepository(ExerciseExecution)
        private exerciseRepo: Repository<ExerciseExecution>,
        @InjectRepository(Plan)
        private planRepo: Repository<Plan>,
        @InjectRepository(StudentPlan)
        private studentPlanRepo: Repository<StudentPlan>,
        @InjectRepository(PlanExercise)
        private planExerciseRepo: Repository<PlanExercise>,
    ) { }

    // 1. Start or Resume Execution
    async startExecution(
        userId: string,
        planId: string,
        weekNumber: number,
        dayOrder: number,
        date: string // YYYY-MM-DD
    ): Promise<PlanExecution> {
        // Construct Day Key
        const dayKey = `W${weekNumber}-D${dayOrder}`;

        // Check if execution exists for this date + dayKey
        const existing = await this.executionRepo.findOne({
            where: {
                student: { id: userId },
                plan: { id: planId },
                date: date,
                dayKey: dayKey
            },
            order: { createdAt: 'DESC' },
            relations: ['exercises', 'exercises.exercise']
        });

        if (existing) {
            // Check if this execution belongs to the CURRENT active assignment or an old one.
            // If the user restarted the plan TODAY, the 'existing' execution might be from the previous run (earlier today).

            // 1. Get the current active assignment
            const activeAssignment = await this.studentPlanRepo.findOne({
                where: {
                    student: { id: userId },
                    plan: { id: planId },
                    isActive: true
                },
                order: { assignedAt: 'DESC' } // Newest active
            });

            if (activeAssignment) {
                // Use createdAt because assignedAt is only DATE type (no time), which causes issues 
                // if execution and assignment happen on the same day.
                const assignmentTimestamp = activeAssignment.createdAt;
                const executionCreated = existing.createdAt;

                console.log(`[DEBUG] Execution Freshness Check:`);
                console.log(`- Exec ID: ${existing.id} CreatedAt: ${executionCreated}`);
                console.log(`- Assign ID: ${activeAssignment.id} CreatedAt: ${assignmentTimestamp}`);
                console.log(`- Is Stale (Exec < Assign)? ${executionCreated.getTime() < assignmentTimestamp.getTime()}`);

                // Tolerance: If execution was created BEFORE the assignment was assigned

                // If existing.createdAt < activeAssignment.createdAt
                if (executionCreated.getTime() < assignmentTimestamp.getTime()) {
                    // It's STALE. We need a NEW execution for today.
                    // Proceed to create (fall through)
                } else {
                    // It's valid for current cycle.
                    return this._syncSnapshots(existing);
                }
            } else {
                // No active assignment? Odd, but just return existing or sync.
                return this._syncSnapshots(existing);
            }
        }

        // Create New
        const plan = await this.planRepo.findOne({
            where: { id: planId },
            relations: ['weeks', 'weeks.days', 'weeks.days.exercises', 'weeks.days.exercises.exercise']
        });
        if (!plan) throw new NotFoundException('Plan not found');

        // Find the specific day in the plan structure to populate snapshots
        const week = plan.weeks.find(w => w.weekNumber === weekNumber);
        if (!week) throw new NotFoundException(`Week ${weekNumber} not found in plan`);

        const day = week.days.find(d => d.order === dayOrder);
        if (!day) throw new NotFoundException(`Day ${dayOrder} not found in week ${weekNumber}`);

        const newExecution = this.executionRepo.create({
            student: { id: userId } as User,
            plan: { id: planId } as Plan,
            date: date,
            dayKey: dayKey,
            weekNumber,
            dayOrder,
            status: ExecutionStatus.IN_PROGRESS,
            exercises: []
        });

        // Create ExerciseExecutions with Snapshots
        const exerciseExecutions: ExerciseExecution[] = day.exercises.map(planEx => {
            return this.exerciseRepo.create({
                planExerciseId: planEx.id,
                exercise: planEx.exercise,
                // SNAPSHOTS
                exerciseNameSnapshot: planEx.exercise.name,
                targetSetsSnapshot: planEx.sets,
                targetRepsSnapshot: planEx.reps,
                targetWeightSnapshot: planEx.suggestedLoad,
                videoUrl: planEx.videoUrl || planEx.exercise.videoUrl,
                // DEFAULTS
                order: planEx.order,
                isCompleted: false
            });
        });

        newExecution.exercises = exerciseExecutions;
        return this.executionRepo.save(newExecution);
    }

    // 2. Update Exercise Execution
    async updateExercise(
        exerciseId: string,
        updateData: Partial<ExerciseExecution>
    ): Promise<ExerciseExecution> {
        // Verify ownership indirectly via execution lookup if needed, but for MVP direct ID update
        // We can check execution.studentId if we passed userId context.
        const exExecution = await this.exerciseRepo.findOne({
            where: { id: exerciseId }
        });

        if (!exExecution) throw new NotFoundException('Exercise execution not found');

        // Auto-fill actuals from targets if completing and not provided
        if (updateData.isCompleted === true) {
            if (!exExecution.setsDone || exExecution.setsDone === '0') {
                exExecution.setsDone = (exExecution.targetSetsSnapshot ?? 0).toString();
            }
            if (!exExecution.repsDone) {
                exExecution.repsDone = exExecution.targetRepsSnapshot ?? '';
            }
            if (!exExecution.weightUsed) {
                exExecution.weightUsed = exExecution.targetWeightSnapshot ?? '';
            }
        }

        Object.assign(exExecution, updateData);
        // Note: Object.assign overwrites, so if updateData has explicit nulls/zeros it fits.

        const savedEx = await this.exerciseRepo.save(exExecution);

        // --- NEW LOGIC: If unchecking, ensure Day is also "Uncompleted" ---
        if (updateData.isCompleted === false) {
            // 1. Fetch Parent Execution
            // Safer: Fetch via relation directly
            const fullEx = await this.exerciseRepo.findOne({
                where: { id: exerciseId },
                relations: ['execution', 'execution.plan', 'execution.student']
            });

            if (fullEx && fullEx.execution) {
                const parentExec = fullEx.execution;

                // 2. Downgrade Status
                if (parentExec.status === ExecutionStatus.COMPLETED) {
                    parentExec.status = ExecutionStatus.IN_PROGRESS;
                    parentExec.finishedAt = null;
                    await this.executionRepo.save(parentExec);

                    // 3. Sync StudentPlan (Remove Day Checkmark)
                    const studentPlan = await this.studentPlanRepo.findOne({
                        where: {
                            student: { id: parentExec.student.id },
                            plan: { id: parentExec.plan.id },
                            isActive: true
                        },
                        order: { createdAt: 'DESC' }
                    });

                    if (studentPlan && studentPlan.progress && studentPlan.progress.days) {
                        // Find Day ID
                        const planStruct = await this.planRepo.findOne({
                            where: { id: parentExec.plan.id },
                            relations: ['weeks', 'weeks.days']
                        });

                        if (planStruct) {
                            const week = planStruct.weeks.find(w => w.weekNumber === parentExec.weekNumber);
                            const day = week?.days.find(d => d.order === parentExec.dayOrder);

                            if (day && studentPlan.progress.days[day.id]) {
                                // REMOVE IT
                                delete studentPlan.progress.days[day.id];
                                // We must clone/reassign to trigger TypeORM JSON update?
                                // Usually explicitly assigning distinct object works best.
                                const newProgress = JSON.parse(JSON.stringify(studentPlan.progress));
                                delete newProgress.days[day.id];
                                studentPlan.progress = newProgress;

                                await this.studentPlanRepo.save(studentPlan);
                            }
                        }
                    }
                }
            }
        }

        return savedEx;
    }

    // 3. Complete Execution (with Date Conflict Check)
    async completeExecution(
        executionId: string,
        userId: string,
        finalDate: string
    ): Promise<PlanExecution> {
        const execution = await this.executionRepo.findOne({
            where: { id: executionId, student: { id: userId } },
            relations: ['plan']
        });
        if (!execution) throw new NotFoundException('Execution not found');

        // If date is different OR we just want to ensure uniqueness on completion
        // Check if there is ALREADY a COMPLETED execution for this (User + Plan + DayKey + Date)
        // EXCLUDING the current one (in case we are just re-saving same day)

        const conflict = await this.executionRepo.findOne({
            where: {
                student: { id: userId },
                plan: { id: execution.plan.id },
                dayKey: execution.dayKey,
                date: finalDate,
                status: ExecutionStatus.COMPLETED
            }
        });

        if (conflict && conflict.id !== execution.id) {
            throw new ConflictException(
                `Ya existe un entrenamiento guardado para el ${finalDate}. Elegí otra fecha.`
            );
        }

        execution.date = finalDate;
        execution.status = ExecutionStatus.COMPLETED;
        execution.finishedAt = new Date();

        const saved = await this.executionRepo.save(execution);

        // --- LEGACY SYNC ---
        // Find active student plan and update 'progress' JSON so older views (PlanDetailsScreen) match.
        const studentPlan = await this.studentPlanRepo.findOne({
            where: {
                student: { id: userId },
                plan: { id: execution.plan.id },
                isActive: true
            },
            order: { createdAt: 'DESC' }
        });

        if (studentPlan) {
            // Re-fetch plan structure to find Day ID
            const planStruct = await this.planRepo.findOne({
                where: { id: execution.plan.id },
                relations: ['weeks', 'weeks.days']
            });

            if (planStruct) {
                const week = planStruct.weeks.find(w => w.weekNumber === execution.weekNumber);
                const day = week?.days.find(d => d.order === execution.dayOrder);

                if (day) {
                    // Update JSON safe - Deep Clone to ensure TypeORM detects change
                    const progress = studentPlan.progress ? JSON.parse(JSON.stringify(studentPlan.progress)) : {};
                    if (!progress['days']) progress['days'] = {};

                    // Only update if not already there or force overwrite
                    progress['days'][day.id] = {
                        completed: true,
                        date: finalDate
                    };

                    studentPlan.progress = progress;
                    await this.studentPlanRepo.save(studentPlan);
                }
            }
        }
        // --- END LEGACY SYNC ---

        return saved;
    }

    // 4. Get Calendar
    async getCalendar(userId: string, from: string, to: string): Promise<PlanExecution[]> {
        return this.executionRepo.find({
            where: {
                student: { id: userId },
                date: Between(from, to),
                status: ExecutionStatus.COMPLETED // Only show finished? MVP Requirements said "entrenó".
                // If we also want IN_PROGRESS, remove this filter.
                // Addendum: "Un día se marca como “entrenó” si hay al menos 1 PlanExecution COMPLETED"
            },
            relations: ['plan', 'exercises', 'exercises.exercise'], // Included exercises so frontend can parse
            order: { date: 'ASC' }
        });
    }

    async findOne(id: string): Promise<PlanExecution | null> {
        const execution = await this.executionRepo.findOne({
            where: { id },
            relations: ['exercises', 'exercises.exercise', 'plan']
        });

        if (!execution) return null;
        return this._syncSnapshots(execution);
    }

    async findExecutionByStructure(
        userId: string,
        planId: string,
        weekNumber: number,
        dayOrder: number,
        startDate?: string
    ): Promise<PlanExecution | null> {
        const whereClause: any = {
            student: { id: userId },
            plan: { id: planId },
            weekNumber: weekNumber,
            dayOrder: dayOrder
        };

        if (startDate) {
            // Filter: Execution date must be >= startDate
            whereClause.date = MoreThanOrEqual(startDate);
        }

        const execution = await this.executionRepo.findOne({
            where: whereClause,
            order: { createdAt: 'DESC' }, // Get latest if multiple exist (re-do)
            relations: ['exercises', 'exercises.exercise']
        });

        if (!execution) return null;
        return this._syncSnapshots(execution);
    }

    private async _syncSnapshots(execution: PlanExecution): Promise<PlanExecution> {
        // "Heal" / Sync missing video URLs AND update snapshots if execution is clean (not started)
        let updatesNeeded = false;

        for (const exExec of execution.exercises) {
            if (exExec.planExerciseId) {
                const planEx = await this.planExerciseRepo.findOne({
                    where: { id: exExec.planExerciseId }
                });

                if (planEx) {
                    // 1. Sync Video
                    if (!exExec.videoUrl && planEx.videoUrl) {
                        exExec.videoUrl = planEx.videoUrl;
                        updatesNeeded = true;
                    }

                    // 2. Sync Snapshots (Target Values)
                    // New Rule: Always sync snapshots if execution is NOT COMPLETED.
                    // This ensures active workouts always reflect the latest plan instructions.
                    // History is preserved only after completion.

                    if (execution.status !== ExecutionStatus.COMPLETED) {
                        // Check for drifts and update
                        if (exExec.targetSetsSnapshot !== planEx.sets ||
                            exExec.targetRepsSnapshot !== planEx.reps ||
                            exExec.targetWeightSnapshot !== planEx.suggestedLoad) {

                            console.log(`[SyncSnapshots] UPDATING SNAPSHOTS for ${exExec.id} (Status: ${execution.status})`);
                            exExec.targetSetsSnapshot = planEx.sets;
                            exExec.targetRepsSnapshot = planEx.reps;
                            exExec.targetWeightSnapshot = planEx.suggestedLoad;

                            updatesNeeded = true;
                        }
                    }
                }
            }
        }

        if (updatesNeeded) {
            // Return re-fetched to ensure clean state or save individually?
            // Since we modified objects in the array, saving them individually is fine.
            // But we need to await all saves.
            await Promise.all(execution.exercises.map(e => this.exerciseRepo.save(e)));
        }

        return execution;
    }
}
