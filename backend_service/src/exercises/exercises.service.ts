import { Injectable, BadRequestException, NotFoundException, Inject, forwardRef } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, In } from 'typeorm';
import { Exercise } from './entities/exercise.entity';
import { Muscle } from './entities/muscle.entity';
import { ExerciseMuscle, MuscleRole } from './entities/exercise-muscle.entity';
import { CreateExerciseDto, ExerciseMuscleDto } from './dto/create-exercise.dto';
import { User } from '../users/entities/user.entity';
import { UpdateExerciseDto } from './dto/update-exercise.dto';
import { Equipment } from './entities/equipment.entity';
import { BASE_EXERCISES } from './constants/base-exercises';

@Injectable()
export class ExercisesService {
  constructor(
    @InjectRepository(Exercise)
    private exercisesRepository: Repository<Exercise>,
    @InjectRepository(Muscle)
    private musclesRepository: Repository<Muscle>,
    @InjectRepository(ExerciseMuscle)
    private exerciseMuscleRepository: Repository<ExerciseMuscle>,
    @InjectRepository(Equipment)
    private equipmentRepository: Repository<Equipment>,
    private dataSource: DataSource,
  ) { }

  private validateMuscles(muscles: ExerciseMuscleDto[]) {
    if (!muscles || muscles.length === 0) {
      throw new BadRequestException('Se requiere al menos un músculo.');
    }

    const primaryMuscles = muscles.filter(m => m.role === MuscleRole.PRIMARY);
    if (primaryMuscles.length !== 1) {
      throw new BadRequestException('El ejercicio debe tener exactamente un músculo PRIMARIO.');
    }

    if (primaryMuscles[0].loadPercentage <= 0) {
      throw new BadRequestException('El músculo primario no puede tener 0% de carga.');
    }

    const totalLoad = muscles.reduce((sum, m) => sum + m.loadPercentage, 0);
    if (totalLoad !== 100) {
      throw new BadRequestException(`La suma de los porcentajes de carga debe ser 100%. Actual: ${totalLoad}%`);
    }

    const muscleIds = muscles.map(m => m.muscleId);
    const uniqueIds = new Set(muscleIds);
    if (muscleIds.length !== uniqueIds.size) {
      throw new BadRequestException('No se pueden duplicar músculos en el mismo ejercicio.');
    }
  }

  async create(createExerciseDto: any, user: User): Promise<Exercise> {
    const muscleDtos = createExerciseDto.muscles as ExerciseMuscleDto[];
    this.validateMuscles(muscleDtos);

    const primaryDto = muscleDtos.find(m => m.role === MuscleRole.PRIMARY);
    if (!primaryDto) throw new BadRequestException('Falta músculo primario.');

    const primaryMuscleEntity = await this.musclesRepository.findOne({ where: { id: primaryDto.muscleId } });
    if (!primaryMuscleEntity) {
      throw new BadRequestException(`Músculo primario no encontrado (ID: ${primaryDto.muscleId})`);
    }

    const { muscles, equipments, ...exerciseData } = createExerciseDto;

    // Load equipments
    let equipmentEntities: Equipment[] = [];
    if (equipments && Array.isArray(equipments)) {
      equipmentEntities = await this.equipmentRepository.findBy({
        id: In(equipments)
      });
    }

    const exercise = this.exercisesRepository.create({
      ...exerciseData,
      muscleGroup: primaryMuscleEntity.name, // Legacy Sync
      createdBy: user,
      gym: user.gym,
      equipments: equipmentEntities,
    });

    const savedExercise = (await this.exercisesRepository.save(exercise)) as any;

    if (muscles && muscles.length > 0) {
      for (const m of muscles) {
        const em = new ExerciseMuscle();
        em.exercise = savedExercise;
        em.muscle = { id: m.muscleId } as Muscle;
        em.role = m.role;
        em.loadPercentage = m.loadPercentage;

        await this.exerciseMuscleRepository.save(em);
      }
    }

    const fullExercise = await this.findOne(savedExercise.id);
    if (!fullExercise) throw new Error('Failed to retrieve created exercise');
    return fullExercise;
  }

  async createForGym(
    createExerciseDto: CreateExerciseDto,
    gym: any,
  ): Promise<Exercise> {
    // Simplifying to avoid build errors for now
    const exercise = this.exercisesRepository.create({
      ...createExerciseDto,
      gym: gym,
      createdBy: null as any,
      muscleGroup: createExerciseDto.muscleGroup,
    });
    return this.exercisesRepository.save(exercise);
  }

  async findAll(gymId?: string, muscleId?: string): Promise<Exercise[]> {
    return this.findAllFiltered({ gymId, muscleId });
  }

  async findAllFiltered(options: { gymId?: string; muscleId?: string; equipmentIds?: string[] }): Promise<Exercise[]> {
    const query = this.exercisesRepository.createQueryBuilder('exercise')
      .leftJoinAndSelect('exercise.exerciseMuscles', 'exerciseMuscle')
      .leftJoinAndSelect('exerciseMuscle.muscle', 'muscle')
      .leftJoinAndSelect('exercise.equipments', 'equipment')
      .leftJoinAndSelect('exercise.createdBy', 'user')
      .leftJoinAndSelect('exercise.gym', 'gym')
      .orderBy('exercise.name', 'ASC');

    if (options.gymId) {
      query.andWhere('gym.id = :gymId', { gymId: options.gymId });
    }

    if (options.muscleId) {
      query.andWhere('exercise.id IN ' +
        query.subQuery()
          .select('em.exerciseId')
          .from(ExerciseMuscle, 'em')
          .where('em.muscleId = :mId')
          .getQuery(), { mId: options.muscleId });
    }

    if (options.equipmentIds && options.equipmentIds.length > 0) {
      query.andWhere('exercise.id IN ' +
        query.subQuery()
          .select('ee.exerciseId')
          .from('exercise_equipments', 'ee')
          .where('ee.equipmentId IN (:...eIds)')
          .getQuery(), { eIds: options.equipmentIds });
    }

    return query.getMany();
  }

  async findAllMuscles(): Promise<Muscle[]> {
    return this.musclesRepository.find({
      order: { order: 'ASC', name: 'ASC' }
    });
  }

  async findAllEquipments(): Promise<Equipment[]> {
    return this.equipmentRepository.find({
      order: { name: 'ASC' }
    });
  }

  async findOne(id: string): Promise<Exercise | null> {
    return this.exercisesRepository.findOne({
      where: { id },
      relations: ['exerciseMuscles', 'exerciseMuscles.muscle', 'equipments']
    });
  }

  async update(id: string, updateExerciseDto: any): Promise<Exercise | null> {
    const { muscles, equipments, ...exerciseData } = updateExerciseDto;

    const exercise = await this.findOne(id);
    if (!exercise) {
      throw new NotFoundException(`Exercise with ID ${id} not found`);
    }

    Object.assign(exercise, exerciseData);

    if (equipments !== undefined) {
      const ids = Array.isArray(equipments) ? equipments : [];
      const equipmentEntities = await this.equipmentRepository.findBy({
        id: In(ids)
      });
      exercise.equipments = equipmentEntities;
    }

    await this.exercisesRepository.save(exercise);

    if (muscles) {
      this.validateMuscles(muscles);

      await this.exerciseMuscleRepository.delete({ exercise: { id: id } as any });

      for (const m of muscles) {
        const em = new ExerciseMuscle();
        em.exercise = exercise;
        em.muscle = { id: m.muscleId } as Muscle;
        em.role = m.role;
        em.loadPercentage = m.loadPercentage;

        await this.exerciseMuscleRepository.save(em);
      }

      const primaryDto = muscles.find((m: any) => m.role === MuscleRole.PRIMARY);
      if (primaryDto) {
        const pMuscle = await this.musclesRepository.findOne({ where: { id: primaryDto.muscleId } });
        if (pMuscle) {
          exercise.muscleGroup = pMuscle.name;
          await this.exercisesRepository.update({ id }, { muscleGroup: pMuscle.name });
        }
      }
    }

    return this.findOne(id);
  }

  async remove(id: string): Promise<void> {
    try {
      await this.exercisesRepository.delete(id);
    } catch (error: any) {
      if (error.code === '23503') {
        const { ConflictException } = require('@nestjs/common');
        throw new ConflictException(`No se puede eliminar el ejercicio porque es parte de planes o ejecuciones históricas. Detalle: ${error.detail}`);
      }
      throw error;
    }
  }

  async cloneBaseExercises(gym: any): Promise<void> {
    const allMuscles = await this.musclesRepository.find();
    const muscleMap = new Map<string, Muscle>();
    allMuscles.forEach(m => muscleMap.set(m.name, m));

    for (const base of BASE_EXERCISES) {
      // 1. Create Exercise
      const exercise = this.exercisesRepository.create({
        name: base.name,
        description: base.description,
        videoUrl: '',
        imageUrl: '',
        metricType: 'REPS',
        gym: gym,
        muscleGroup: base.muscles.find(m => m.role === 'PRIMARY')?.name || undefined
      });

      // Valid casting to ensure it's treated as a single entity
      const saved = (await this.exercisesRepository.save(exercise)) as Exercise;

      // 2. Create ExerciseMuscles
      for (const m of base.muscles) {
        const muscleEntity = muscleMap.get(m.name);
        if (muscleEntity) {
          const em = this.exerciseMuscleRepository.create({
            exercise: saved,
            muscle: muscleEntity,
            role: m.role as MuscleRole,
            loadPercentage: m.loadPercentage
          });
          await this.exerciseMuscleRepository.save(em);
        } else {
          console.warn(`[cloneBaseExercises] Muscle not found: ${m.name}`);
        }
      }
    }
  }
}
