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
exports.GymsController = void 0;
const common_1 = require("@nestjs/common");
const passport_1 = require("@nestjs/passport");
const platform_express_1 = require("@nestjs/platform-express");
const multer_1 = require("multer");
const path_1 = require("path");
const fs_1 = require("fs");
const user_entity_1 = require("../users/entities/user.entity");
const gyms_service_1 = require("./gyms.service");
const create_gym_dto_1 = require("./dto/create-gym.dto");
const update_gym_dto_1 = require("./dto/update-gym.dto");
let GymsController = class GymsController {
    gymsService;
    constructor(gymsService) {
        this.gymsService = gymsService;
    }
    checkSuperAdmin(user) {
        if (user.role !== user_entity_1.UserRole.SUPER_ADMIN) {
            throw new common_1.ForbiddenException('Only Super Admin can access this resource.');
        }
    }
    validateAdminAccess(user, targetGymId) {
        if (user.role === user_entity_1.UserRole.SUPER_ADMIN)
            return;
        if (user.role === user_entity_1.UserRole.ADMIN) {
            if (user.gym && user.gym.id === targetGymId) {
                return;
            }
        }
        throw new common_1.ForbiddenException('You do not have permission to modify this gym.');
    }
    create(createGymDto, req) {
        this.checkSuperAdmin(req.user);
        return this.gymsService.create(createGymDto);
    }
    findAll(req) {
        this.checkSuperAdmin(req.user);
        return this.gymsService.findAll();
    }
    findOne(id, req) {
        if (req.user.role !== user_entity_1.UserRole.SUPER_ADMIN) {
            if (!req.user.gym || req.user.gym.id !== id) {
                throw new common_1.ForbiddenException('Access denied to this gym data.');
            }
        }
        return this.gymsService.findOne(id);
    }
    update(id, updateGymDto, req) {
        this.validateAdminAccess(req.user, id);
        return this.gymsService.update(id, updateGymDto);
    }
    remove(id, req) {
        this.checkSuperAdmin(req.user);
        return this.gymsService.remove(id);
    }
    async uploadLogo(id, file, req) {
        this.validateAdminAccess(req.user, id);
        if (!file)
            throw new common_1.BadRequestException('File is not an image or was rejected');
        const logoUrl = `/uploads/logos/${file.filename}`;
        await this.gymsService.update(id, { logoUrl });
        return { logoUrl };
    }
};
exports.GymsController = GymsController;
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_gym_dto_1.CreateGymDto, Object]),
    __metadata("design:returntype", void 0)
], GymsController.prototype, "create", null);
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], GymsController.prototype, "findAll", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], GymsController.prototype, "findOne", null);
__decorate([
    (0, common_1.Patch)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, update_gym_dto_1.UpdateGymDto, Object]),
    __metadata("design:returntype", void 0)
], GymsController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], GymsController.prototype, "remove", null);
__decorate([
    (0, common_1.Post)(':id/logo'),
    (0, common_1.UseInterceptors)((0, platform_express_1.FileInterceptor)('file', {
        storage: (0, multer_1.diskStorage)({
            destination: (req, file, cb) => {
                const uploadPath = './uploads/logos';
                if (!(0, fs_1.existsSync)(uploadPath)) {
                    (0, fs_1.mkdirSync)(uploadPath, { recursive: true });
                }
                cb(null, uploadPath);
            },
            filename: (req, file, cb) => {
                const randomName = Array(32).fill(null).map(() => (Math.round(Math.random() * 16)).toString(16)).join('');
                cb(null, `${randomName}${(0, path_1.extname)(file.originalname)}`);
            },
        }),
        fileFilter: (req, file, cb) => {
            if (!file.mimetype.match(/\/(jpg|jpeg|png|gif)$/)) {
                return cb(new common_1.BadRequestException('Only image files are allowed!'), false);
            }
            cb(null, true);
        },
        limits: {
            fileSize: 5 * 1024 * 1024
        }
    })),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.UploadedFile)()),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], GymsController.prototype, "uploadLogo", null);
exports.GymsController = GymsController = __decorate([
    (0, common_1.Controller)('gyms'),
    (0, common_1.UseGuards)((0, passport_1.AuthGuard)('jwt')),
    __metadata("design:paramtypes", [gyms_service_1.GymsService])
], GymsController);
//# sourceMappingURL=gyms.controller.js.map