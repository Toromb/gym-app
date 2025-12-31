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
Object.defineProperty(exports, "__esModule", { value: true });
exports.Gym = exports.GymStatus = exports.GymPlan = void 0;
const typeorm_1 = require("typeorm");
const user_entity_1 = require("../../users/entities/user.entity");
var GymPlan;
(function (GymPlan) {
    GymPlan["BASIC"] = "basic";
    GymPlan["PRO"] = "pro";
    GymPlan["PREMIUM"] = "premium";
})(GymPlan || (exports.GymPlan = GymPlan = {}));
var GymStatus;
(function (GymStatus) {
    GymStatus["ACTIVE"] = "active";
    GymStatus["SUSPENDED"] = "suspended";
})(GymStatus || (exports.GymStatus = GymStatus = {}));
let Gym = class Gym {
    id;
    businessName;
    address;
    phone;
    email;
    status;
    suspensionReason;
    subscriptionPlan;
    expirationDate;
    maxProfiles;
    logoUrl;
    primaryColor;
    secondaryColor;
    welcomeMessage;
    openingHours;
    paymentAlias;
    paymentCbu;
    paymentAccountName;
    paymentBankName;
    paymentNotes;
    createdAt;
    updatedAt;
    users;
};
exports.Gym = Gym;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], Gym.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ unique: true }),
    __metadata("design:type", String)
], Gym.prototype, "businessName", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], Gym.prototype, "address", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Gym.prototype, "phone", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Gym.prototype, "email", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: GymStatus,
        default: GymStatus.ACTIVE,
    }),
    __metadata("design:type", String)
], Gym.prototype, "status", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', nullable: true }),
    __metadata("design:type", String)
], Gym.prototype, "suspensionReason", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: GymPlan,
        default: GymPlan.BASIC,
    }),
    __metadata("design:type", String)
], Gym.prototype, "subscriptionPlan", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'date', nullable: true }),
    __metadata("design:type", Date)
], Gym.prototype, "expirationDate", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'int', default: 50 }),
    __metadata("design:type", Number)
], Gym.prototype, "maxProfiles", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Gym.prototype, "logoUrl", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Gym.prototype, "primaryColor", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Gym.prototype, "secondaryColor", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Gym.prototype, "welcomeMessage", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Gym.prototype, "openingHours", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Gym.prototype, "paymentAlias", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Gym.prototype, "paymentCbu", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Gym.prototype, "paymentAccountName", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Gym.prototype, "paymentBankName", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', nullable: true }),
    __metadata("design:type", String)
], Gym.prototype, "paymentNotes", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], Gym.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)(),
    __metadata("design:type", Date)
], Gym.prototype, "updatedAt", void 0);
__decorate([
    (0, typeorm_1.OneToMany)(() => user_entity_1.User, (user) => user.gym),
    __metadata("design:type", Array)
], Gym.prototype, "users", void 0);
exports.Gym = Gym = __decorate([
    (0, typeorm_1.Entity)('gyms')
], Gym);
//# sourceMappingURL=gym.entity.js.map