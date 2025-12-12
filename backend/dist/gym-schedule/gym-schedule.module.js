"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.GymScheduleModule = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const gym_schedule_service_1 = require("./gym-schedule.service");
const gym_schedule_controller_1 = require("./gym-schedule.controller");
const gym_schedule_entity_1 = require("./entities/gym-schedule.entity");
let GymScheduleModule = class GymScheduleModule {
};
exports.GymScheduleModule = GymScheduleModule;
exports.GymScheduleModule = GymScheduleModule = __decorate([
    (0, common_1.Module)({
        imports: [typeorm_1.TypeOrmModule.forFeature([gym_schedule_entity_1.GymSchedule])],
        controllers: [gym_schedule_controller_1.GymScheduleController],
        providers: [gym_schedule_service_1.GymScheduleService],
        exports: [gym_schedule_service_1.GymScheduleService],
    })
], GymScheduleModule);
//# sourceMappingURL=gym-schedule.module.js.map