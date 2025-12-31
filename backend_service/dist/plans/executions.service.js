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
exports.ExecutionsService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const plan_execution_entity_1 = require("./entities/plan-execution.entity");
const exercise_execution_entity_1 = require("./entities/exercise-execution.entity");
const plan_entity_1 = require("./entities/plan.entity");
const student_plan_entity_1 = require("./entities/student-plan.entity");
let ExecutionsService = class ExecutionsService {
    executionRepo;
    exerciseRepo;
    planRepo;
    studentPlanRepo;
    planExerciseRepo;
    constructor(executionRepo, exerciseRepo, planRepo, studentPlanRepo, planExerciseRepo) {
        this.executionRepo = executionRepo;
        this.exerciseRepo = exerciseRepo;
        this.planRepo = planRepo;
        this.studentPlanRepo = studentPlanRepo;
        this.planExerciseRepo = planExerciseRepo;
    }
    async startExecution(userId, planId, weekNumber, dayOrder, date) {
        const dayKey = `W${weekNumber}-D${dayOrder}`;
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
            const activeAssignment = await this.studentPlanRepo.findOne({
                where: {
                    student: { id: userId },
                    plan: { id: planId },
                    isActive: true
                },
                order: { assignedAt: 'DESC' }
            });
            if (activeAssignment) {
                const assignmentTimestamp = activeAssignment.createdAt;
                const executionCreated = existing.createdAt;
                console.log(`[DEBUG] Execution Freshness Check:`);
                console.log(`- Exec ID: ${existing.id} CreatedAt: ${executionCreated}`);
                console.log(`- Assign ID: ${activeAssignment.id} CreatedAt: ${assignmentTimestamp}`);
                console.log(`- Is Stale (Exec < Assign)? ${executionCreated.getTime() < assignmentTimestamp.getTime()}`);
                if (executionCreated.getTime() < assignmentTimestamp.getTime()) {
                }
                else {
                    return this._syncSnapshots(existing);
                }
            }
            else {
                return this._syncSnapshots(existing);
            }
        }
        const plan = await this.planRepo.findOne({
            where: { id: planId },
            relations: ['weeks', 'weeks.days', 'weeks.days.exercises', 'weeks.days.exercises.exercise']
        });
        if (!plan)
            throw new common_1.NotFoundException('Plan not found');
        const week = plan.weeks.find(w => w.weekNumber === weekNumber);
        if (!week)
            throw new common_1.NotFoundException(`Week ${weekNumber} not found in plan`);
        const day = week.days.find(d => d.order === dayOrder);
        if (!day)
            throw new common_1.NotFoundException(`Day ${dayOrder} not found in week ${weekNumber}`);
        const newExecution = this.executionRepo.create({
            student: { id: userId },
            plan: { id: planId },
            date: date,
            dayKey: dayKey,
            weekNumber,
            dayOrder,
            status: plan_execution_entity_1.ExecutionStatus.IN_PROGRESS,
            exercises: []
        });
        const exerciseExecutions = day.exercises.map(planEx => {
            return this.exerciseRepo.create({
                planExerciseId: planEx.id,
                exercise: planEx.exercise,
                exerciseNameSnapshot: planEx.exercise.name,
                targetSetsSnapshot: planEx.sets,
                targetRepsSnapshot: planEx.reps,
                targetWeightSnapshot: planEx.suggestedLoad,
                videoUrl: planEx.videoUrl || planEx.exercise.videoUrl,
                order: planEx.order,
                isCompleted: false
            });
        });
        newExecution.exercises = exerciseExecutions;
        return this.executionRepo.save(newExecution);
    }
    async updateExercise(exerciseId, updateData) {
        const exExecution = await this.exerciseRepo.findOne({
            where: { id: exerciseId }
        });
        if (!exExecution)
            throw new common_1.NotFoundException('Exercise execution not found');
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
        const savedEx = await this.exerciseRepo.save(exExecution);
        if (updateData.isCompleted === false) {
            const fullEx = await this.exerciseRepo.findOne({
                where: { id: exerciseId },
                relations: ['execution', 'execution.plan', 'execution.student']
            });
            if (fullEx && fullEx.execution) {
                const parentExec = fullEx.execution;
                if (parentExec.status === plan_execution_entity_1.ExecutionStatus.COMPLETED) {
                    parentExec.status = plan_execution_entity_1.ExecutionStatus.IN_PROGRESS;
                    parentExec.finishedAt = null;
                    await this.executionRepo.save(parentExec);
                    const studentPlan = await this.studentPlanRepo.findOne({
                        where: {
                            student: { id: parentExec.student.id },
                            plan: { id: parentExec.plan.id },
                            isActive: true
                        },
                        order: { createdAt: 'DESC' }
                    });
                    if (studentPlan && studentPlan.progress && studentPlan.progress.days) {
                        const planStruct = await this.planRepo.findOne({
                            where: { id: parentExec.plan.id },
                            relations: ['weeks', 'weeks.days']
                        });
                        if (planStruct) {
                            const week = planStruct.weeks.find(w => w.weekNumber === parentExec.weekNumber);
                            const day = week?.days.find(d => d.order === parentExec.dayOrder);
                            if (day && studentPlan.progress.days[day.id]) {
                                delete studentPlan.progress.days[day.id];
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
    async completeExecution(executionId, userId, finalDate) {
        const execution = await this.executionRepo.findOne({
            where: { id: executionId, student: { id: userId } },
            relations: ['plan']
        });
        if (!execution)
            throw new common_1.NotFoundException('Execution not found');
        const conflict = await this.executionRepo.findOne({
            where: {
                student: { id: userId },
                plan: { id: execution.plan.id },
                dayKey: execution.dayKey,
                date: finalDate,
                status: plan_execution_entity_1.ExecutionStatus.COMPLETED
            }
        });
        if (conflict && conflict.id !== execution.id) {
            throw new common_1.ConflictException(`Ya existe un entrenamiento guardado para el ${finalDate}. Elegí otra fecha.`);
        }
        execution.date = finalDate;
        execution.status = plan_execution_entity_1.ExecutionStatus.COMPLETED;
        execution.finishedAt = new Date();
        const saved = await this.executionRepo.save(execution);
        const studentPlan = await this.studentPlanRepo.findOne({
            where: {
                student: { id: userId },
                plan: { id: execution.plan.id },
                isActive: true
            },
            order: { createdAt: 'DESC' }
        });
        if (studentPlan) {
            const planStruct = await this.planRepo.findOne({
                where: { id: execution.plan.id },
                relations: ['weeks', 'weeks.days']
            });
            if (planStruct) {
                const week = planStruct.weeks.find(w => w.weekNumber === execution.weekNumber);
                const day = week?.days.find(d => d.order === execution.dayOrder);
                if (day) {
                    const progress = studentPlan.progress ? JSON.parse(JSON.stringify(studentPlan.progress)) : {};
                    if (!progress['days'])
                        progress['days'] = {};
                    progress['days'][day.id] = {
                        completed: true,
                        date: finalDate
                    };
                    studentPlan.progress = progress;
                    await this.studentPlanRepo.save(studentPlan);
                }
            }
        }
        return saved;
    }
    async getCalendar(userId, from, to) {
        return this.executionRepo.find({
            where: {
                student: { id: userId },
                date: (0, typeorm_2.Between)(from, to),
                status: plan_execution_entity_1.ExecutionStatus.COMPLETED
            },
            relations: ['plan', 'exercises', 'exercises.exercise'],
            order: { date: 'ASC' }
        });
    }
    async findOne(id) {
        const execution = await this.executionRepo.findOne({
            where: { id },
            relations: ['exercises', 'exercises.exercise', 'plan']
        });
        if (!execution)
            return null;
        return this._syncSnapshots(execution);
    }
    async findExecutionByStructure(userId, planId, weekNumber, dayOrder, startDate) {
        const whereClause = {
            student: { id: userId },
            plan: { id: planId },
            weekNumber: weekNumber,
            dayOrder: dayOrder
        };
        if (startDate) {
            whereClause.date = (0, typeorm_2.MoreThanOrEqual)(startDate);
        }
        const execution = await this.executionRepo.findOne({
            where: whereClause,
            order: { createdAt: 'DESC' },
            relations: ['exercises', 'exercises.exercise']
        });
        if (!execution)
            return null;
        return this._syncSnapshots(execution);
    }
    async _syncSnapshots(execution) {
        let updatesNeeded = false;
        for (const exExec of execution.exercises) {
            if (exExec.planExerciseId) {
                const planEx = await this.planExerciseRepo.findOne({
                    where: { id: exExec.planExerciseId }
                });
                if (planEx) {
                    if (!exExec.videoUrl && planEx.videoUrl) {
                        exExec.videoUrl = planEx.videoUrl;
                        updatesNeeded = true;
                    }
                    if (execution.status !== plan_execution_entity_1.ExecutionStatus.COMPLETED) {
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
            await Promise.all(execution.exercises.map(e => this.exerciseRepo.save(e)));
        }
        return execution;
    }
};
exports.ExecutionsService = ExecutionsService;
exports.ExecutionsService = ExecutionsService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(plan_execution_entity_1.PlanExecution)),
    __param(1, (0, typeorm_1.InjectRepository)(exercise_execution_entity_1.ExerciseExecution)),
    __param(2, (0, typeorm_1.InjectRepository)(plan_entity_1.Plan)),
    __param(3, (0, typeorm_1.InjectRepository)(student_plan_entity_1.StudentPlan)),
    __param(4, (0, typeorm_1.InjectRepository)(plan_entity_1.PlanExercise)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], ExecutionsService);
//# sourceMappingURL=executions.service.js.map