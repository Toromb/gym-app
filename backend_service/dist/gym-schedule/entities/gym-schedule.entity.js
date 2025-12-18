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
exports.GymSchedule = void 0;
const typeorm_1 = require("typeorm");
const swagger_1 = require("@nestjs/swagger");
const gym_entity_1 = require("../../gyms/entities/gym.entity");
let GymSchedule = class GymSchedule {
    id;
    dayOfWeek;
    isClosed;
    openTimeMorning;
    closeTimeMorning;
    openTimeAfternoon;
    closeTimeAfternoon;
    notes;
    gym;
};
exports.GymSchedule = GymSchedule;
__decorate([
    (0, swagger_1.ApiProperty)({ example: 1, description: 'The unique identifier of the schedule record' }),
    (0, typeorm_1.PrimaryGeneratedColumn)(),
    __metadata("design:type", Number)
], GymSchedule.prototype, "id", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'MONDAY', description: 'Day of the week' }),
    (0, typeorm_1.Column)({ type: 'varchar' }),
    __metadata("design:type", String)
], GymSchedule.prototype, "dayOfWeek", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: false, description: 'Whether the gym is closed on this day' }),
    (0, typeorm_1.Column)({ type: 'boolean', default: false }),
    __metadata("design:type", Boolean)
], GymSchedule.prototype, "isClosed", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: '08:00', description: 'Opening time for the morning shift', required: false, nullable: true }),
    (0, typeorm_1.Column)({ type: 'varchar', nullable: true }),
    __metadata("design:type", Object)
], GymSchedule.prototype, "openTimeMorning", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: '12:00', description: 'Closing time for the morning shift', required: false, nullable: true }),
    (0, typeorm_1.Column)({ type: 'varchar', nullable: true }),
    __metadata("design:type", Object)
], GymSchedule.prototype, "closeTimeMorning", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: '16:00', description: 'Opening time for the afternoon shift', required: false, nullable: true }),
    (0, typeorm_1.Column)({ type: 'varchar', nullable: true }),
    __metadata("design:type", Object)
], GymSchedule.prototype, "openTimeAfternoon", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: '21:00', description: 'Closing time for the afternoon shift', required: false, nullable: true }),
    (0, typeorm_1.Column)({ type: 'varchar', nullable: true }),
    __metadata("design:type", Object)
], GymSchedule.prototype, "closeTimeAfternoon", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'Maintenance day', description: 'Additional notes', required: false, nullable: true }),
    (0, typeorm_1.Column)({ type: 'text', nullable: true }),
    __metadata("design:type", Object)
], GymSchedule.prototype, "notes", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => gym_entity_1.Gym, { onDelete: 'CASCADE' }),
    __metadata("design:type", gym_entity_1.Gym)
], GymSchedule.prototype, "gym", void 0);
exports.GymSchedule = GymSchedule = __decorate([
    (0, typeorm_1.Entity)('gym_schedule_v2')
], GymSchedule);
//# sourceMappingURL=gym-schedule.entity.js.map