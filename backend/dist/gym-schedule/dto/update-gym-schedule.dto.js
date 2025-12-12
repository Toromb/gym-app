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
exports.UpdateGymScheduleDto = void 0;
const swagger_1 = require("@nestjs/swagger");
const class_validator_1 = require("class-validator");
class UpdateGymScheduleDto {
    dayOfWeek;
    isClosed;
    openTimeMorning;
    closeTimeMorning;
    openTimeAfternoon;
    closeTimeAfternoon;
    notes;
}
exports.UpdateGymScheduleDto = UpdateGymScheduleDto;
__decorate([
    (0, swagger_1.ApiProperty)({ description: 'Day of the week', example: 'MONDAY' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], UpdateGymScheduleDto.prototype, "dayOfWeek", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: 'Is the gym closed?', example: false }),
    (0, class_validator_1.IsBoolean)(),
    __metadata("design:type", Boolean)
], UpdateGymScheduleDto.prototype, "isClosed", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: 'Morning Open Time', example: '08:00', required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateGymScheduleDto.prototype, "openTimeMorning", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: 'Morning Close Time', example: '12:00', required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateGymScheduleDto.prototype, "closeTimeMorning", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: 'Afternoon Open Time', example: '16:00', required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateGymScheduleDto.prototype, "openTimeAfternoon", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: 'Afternoon Close Time', example: '21:00', required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateGymScheduleDto.prototype, "closeTimeAfternoon", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: 'Notes', example: 'Holiday', required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateGymScheduleDto.prototype, "notes", void 0);
//# sourceMappingURL=update-gym-schedule.dto.js.map