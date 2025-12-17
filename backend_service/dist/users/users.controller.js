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
exports.UsersController = void 0;
const common_1 = require("@nestjs/common");
const users_service_1 = require("./users.service");
const create_user_dto_1 = require("./dto/create-user.dto");
const update_user_dto_1 = require("./dto/update-user.dto");
const passport_1 = require("@nestjs/passport");
const user_entity_1 = require("./entities/user.entity");
let UsersController = class UsersController {
    usersService;
    constructor(usersService) {
        this.usersService = usersService;
    }
    create(createUserDto, req) {
        const creator = req.user;
        if (creator.role === user_entity_1.UserRole.SUPER_ADMIN) {
            return this.usersService.create(createUserDto, undefined);
        }
        if (creator.role === user_entity_1.UserRole.ADMIN) {
            if (!createUserDto.role) {
                createUserDto.role = user_entity_1.UserRole.ALUMNO;
            }
            if (createUserDto.role === user_entity_1.UserRole.SUPER_ADMIN) {
                throw new common_1.ForbiddenException('Admin cannot create Super Admin');
            }
            return this.usersService.create(createUserDto, creator);
        }
        if (creator.role === user_entity_1.UserRole.PROFE) {
            createUserDto.role = user_entity_1.UserRole.ALUMNO;
            return this.usersService.create(createUserDto, creator);
        }
        throw new common_1.ForbiddenException('You do not have permission to create users');
    }
    findAll(req, role, gymId) {
        const user = req.user;
        if (user.role === user_entity_1.UserRole.SUPER_ADMIN) {
            return this.usersService.findAllStudents(undefined, role, gymId);
        }
        if (user.role === user_entity_1.UserRole.ADMIN) {
            return this.usersService.findAllStudents(undefined, role, user.gym?.id);
        }
        if (user.role === user_entity_1.UserRole.PROFE) {
            return this.usersService.findAllStudents(user.id, role, user.gym?.id);
        }
        throw new common_1.ForbiddenException('You do not have permission to view users');
    }
    async getProfile(req) {
        const userId = req.user.id;
        const user = await this.usersService.findOne(userId);
        if (!user)
            throw new common_1.NotFoundException('User not found');
        return user;
    }
    async updateProfile(updateUserDto, req) {
        const userId = req.user.id;
        const userRole = req.user.role;
        const user = await this.usersService.findOne(userId);
        if (!user)
            throw new common_1.NotFoundException('User not found');
        const allowedFields = ['phone', 'age', 'gender', 'height'];
        if (userRole === user_entity_1.UserRole.ALUMNO) {
            allowedFields.push('currentWeight', 'personalComment');
            if (updateUserDto.currentWeight) {
                updateUserDto.weightUpdateDate = new Date();
            }
        }
        else if (userRole === user_entity_1.UserRole.PROFE) {
            allowedFields.push('specialty', 'internalNotes');
        }
        else if (userRole === user_entity_1.UserRole.ADMIN) {
            allowedFields.push('adminNotes');
        }
        const filteredDto = {};
        for (const key of Object.keys(updateUserDto)) {
            if (allowedFields.includes(key)) {
                filteredDto[key] = updateUserDto[key];
            }
        }
        if (Object.keys(filteredDto).length === 0) {
            return user;
        }
        return this.usersService.update(userId, filteredDto);
    }
    async validateAccess(user, requestor, action) {
        if (requestor.role === user_entity_1.UserRole.SUPER_ADMIN)
            return true;
        if (user.gym?.id !== requestor.gym?.id) {
            throw new common_1.ForbiddenException('Access denied (Different Gym)');
        }
        if (requestor.role === user_entity_1.UserRole.ADMIN)
            return true;
        if (requestor.role === user_entity_1.UserRole.PROFE) {
            if (action === 'view' && user.id === requestor.id)
                return true;
            if (user.professor?.id === requestor.id)
                return true;
            throw new common_1.ForbiddenException('You can only access your own students');
        }
        if (requestor.role === user_entity_1.UserRole.ALUMNO) {
            if (user.id === requestor.id)
                return true;
        }
        throw new common_1.ForbiddenException('Access denied');
    }
    async findOne(id, req) {
        const user = await this.usersService.findOne(id);
        const requestor = req.user;
        if (!user)
            throw new common_1.NotFoundException('User not found');
        await this.validateAccess(user, requestor, 'view');
        return user;
    }
    async update(id, updateUserDto, req) {
        const requestor = req.user;
        const userToUpdate = await this.usersService.findOne(id);
        if (!userToUpdate)
            throw new common_1.NotFoundException('User not found');
        await this.validateAccess(userToUpdate, requestor, 'update');
        if (requestor.role === user_entity_1.UserRole.PROFE) {
            const allowedStudentFields = ['trainingGoal', 'professorObservations', 'notes'];
            const filteredDto = {};
            for (const key of Object.keys(updateUserDto)) {
                if (allowedStudentFields.includes(key)) {
                    filteredDto[key] = updateUserDto[key];
                }
            }
            if (Object.keys(filteredDto).length === 0) {
                return userToUpdate;
            }
            return this.usersService.update(id, filteredDto);
        }
        return this.usersService.update(id, updateUserDto);
    }
    async updatePaymentStatus(id, req) {
        const requestor = req.user;
        if (requestor.role !== user_entity_1.UserRole.ADMIN && requestor.role !== user_entity_1.UserRole.SUPER_ADMIN) {
            throw new common_1.ForbiddenException('Only Admins can update payment status');
        }
        const user = await this.usersService.findOne(id);
        if (!user)
            throw new common_1.NotFoundException('User not found');
        await this.validateAccess(user, requestor, 'update');
        return this.usersService.markAsPaid(id);
    }
    async remove(id, req) {
        const requestor = req.user;
        const userToDelete = await this.usersService.findOne(id);
        if (!userToDelete)
            throw new common_1.NotFoundException('User not found');
        await this.validateAccess(userToDelete, requestor, 'delete');
        return this.usersService.remove(id);
    }
};
exports.UsersController = UsersController;
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_user_dto_1.CreateUserDto, Object]),
    __metadata("design:returntype", void 0)
], UsersController.prototype, "create", null);
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('role')),
    __param(2, (0, common_1.Query)('gymId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", void 0)
], UsersController.prototype, "findAll", null);
__decorate([
    (0, common_1.Get)('profile'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "getProfile", null);
__decorate([
    (0, common_1.Patch)('profile'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [update_user_dto_1.UpdateUserDto, Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "updateProfile", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "findOne", null);
__decorate([
    (0, common_1.Patch)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, update_user_dto_1.UpdateUserDto, Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "update", null);
__decorate([
    (0, common_1.Patch)(':id/payment-status'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "updatePaymentStatus", null);
__decorate([
    (0, common_1.Delete)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "remove", null);
exports.UsersController = UsersController = __decorate([
    (0, common_1.Controller)('users'),
    (0, common_1.UseGuards)((0, passport_1.AuthGuard)('jwt')),
    __metadata("design:paramtypes", [users_service_1.UsersService])
], UsersController);
//# sourceMappingURL=users.controller.js.map