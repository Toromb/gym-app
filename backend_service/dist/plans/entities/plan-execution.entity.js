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
exports.PlanExecution = exports.ExecutionStatus = void 0;
const typeorm_1 = require("typeorm");
const user_entity_1 = require("../../users/entities/user.entity");
const plan_entity_1 = require("./plan.entity");
const exercise_execution_entity_1 = require("./exercise-execution.entity");
var ExecutionStatus;
(function (ExecutionStatus) {
    ExecutionStatus["IN_PROGRESS"] = "IN_PROGRESS";
    ExecutionStatus["COMPLETED"] = "COMPLETED";
})(ExecutionStatus || (exports.ExecutionStatus = ExecutionStatus = {}));
let PlanExecution = class PlanExecution {
    id;
    student;
    plan;
    date;
    dayKey;
    weekNumber;
    dayOrder;
    status;
    finishedAt;
    details;
    exercises;
    createdAt;
    updatedAt;
};
exports.PlanExecution = PlanExecution;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], PlanExecution.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => user_entity_1.User, { onDelete: 'CASCADE' }),
    __metadata("design:type", user_entity_1.User)
], PlanExecution.prototype, "student", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => plan_entity_1.Plan, { onDelete: 'CASCADE' }),
    __metadata("design:type", plan_entity_1.Plan)
], PlanExecution.prototype, "plan", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'date' }),
    __metadata("design:type", String)
], PlanExecution.prototype, "date", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], PlanExecution.prototype, "dayKey", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", Number)
], PlanExecution.prototype, "weekNumber", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", Number)
], PlanExecution.prototype, "dayOrder", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: ExecutionStatus,
        default: ExecutionStatus.IN_PROGRESS
    }),
    __metadata("design:type", String)
], PlanExecution.prototype, "status", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'timestamp', nullable: true }),
    __metadata("design:type", Object)
], PlanExecution.prototype, "finishedAt", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'json', nullable: true }),
    __metadata("design:type", Object)
], PlanExecution.prototype, "details", void 0);
__decorate([
    (0, typeorm_1.OneToMany)(() => exercise_execution_entity_1.ExerciseExecution, (ex) => ex.execution, { cascade: true }),
    __metadata("design:type", Array)
], PlanExecution.prototype, "exercises", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], PlanExecution.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)(),
    __metadata("design:type", Date)
], PlanExecution.prototype, "updatedAt", void 0);
exports.PlanExecution = PlanExecution = __decorate([
    (0, typeorm_1.Entity)('plan_executions')
], PlanExecution);
//# sourceMappingURL=plan-execution.entity.js.map