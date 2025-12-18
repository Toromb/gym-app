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
exports.StatsController = void 0;
const common_1 = require("@nestjs/common");
const passport_1 = require("@nestjs/passport");
const users_service_1 = require("../users/users.service");
const gyms_service_1 = require("../gyms/gyms.service");
const user_entity_1 = require("../users/entities/user.entity");
let StatsController = class StatsController {
    usersService;
    gymsService;
    constructor(usersService, gymsService) {
        this.usersService = usersService;
        this.gymsService = gymsService;
    }
    async getPlatformStats(req) {
        const user = req.user;
        if (user.role !== user_entity_1.UserRole.SUPER_ADMIN) {
            throw new common_1.ForbiddenException('Only Super Admin can access platform stats');
        }
        const stats = {
            totalGyms: await this.gymsService.countAll(),
            activeGyms: await this.gymsService.countActive(),
            totalUsers: await this.usersService.countAll(),
        };
        return stats;
    }
};
exports.StatsController = StatsController;
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], StatsController.prototype, "getPlatformStats", null);
exports.StatsController = StatsController = __decorate([
    (0, common_1.Controller)('stats'),
    (0, common_1.UseGuards)((0, passport_1.AuthGuard)('jwt')),
    __metadata("design:paramtypes", [users_service_1.UsersService,
        gyms_service_1.GymsService])
], StatsController);
//# sourceMappingURL=stats.controller.js.map