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
exports.PlanExercise = exports.PlanDay = exports.Plan = void 0;
const typeorm_1 = require("typeorm");
const class_transformer_1 = require("class-transformer");
const user_entity_1 = require("../../users/entities/user.entity");
const exercise_entity_1 = require("../../exercises/entities/exercise.entity");
const plan_week_entity_1 = require("./plan-week.entity");
let Plan = class Plan {
    id;
    name;
    description;
    objective;
    generalNotes;
    teacher;
    startDate;
    durationWeeks;
    isTemplate;
    weeks;
    createdAt;
    updatedAt;
};
exports.Plan = Plan;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], Plan.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], Plan.prototype, "name", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Plan.prototype, "description", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Plan.prototype, "objective", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', nullable: true }),
    __metadata("design:type", String)
], Plan.prototype, "generalNotes", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => user_entity_1.User, { onDelete: 'SET NULL' }),
    __metadata("design:type", user_entity_1.User)
], Plan.prototype, "teacher", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'date', nullable: true }),
    __metadata("design:type", String)
], Plan.prototype, "startDate", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: 4 }),
    __metadata("design:type", Number)
], Plan.prototype, "durationWeeks", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: false }),
    __metadata("design:type", Boolean)
], Plan.prototype, "isTemplate", void 0);
__decorate([
    (0, typeorm_1.OneToMany)(() => plan_week_entity_1.PlanWeek, (week) => week.plan, { cascade: true }),
    __metadata("design:type", Array)
], Plan.prototype, "weeks", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], Plan.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)(),
    __metadata("design:type", Date)
], Plan.prototype, "updatedAt", void 0);
exports.Plan = Plan = __decorate([
    (0, typeorm_1.Entity)('plans')
], Plan);
let PlanDay = class PlanDay {
    id;
    week;
    title;
    dayOfWeek;
    order;
    dayNotes;
    exercises;
};
exports.PlanDay = PlanDay;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], PlanDay.prototype, "id", void 0);
__decorate([
    (0, class_transformer_1.Exclude)(),
    (0, typeorm_1.ManyToOne)(() => plan_week_entity_1.PlanWeek, (week) => week.days, { onDelete: 'CASCADE' }),
    __metadata("design:type", plan_week_entity_1.PlanWeek)
], PlanDay.prototype, "week", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], PlanDay.prototype, "title", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", Number)
], PlanDay.prototype, "dayOfWeek", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: 0 }),
    __metadata("design:type", Number)
], PlanDay.prototype, "order", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', nullable: true }),
    __metadata("design:type", String)
], PlanDay.prototype, "dayNotes", void 0);
__decorate([
    (0, typeorm_1.OneToMany)(() => PlanExercise, (exercise) => exercise.day, { cascade: true }),
    __metadata("design:type", Array)
], PlanDay.prototype, "exercises", void 0);
exports.PlanDay = PlanDay = __decorate([
    (0, typeorm_1.Entity)('plan_days')
], PlanDay);
let PlanExercise = class PlanExercise {
    id;
    day;
    exercise;
    sets;
    reps;
    suggestedLoad;
    rest;
    notes;
    videoUrl;
    order;
};
exports.PlanExercise = PlanExercise;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], PlanExercise.prototype, "id", void 0);
__decorate([
    (0, class_transformer_1.Exclude)(),
    (0, typeorm_1.ManyToOne)(() => PlanDay, (day) => day.exercises, { onDelete: 'CASCADE' }),
    __metadata("design:type", PlanDay)
], PlanExercise.prototype, "day", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => exercise_entity_1.Exercise),
    __metadata("design:type", exercise_entity_1.Exercise)
], PlanExercise.prototype, "exercise", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", Number)
], PlanExercise.prototype, "sets", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], PlanExercise.prototype, "reps", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], PlanExercise.prototype, "suggestedLoad", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], PlanExercise.prototype, "rest", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], PlanExercise.prototype, "notes", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], PlanExercise.prototype, "videoUrl", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: 0 }),
    __metadata("design:type", Number)
], PlanExercise.prototype, "order", void 0);
exports.PlanExercise = PlanExercise = __decorate([
    (0, typeorm_1.Entity)('plan_exercises')
], PlanExercise);
//# sourceMappingURL=plan.entity.js.map