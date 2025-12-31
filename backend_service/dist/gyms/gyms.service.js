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
exports.GymsService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const gym_entity_1 = require("./entities/gym.entity");
const exercises_service_1 = require("../exercises/exercises.service");
let GymsService = class GymsService {
    gymsRepository;
    exercisesService;
    constructor(gymsRepository, exercisesService) {
        this.gymsRepository = gymsRepository;
        this.exercisesService = exercisesService;
    }
    async create(createGymDto) {
        const gym = this.gymsRepository.create(createGymDto);
        const savedGym = await this.gymsRepository.save(gym);
        console.log(`[GymsService] Creating Base Exercises for Gym: ${savedGym.id} (${savedGym.businessName})`);
        await this.exercisesService.cloneBaseExercises(savedGym);
        return savedGym;
    }
    findAll() {
        return this.gymsRepository.find();
    }
    findOne(id) {
        return this.gymsRepository.findOneBy({ id });
    }
    async update(id, updateGymDto) {
        await this.gymsRepository.update(id, updateGymDto);
        return this.gymsRepository.findOneBy({ id });
    }
    remove(id) {
        return this.gymsRepository.delete(id);
    }
    countAll() {
        return this.gymsRepository.count();
    }
    async debugGenerateExercises(gymId) {
        let gym;
        if (gymId === 'latest') {
            const gyms = await this.gymsRepository.find({ order: { createdAt: 'DESC' }, take: 1 });
            gym = gyms[0];
        }
        else {
            gym = await this.gymsRepository.findOneBy({ id: gymId });
        }
        if (!gym)
            return { error: 'Gym not found' };
        const logs = [];
        logs.push(`Starting Debug for Gym: ${gym.businessName} (${gym.id})`);
        const testExercise = {
            name: 'DEBUG ENTRY ' + new Date().toISOString(),
            description: 'Test Entry',
            muscles: [
                { name: 'Cuádriceps', role: 'PRIMARY', loadPercentage: 100 }
            ],
            videoUrl: '',
            imageUrl: '',
            muscleGroup: 'Cuádriceps'
        };
        try {
            logs.push(`Attempting to create exercise: ${testExercise.name}`);
            const result = await this.exercisesService.createForGym({
                ...testExercise,
                muscles: testExercise.muscles.map(m => ({
                    muscleId: m.name,
                    role: m.role,
                    loadPercentage: m.loadPercentage
                }))
            }, gym);
            logs.push(`SUCCESS: Created exercise ID ${result.id}`);
            return { success: true, logs, result };
        }
        catch (e) {
            logs.push(`ERROR: ${e.message}`);
            logs.push(`STACK: ${e.stack}`);
            return { success: false, logs, error: e.toString() };
        }
    }
    countActive() {
        return this.gymsRepository.count({ where: { status: gym_entity_1.GymStatus.ACTIVE } });
    }
};
exports.GymsService = GymsService;
exports.GymsService = GymsService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(gym_entity_1.Gym)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        exercises_service_1.ExercisesService])
], GymsService);
//# sourceMappingURL=gyms.service.js.map