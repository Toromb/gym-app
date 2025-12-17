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
exports.GymScheduleService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const gym_schedule_entity_1 = require("./entities/gym-schedule.entity");
let GymScheduleService = class GymScheduleService {
    gymScheduleRepository;
    constructor(gymScheduleRepository) {
        this.gymScheduleRepository = gymScheduleRepository;
    }
    async onModuleInit() {
        await this.seedDefaults();
    }
    async seedDefaults() {
        const count = await this.gymScheduleRepository.count();
        if (count === 0) {
            const days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
            const defaultSchedule = days.map(day => {
                const schedule = new gym_schedule_entity_1.GymSchedule();
                schedule.dayOfWeek = day;
                schedule.isClosed = false;
                schedule.openTimeMorning = '08:00';
                schedule.closeTimeMorning = '12:00';
                schedule.openTimeAfternoon = '16:00';
                schedule.closeTimeAfternoon = '21:00';
                if (day === 'SUNDAY') {
                    schedule.isClosed = true;
                    schedule.openTimeMorning = null;
                    schedule.closeTimeMorning = null;
                    schedule.openTimeAfternoon = null;
                    schedule.closeTimeAfternoon = null;
                }
                return schedule;
            });
            await this.gymScheduleRepository.save(defaultSchedule);
        }
    }
    async findAll() {
        const daysOrder = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
        const schedules = await this.gymScheduleRepository.find();
        return schedules.sort((a, b) => {
            return daysOrder.indexOf(a.dayOfWeek) - daysOrder.indexOf(b.dayOfWeek);
        });
    }
    async update(updateGymScheduleDtos) {
        const updatedSchedules = [];
        for (const dto of updateGymScheduleDtos) {
            let schedule = await this.gymScheduleRepository.findOne({ where: { dayOfWeek: dto.dayOfWeek } });
            if (schedule) {
                if (dto.isClosed !== undefined)
                    schedule.isClosed = dto.isClosed;
                if (dto.openTimeMorning !== undefined)
                    schedule.openTimeMorning = dto.openTimeMorning || null;
                if (dto.closeTimeMorning !== undefined)
                    schedule.closeTimeMorning = dto.closeTimeMorning || null;
                if (dto.openTimeAfternoon !== undefined)
                    schedule.openTimeAfternoon = dto.openTimeAfternoon || null;
                if (dto.closeTimeAfternoon !== undefined)
                    schedule.closeTimeAfternoon = dto.closeTimeAfternoon || null;
                if (dto.notes !== undefined)
                    schedule.notes = dto.notes || null;
                updatedSchedules.push(await this.gymScheduleRepository.save(schedule));
            }
        }
        return updatedSchedules;
    }
};
exports.GymScheduleService = GymScheduleService;
exports.GymScheduleService = GymScheduleService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(gym_schedule_entity_1.GymSchedule)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], GymScheduleService);
//# sourceMappingURL=gym-schedule.service.js.map