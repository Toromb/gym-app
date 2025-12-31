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
Object.defineProperty(exports, "__esModule", { value: true });
exports.ExerciseExecution = void 0;
const typeorm_1 = require("typeorm");
const plan_execution_entity_1 = require("./plan-execution.entity");
const exercise_entity_1 = require("../../exercises/entities/exercise.entity");
let ExerciseExecution = class ExerciseExecution {
    id;
    execution;
    planExerciseId;
    exercise;
    exerciseNameSnapshot;
    targetSetsSnapshot;
    targetRepsSnapshot;
    targetWeightSnapshot;
    videoUrl;
    isCompleted;
    setsDone;
    repsDone;
    weightUsed;
    timeSpent;
    notes;
    order;
};
exports.ExerciseExecution = ExerciseExecution;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], ExerciseExecution.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => plan_execution_entity_1.PlanExecution, (execution) => execution.exercises, { onDelete: 'CASCADE' }),
    __metadata("design:type", plan_execution_entity_1.PlanExecution)
], ExerciseExecution.prototype, "execution", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], ExerciseExecution.prototype, "planExerciseId", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => exercise_entity_1.Exercise, { eager: true }),
    __metadata("design:type", exercise_entity_1.Exercise)
], ExerciseExecution.prototype, "exercise", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], ExerciseExecution.prototype, "exerciseNameSnapshot", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", Number)
], ExerciseExecution.prototype, "targetSetsSnapshot", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], ExerciseExecution.prototype, "targetRepsSnapshot", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], ExerciseExecution.prototype, "targetWeightSnapshot", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], ExerciseExecution.prototype, "videoUrl", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: false }),
    __metadata("design:type", Boolean)
], ExerciseExecution.prototype, "isCompleted", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], ExerciseExecution.prototype, "setsDone", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], ExerciseExecution.prototype, "repsDone", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], ExerciseExecution.prototype, "weightUsed", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], ExerciseExecution.prototype, "timeSpent", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', nullable: true }),
    __metadata("design:type", String)
], ExerciseExecution.prototype, "notes", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: 0 }),
    __metadata("design:type", Number)
], ExerciseExecution.prototype, "order", void 0);
exports.ExerciseExecution = ExerciseExecution = __decorate([
    (0, typeorm_1.Entity)('exercise_executions')
], ExerciseExecution);
//# sourceMappingURL=exercise-execution.entity.js.map