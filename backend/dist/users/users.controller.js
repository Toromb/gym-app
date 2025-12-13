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
        if (creator.role === user_entity_1.UserRole.ADMIN) {
            if (!createUserDto.role) {
                createUserDto.role = user_entity_1.UserRole.ALUMNO;
            }
            return this.usersService.create(createUserDto);
        }
        if (creator.role === user_entity_1.UserRole.PROFE) {
            createUserDto.role = user_entity_1.UserRole.ALUMNO;
            return this.usersService.create(createUserDto, creator);
        }
        throw new common_1.ForbiddenException('You do not have permission to create users');
    }
    findAll(req, role) {
        const user = req.user;
        if (user.role === user_entity_1.UserRole.ADMIN) {
            return this.usersService.findAllStudents(undefined, role);
        }
        if (user.role === user_entity_1.UserRole.PROFE) {
            return this.usersService.findAllStudents(user.id, role);
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
    async findOne(id, req) {
        const user = await this.usersService.findOne(id);
        const requestor = req.user;
        if (!user)
            throw new common_1.NotFoundException('User not found');
        if (requestor.role === user_entity_1.UserRole.ADMIN)
            return user;
        if (requestor.role === user_entity_1.UserRole.PROFE) {
            if (user.professor?.id === requestor.id || user.id === requestor.id) {
                return user;
            }
            throw new common_1.ForbiddenException('You can only view your own students');
        }
        if (requestor.id === user.id)
            return user;
        throw new common_1.ForbiddenException('Access denied');
    }
    async update(id, updateUserDto, req) {
        const requestor = req.user;
        if (requestor.role === user_entity_1.UserRole.ADMIN) {
            return this.usersService.update(id, updateUserDto);
        }
        if (requestor.role === user_entity_1.UserRole.PROFE) {
            const userToUpdate = await this.usersService.findOne(id);
            if (!userToUpdate)
                throw new common_1.NotFoundException('User not found');
            if (userToUpdate.professor?.id !== requestor.id) {
                throw new common_1.ForbiddenException('You can only edit your own students');
            }
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
        throw new common_1.ForbiddenException('Permission denied');
    }
    async remove(id, req) {
        const requestor = req.user;
        if (requestor.role === user_entity_1.UserRole.ADMIN) {
            return this.usersService.remove(id);
        }
        if (requestor.role === user_entity_1.UserRole.PROFE) {
            const userToDelete = await this.usersService.findOne(id);
            if (!userToDelete)
                throw new common_1.NotFoundException('User not found');
            if (userToDelete.professor?.id !== requestor.id) {
                throw new common_1.ForbiddenException('You can only delete your own students');
            }
            return this.usersService.remove(id);
        }
        throw new common_1.ForbiddenException('Permission denied');
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
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
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