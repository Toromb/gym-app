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
exports.PlansController = void 0;
const common_1 = require("@nestjs/common");
const plans_service_1 = require("./plans.service");
const passport_1 = require("@nestjs/passport");
const create_plan_dto_1 = require("./dto/create-plan.dto");
const user_entity_1 = require("../users/entities/user.entity");
let PlansController = class PlansController {
    plansService;
    constructor(plansService) {
        this.plansService = plansService;
    }
    create(createPlanDto, req) {
        if (req.user.role === user_entity_1.UserRole.ALUMNO) {
            throw new common_1.ForbiddenException('Only teachers and admins can create plans');
        }
        return this.plansService.create(createPlanDto, req.user);
    }
    findAll(req) {
        if (req.user.role === user_entity_1.UserRole.SUPER_ADMIN) {
            return this.plansService.findAll();
        }
        if (req.user.role === user_entity_1.UserRole.PROFE || req.user.role === user_entity_1.UserRole.ADMIN) {
            const gymId = req.user.gym?.id;
            if (!gymId) {
                return [];
            }
            return this.plansService.findAll(gymId);
        }
        return [];
    }
    async getMyPlan(req) {
        const plan = await this.plansService.findStudentPlan(req.user.id);
        if (!plan) {
            throw new common_1.NotFoundException('No active plan found');
        }
        return plan;
    }
    async getMyHistory(req) {
        return this.plansService.findStudentAssignments(req.user.id);
    }
    findOne(id) {
        return this.plansService.findOne(id);
    }
    assignPlan(body, req) {
        if (req.user.role !== user_entity_1.UserRole.PROFE && req.user.role !== user_entity_1.UserRole.ADMIN) {
            throw new common_1.ForbiddenException('Only professors and admins can assign plans');
        }
        return this.plansService.assignPlan(body.planId, body.studentId, req.user);
    }
    console;
    log(, JSON, stringify) { }
};
exports.PlansController = PlansController;
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_plan_dto_1.CreatePlanDto, Object]),
    __metadata("design:returntype", void 0)
], PlansController.prototype, "create", null);
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], PlansController.prototype, "findAll", null);
__decorate([
    (0, common_1.Get)('student/my-plan'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], PlansController.prototype, "getMyPlan", null);
__decorate([
    (0, common_1.Get)('student/history'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], PlansController.prototype, "getMyHistory", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], PlansController.prototype, "findOne", null);
__decorate([
    (0, common_1.Post)('assign'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", void 0)
], PlansController.prototype, "assignPlan", null);
exports.PlansController = PlansController = __decorate([
    (0, common_1.Controller)('plans'),
    (0, common_1.UseGuards)((0, passport_1.AuthGuard)('jwt')),
    (0, common_1.UseInterceptors)(common_1.ClassSerializerInterceptor),
    __metadata("design:paramtypes", [plans_service_1.PlansService])
], PlansController);
(updatePlanDto, null, 2);
;
return this.plansService.update(id, updatePlanDto, req.user);
assignPlan(, body, { planId: string, studentId: string }, , req, any);
{
    if (req.user.role !== user_entity_1.UserRole.PROFE && req.user.role !== user_entity_1.UserRole.ADMIN) {
        throw new common_1.ForbiddenException('Only professors and admins can assign plans');
    }
    return this.plansService.assignPlan(body.planId, body.studentId, req.user.id);
}
getStudentAssignments(, studentId, string, , req, any);
{
    if (req.user.role !== user_entity_1.UserRole.PROFE && req.user.role !== user_entity_1.UserRole.ADMIN) {
        throw new common_1.ForbiddenException('Access denied');
    }
    return this.plansService.findAllAssignmentsByStudent(studentId);
}
deleteAssignment(, id, string, , req, any);
{
    return this.plansService.removeAssignment(id, req.user);
}
remove(, id, string, , req, any);
{
    return this.plansService.remove(id, req.user);
}
updateProgress(, body, {
    studentPlanId: string,
    type: 'exercise' | 'day',
    id: string,
    completed: boolean,
    date: string
}, , req, any);
{
    return this.plansService.updateProgress(body.studentPlanId, req.user.id, body);
}
restartAssignment(, assignmentId, string, , req, any);
{
    return this.plansService.restartAssignment(assignmentId, req.user.id);
}
//# sourceMappingURL=plans.controller.js.map