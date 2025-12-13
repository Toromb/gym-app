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
const update_plan_dto_1 = require("./dto/update-plan.dto");
let PlansController = class PlansController {
    plansService;
    constructor(plansService) {
        this.plansService = plansService;
    }
    create(createPlanDto, req) {
        if (req.user.role === user_entity_1.UserRole.ALUMNO) {
        }
        return this.plansService.create(createPlanDto, req.user);
    }
    findAll(req) {
        if (req.user.role === user_entity_1.UserRole.PROFE || req.user.role === user_entity_1.UserRole.ADMIN) {
            return this.plansService.findAll();
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
    update(id, updatePlanDto, req) {
        if (req.user.role !== user_entity_1.UserRole.ADMIN && req.user.role !== user_entity_1.UserRole.PROFE) {
            throw new common_1.ForbiddenException('Only admins and professors can edit plans');
        }
        console.log('Update Payload:', JSON.stringify(updatePlanDto, null, 2));
        return this.plansService.update(id, updatePlanDto, req.user);
    }
    assignPlan(body, req) {
        if (req.user.role !== user_entity_1.UserRole.PROFE) {
            throw new common_1.ForbiddenException('Only professors can assign plans');
        }
        return this.plansService.assignPlan(body.planId, body.studentId, req.user.id);
    }
    getStudentAssignments(studentId, req) {
        if (req.user.role !== user_entity_1.UserRole.PROFE && req.user.role !== user_entity_1.UserRole.ADMIN) {
            throw new common_1.ForbiddenException('Access denied');
        }
        return this.plansService.findAllAssignmentsByStudent(studentId);
    }
    deleteAssignment(id, req) {
        return this.plansService.removeAssignment(id, req.user);
    }
    remove(id, req) {
        return this.plansService.remove(id, req.user);
    }
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
    (0, common_1.Patch)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, update_plan_dto_1.UpdatePlanDto, Object]),
    __metadata("design:returntype", void 0)
], PlansController.prototype, "update", null);
__decorate([
    (0, common_1.Post)('assign'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", void 0)
], PlansController.prototype, "assignPlan", null);
__decorate([
    (0, common_1.Get)('assignments/student/:studentId'),
    __param(0, (0, common_1.Param)('studentId')),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], PlansController.prototype, "getStudentAssignments", null);
__decorate([
    (0, common_1.Delete)('assignments/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], PlansController.prototype, "deleteAssignment", null);
__decorate([
    (0, common_1.Delete)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], PlansController.prototype, "remove", null);
exports.PlansController = PlansController = __decorate([
    (0, common_1.Controller)('plans'),
    (0, common_1.UseGuards)((0, passport_1.AuthGuard)('jwt')),
    (0, common_1.UseInterceptors)(common_1.ClassSerializerInterceptor),
    __metadata("design:paramtypes", [plans_service_1.PlansService])
], PlansController);
//# sourceMappingURL=plans.controller.js.map