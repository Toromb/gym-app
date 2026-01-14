import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { FreeTrainingDefinition, FreeTrainingType, TrainingLevel, BodySector, CardioLevel } from './entities/free-training-definition.entity';
import { FreeTrainingDefinitionExercise } from './entities/free-training-definition-exercise.entity';
import { CreateFreeTrainingDefinitionDto } from './dto/create-free-training-definition.dto';
import { Exercise } from '../exercises/entities/exercise.entity';
import { Gym } from '../gyms/entities/gym.entity';

@Injectable()
export class FreeTrainingsService {
    constructor(
        @InjectRepository(FreeTrainingDefinition)
        private readonly freeTrainingRepo: Repository<FreeTrainingDefinition>,
        @InjectRepository(FreeTrainingDefinitionExercise)
        private readonly freeTrainingExerciseRepo: Repository<FreeTrainingDefinitionExercise>,
        @InjectRepository(Exercise)
        private readonly exerciseRepo: Repository<Exercise>,
    ) { }

    async create(createDto: CreateFreeTrainingDefinitionDto, gymId: string) {
        const { exercises, ...definitionData } = createDto;

        const definition = this.freeTrainingRepo.create({
            ...definitionData,
            gym: { id: gymId } as Gym,
        });

        const savedDefinition = await this.freeTrainingRepo.save(definition);

        if (exercises && exercises.length > 0) {
            const exerciseEntities = [];
            for (const exDto of exercises) {
                const exercise = await this.exerciseRepo.findOne({ where: { id: exDto.exerciseId } });
                if (!exercise) continue; // Or throw error? Skipping for now to be safe.

                const newEx = this.freeTrainingExerciseRepo.create({
                    freeTraining: savedDefinition,
                    exercise: exercise,
                    order: exDto.order ?? 0,
                    sets: exDto.sets,
                    reps: exDto.reps,
                    suggestedLoad: exDto.suggestedLoad,
                    rest: exDto.rest,
                    notes: exDto.notes,
                    videoUrl: exDto.videoUrl,
                });
                exerciseEntities.push(newEx);
            }
            await this.freeTrainingExerciseRepo.save(exerciseEntities);
        }

        return this.findOne(savedDefinition.id);
    }

    async findAll(
        gymId: string,
        filters: {
            type?: string;
            level?: string;
            sector?: string;
            cardioLevel?: string;
        },
    ) {
        const query = this.freeTrainingRepo.createQueryBuilder('ft')
            .leftJoinAndSelect('ft.exercises', 'fte')
            .leftJoinAndSelect('fte.exercise', 'ex')
            .leftJoinAndSelect('ex.equipments', 'eq')
            .where('ft.gymId = :gymId', { gymId });

        if (filters.type) {
            query.andWhere('ft.type = :type', { type: filters.type });
        }
        if (filters.level) {
            query.andWhere('ft.level = :level', { level: filters.level });
        }
        if (filters.sector) {
            query.andWhere('ft.sector = :sector', { sector: filters.sector });
        }
        if (filters.cardioLevel) {
            query.andWhere('ft.cardioLevel = :cardioLevel', { cardioLevel: filters.cardioLevel });
        }

        // Default sort by createdAt desc? Or name?
        query.orderBy('ft.createdAt', 'DESC');

        return query.getMany();
    }

    async findOne(id: string) {
        const ft = await this.freeTrainingRepo.findOne({
            where: { id },
            relations: ['exercises', 'exercises.exercise', 'exercises.exercise.equipments'],
        });
        if (!ft) throw new NotFoundException('Free Training Definition not found');

        // Sort exercises by order
        if (ft.exercises) {
            ft.exercises.sort((a, b) => a.order - b.order);
        }
        return ft;
    }

    async update(id: string, updateDto: any) {
        const ft = await this.findOne(id);
        const { exercises, ...definitionData } = updateDto;

        // Update scalar fields
        Object.assign(ft, definitionData);
        const savedDefinition = await this.freeTrainingRepo.save(ft);

        // Update Exercises (Full Replacement Strategy for simplicity, similar to Plans)
        if (exercises) {
            // 1. Remove existing exercises
            // Note: Cascade delete is optional. Manual delete is safer.
            // But we need to check if existing exercises are orphaned.
            const existingExercises = await this.freeTrainingExerciseRepo.find({ where: { freeTraining: { id: id } } });
            if (existingExercises.length > 0) {
                await this.freeTrainingExerciseRepo.remove(existingExercises);
            }

            // 2. Add new exercises
            const exerciseEntities = [];
            for (const exDto of exercises) {
                const exercise = await this.exerciseRepo.findOne({ where: { id: exDto.exerciseId } });
                if (!exercise) continue;

                const newEx = this.freeTrainingExerciseRepo.create({
                    freeTraining: savedDefinition,
                    exercise: exercise,
                    order: exDto.order ?? 0,
                    sets: exDto.sets,
                    reps: exDto.reps,
                    suggestedLoad: exDto.suggestedLoad,
                    rest: exDto.rest,
                    notes: exDto.notes,
                    videoUrl: exDto.videoUrl,
                });
                exerciseEntities.push(newEx);
            }
            await this.freeTrainingExerciseRepo.save(exerciseEntities);
        }

        return this.findOne(savedDefinition.id);
    }

    async remove(id: string) {
        const result = await this.freeTrainingRepo.delete(id);
        if (result.affected === 0) {
            throw new NotFoundException(`Free Training definition with ID "${id}" not found`);
        }
    }
}
