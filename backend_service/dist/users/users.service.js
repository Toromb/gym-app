"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var UsersService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.UsersService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const user_entity_1 = require("./entities/user.entity");
const bcrypt = __importStar(require("bcrypt"));
const gyms_service_1 = require("../gyms/gyms.service");
let UsersService = UsersService_1 = class UsersService {
    usersRepository;
    gymsService;
    logger = new common_1.Logger(UsersService_1.name);
    constructor(usersRepository, gymsService) {
        this.usersRepository = usersRepository;
        this.gymsService = gymsService;
    }
    async create(createUserDto, creator) {
        const { password, gymId, professorId, ...rest } = createUserDto;
        const passwordToHash = password || '123456';
        const passwordHash = await bcrypt.hash(passwordToHash, 10);
        let gym = null;
        if (gymId) {
            gym = await this.gymsService.findOne(gymId);
        }
        else if (creator && creator.gym) {
            gym = creator.gym;
        }
        let professor = (creator && creator.role === user_entity_1.UserRole.PROFE) ? creator : undefined;
        if (professorId) {
            professor = await this.usersRepository.findOne({ where: { id: professorId } });
        }
        const user = this.usersRepository.create({
            ...rest,
            passwordHash,
            professor: professor || undefined,
            gym: gym || undefined,
        });
        return this.usersRepository.save(user);
    }
    async findAllStudents(professorId, roleFilter, gymId) {
        const where = {};
        if (roleFilter) {
            where.role = roleFilter;
        }
        else if (professorId) {
            where.role = user_entity_1.UserRole.ALUMNO;
        }
        if (professorId) {
            where.professor = { id: professorId };
        }
        if (gymId) {
            where.gym = { id: gymId };
        }
        const users = await this.usersRepository.find({
            where,
            relations: ['studentPlans', 'professor', 'gym'],
        });
        return users.map(u => {
            if (u.membershipExpirationDate) {
                const status = this.calculatePaymentStatus(u.membershipExpirationDate);
                u.paymentStatus = status;
            }
            return u;
        });
    }
    async findOneByEmail(email) {
        const user = await this.usersRepository.createQueryBuilder('user')
            .addSelect('user.passwordHash')
            .leftJoinAndSelect('user.gym', 'gym')
            .where('user.email = :email', { email })
            .getOne();
        if (user && user.membershipExpirationDate) {
            const status = this.calculatePaymentStatus(user.membershipExpirationDate);
            user.paymentStatus = status;
        }
        return user;
    }
    async findOne(id) {
        const user = await this.usersRepository.findOne({
            where: { id },
            relations: ['gym', 'professor'],
        });
        if (user && user.membershipExpirationDate) {
            const status = this.calculatePaymentStatus(user.membershipExpirationDate);
            user.paymentStatus = status;
        }
        return user;
    }
    async update(id, updateUserDto) {
        const user = await this.findOne(id);
        if (!user) {
            throw new Error('User not found');
        }
        const { password, professorId, ...rest } = updateUserDto;
        if (password) {
            user.passwordHash = await bcrypt.hash(password, 10);
        }
        if (professorId !== undefined) {
            if (professorId === null) {
                user.professor = null;
            }
            else {
                user.professor = await this.usersRepository.findOne({ where: { id: professorId } });
            }
        }
        Object.assign(user, rest);
        return this.usersRepository.save(user);
    }
    async remove(id) {
        await this.usersRepository.delete(id);
    }
    async countAll() {
        return this.usersRepository.count();
    }
    async markAsPaid(id) {
        const user = await this.findOne(id);
        if (!user)
            throw new Error('User not found');
        const referenceDate = user.membershipExpirationDate ? new Date(user.membershipExpirationDate) : new Date(user.membershipStartDate);
        referenceDate.setMonth(referenceDate.getMonth() + 1);
        user.membershipExpirationDate = referenceDate;
        user.lastPaymentDate = new Date().toISOString().split('T')[0];
        return this.usersRepository.save(user);
    }
    calculatePaymentStatus(expirationDate) {
        if (!expirationDate)
            return 'pending';
        const now = new Date();
        const exp = new Date(expirationDate);
        now.setHours(0, 0, 0, 0);
        exp.setHours(0, 0, 0, 0);
        const diffTime = now.getTime() - exp.getTime();
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        if (diffDays <= 0)
            return 'paid';
        if (diffDays <= 10)
            return 'pending';
        return 'overdue';
    }
};
exports.UsersService = UsersService;
exports.UsersService = UsersService = UsersService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        gyms_service_1.GymsService])
], UsersService);
//# sourceMappingURL=users.service.js.map