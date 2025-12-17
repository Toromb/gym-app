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
exports.GymScheduleController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const gym_schedule_service_1 = require("./gym-schedule.service");
const update_gym_schedule_dto_1 = require("./dto/update-gym-schedule.dto");
const passport_1 = require("@nestjs/passport");
const user_entity_1 = require("../users/entities/user.entity");
let GymScheduleController = class GymScheduleController {
    gymScheduleService;
    constructor(gymScheduleService) {
        this.gymScheduleService = gymScheduleService;
    }
    findAll() {
        return this.gymScheduleService.findAll();
    }
    update(updateGymScheduleDtos, req) {
        if (req.user.role !== user_entity_1.UserRole.ADMIN) {
            throw new common_1.ForbiddenException('Only admin can update schedule');
        }
        return this.gymScheduleService.update(updateGymScheduleDtos);
    }
};
exports.GymScheduleController = GymScheduleController;
__decorate([
    (0, common_1.Get)(),
    (0, swagger_1.ApiOperation)({ summary: 'Get gym schedule' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Return all gym schedules.' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], GymScheduleController.prototype, "findAll", null);
__decorate([
    (0, common_1.Put)(),
    (0, swagger_1.ApiOperation)({ summary: 'Update gym schedule' }),
    (0, swagger_1.ApiBody)({ type: [update_gym_schedule_dto_1.UpdateGymScheduleDto] }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'The gym schedule has been successfully updated.' }),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Array, Object]),
    __metadata("design:returntype", void 0)
], GymScheduleController.prototype, "update", null);
exports.GymScheduleController = GymScheduleController = __decorate([
    (0, swagger_1.ApiTags)('gym-schedule'),
    (0, swagger_1.ApiBearerAuth)(),
    (0, common_1.Controller)('gym-schedule'),
    (0, common_1.UseGuards)((0, passport_1.AuthGuard)('jwt')),
    __metadata("design:paramtypes", [gym_schedule_service_1.GymScheduleService])
], GymScheduleController);
//# sourceMappingURL=gym-schedule.controller.js.map