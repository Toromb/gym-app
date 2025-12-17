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
exports.ExecutionsController = void 0;
const common_1 = require("@nestjs/common");
const executions_service_1 = require("./executions.service");
const passport_1 = require("@nestjs/passport");
const user_entity_1 = require("../users/entities/user.entity");
let ExecutionsController = class ExecutionsController {
    executionsService;
    constructor(executionsService) {
        this.executionsService = executionsService;
    }
    async startExecution(req, body) {
        if (!body.date)
            body.date = new Date().toISOString().split('T')[0];
        return this.executionsService.startExecution(req.user.id, body.planId, body.weekNumber, body.dayOrder, body.date);
    }
    async updateExercise(req, exerciseExecId, body) {
        return this.executionsService.updateExercise(exerciseExecId, body);
    }
    async completeExecution(req, id, body) {
        if (req.user.role !== user_entity_1.UserRole.ALUMNO && req.user.role !== user_entity_1.UserRole.PROFE) {
            throw new common_1.ForbiddenException('Only Student or Professor can complete executions');
        }
        if (!body.date)
            throw new common_1.BadRequestException('Date is required to complete execution');
        return this.executionsService.completeExecution(id, req.user.id, body.date);
    }
    async getCalendar(req, from, to) {
        if (!from || !to)
            throw new common_1.BadRequestException('from and to dates required');
        return this.executionsService.getCalendar(req.user.id, from, to);
    }
    async getExecution(req, id) {
        return this.executionsService.findOne(id);
    }
    async getExecutionByStructure(req, studentId, planId, week, day, startDate) {
        console.log(`[DEBUG] getExecutionByStructure: studentId=${studentId}, planId=${planId}, w=${week}, d=${day}, start=${startDate}`);
        if (req.user.role !== user_entity_1.UserRole.PROFE && req.user.role !== user_entity_1.UserRole.ADMIN && req.user.role !== user_entity_1.UserRole.SUPER_ADMIN) {
            if (req.user.id !== studentId) {
                throw new common_1.ForbiddenException('Access denied');
            }
        }
        const result = await this.executionsService.findExecutionByStructure(studentId, planId, Number(week), Number(day), startDate);
        console.log(`[DEBUG] Found execution: ${result ? result.id : 'NULL'}`);
        return result;
    }
};
exports.ExecutionsController = ExecutionsController;
__decorate([
    (0, common_1.Post)('start'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], ExecutionsController.prototype, "startExecution", null);
__decorate([
    (0, common_1.Patch)('exercises/:id'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], ExecutionsController.prototype, "updateExercise", null);
__decorate([
    (0, common_1.Patch)(':id/complete'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], ExecutionsController.prototype, "completeExecution", null);
__decorate([
    (0, common_1.Get)('calendar'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('from')),
    __param(2, (0, common_1.Query)('to')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], ExecutionsController.prototype, "getCalendar", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], ExecutionsController.prototype, "getExecution", null);
__decorate([
    (0, common_1.Get)('history/structure'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('studentId')),
    __param(2, (0, common_1.Query)('planId')),
    __param(3, (0, common_1.Query)('week')),
    __param(4, (0, common_1.Query)('day')),
    __param(5, (0, common_1.Query)('startDate')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, Number, Number, String]),
    __metadata("design:returntype", Promise)
], ExecutionsController.prototype, "getExecutionByStructure", null);
exports.ExecutionsController = ExecutionsController = __decorate([
    (0, common_1.Controller)('executions'),
    (0, common_1.UseGuards)((0, passport_1.AuthGuard)('jwt')),
    __metadata("design:paramtypes", [executions_service_1.ExecutionsService])
], ExecutionsController);
//# sourceMappingURL=executions.controller.js.map