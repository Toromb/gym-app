import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Exercise } from './entities/exercise.entity';
import { Muscle } from './entities/muscle.entity';
import { ExerciseMuscle, MuscleRole } from './entities/exercise-muscle.entity';
import { CreateExerciseDto, ExerciseMuscleDto } from './dto/create-exercise.dto';
import { User } from '../users/entities/user.entity';
import { UpdateExerciseDto } from './dto/update-exercise.dto';

@Injectable()
export class ExercisesService {
  constructor(
    @InjectRepository(Exercise)
    private exercisesRepository: Repository<Exercise>,
    @InjectRepository(Muscle)
    private musclesRepository: Repository<Muscle>,
    @InjectRepository(ExerciseMuscle)
    private exerciseMusclesRepository: Repository<ExerciseMuscle>,
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

  async create(
    createExerciseDto: CreateExerciseDto,
    user: User,
  ): Promise<Exercise> {
    this.validateMuscles(createExerciseDto.muscles);

    // Validation ensures one Primary exists, but we safe check for TS
    const primaryDto = createExerciseDto.muscles.find(m => m.role === MuscleRole.PRIMARY);
    if (!primaryDto) throw new BadRequestException('Falta músculo primario.'); // Should be caught by validateMuscles

    const primaryMuscleEntity = await this.musclesRepository.findOne({ where: { id: primaryDto.muscleId } });
    if (!primaryMuscleEntity) {
      throw new BadRequestException(`Músculo primario no encontrado (ID: ${primaryDto.muscleId})`);
    }

    // Transactional save to ensure consistency
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const exercise = this.exercisesRepository.create({
        ...createExerciseDto,
        muscleGroup: primaryMuscleEntity.name, // Legacy Sync
        createdBy: user,
        gym: user.gym,
      });

      const savedExercise = await queryRunner.manager.save(exercise);

      const exerciseMuscles = createExerciseDto.muscles.map(mDto => {
        return this.exerciseMusclesRepository.create({
          exercise: savedExercise,
          muscle: { id: mDto.muscleId } as Muscle,
          role: mDto.role,
          loadPercentage: mDto.loadPercentage
        });
      });

      await queryRunner.manager.save(exerciseMuscles);

      await queryRunner.commitTransaction();

      // Return full object with relations
      const createdExercise = await this.findOne(savedExercise.id);
      if (!createdExercise) throw new Error('Error retrieving created exercise.');
      return createdExercise;
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  async createForGym(
    createExerciseDto: CreateExerciseDto,
    gym: any,
  ): Promise<Exercise> {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // 1. Create Exercise
      const exercise = this.exercisesRepository.create({
        ...createExerciseDto,
        gym: gym,
        createdBy: null as any,
        muscleGroup: createExerciseDto.muscleGroup,
      });

      console.log(`[ExercisesService] Saving exercise "${createExerciseDto.name}" for Gym ${gym?.id}`);
      const savedExercise = await queryRunner.manager.save(exercise);
      console.log(`[ExercisesService] Exercise saved with ID: ${savedExercise.id}`);

      // 2. Map Muscles (if provided)
      if (createExerciseDto.muscles && createExerciseDto.muscles.length > 0) {
        const exerciseMuscles: ExerciseMuscle[] = [];

        for (const mDto of createExerciseDto.muscles) {
          // For Template functionality, we allow passing "Name" in the muscleId field
          // Check if muscle exists by UUID (standard) or Name (template)
          let muscle = await this.musclesRepository.findOne({ where: { id: mDto.muscleId } });

          if (!muscle) {
            // Try finding by name (Case Insensitive)
            muscle = await this.musclesRepository.createQueryBuilder('muscle')
              .where('LOWER(muscle.name) = LOWER(:name)', { name: mDto.muscleId })
              .getOne();
          }

          if (muscle) {
            const em = this.exerciseMusclesRepository.create({
              exercise: savedExercise,
              muscle: muscle,
              role: mDto.role,
              loadPercentage: mDto.loadPercentage
            });
            exerciseMuscles.push(em);
          } else {
            console.warn(`[ExercisesService] Muscle not found: ${mDto.muscleId} for exercise ${createExerciseDto.name}`);
          }
        }

        if (exerciseMuscles.length > 0) {
          await queryRunner.manager.save(exerciseMuscles);
          console.log(`[ExercisesService] Saved ${exerciseMuscles.length} muscle associations.`);
        }
      }

      await queryRunner.commitTransaction();
      return savedExercise;

    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  async findAll(gymId?: string, muscleId?: string): Promise<Exercise[]> {
    const query = this.exercisesRepository.createQueryBuilder('exercise')
      .leftJoinAndSelect('exercise.exerciseMuscles', 'exerciseMuscles')
      .leftJoinAndSelect('exerciseMuscles.muscle', 'muscle')
      .leftJoinAndSelect('exercise.gym', 'gym');

    if (gymId) {
      query.andWhere('gym.id = :gymId', { gymId });
    }

    if (muscleId) {
      // Filter exercises that have THIS muscle involved
      query.andWhere('exerciseMuscles.muscleId = :muscleId', { muscleId });
    }

    query.orderBy('exercise.name', 'ASC');

    return query.getMany();
  }

  async findAllMuscles(): Promise<Muscle[]> {
    return this.musclesRepository.find({
      order: { order: 'ASC', name: 'ASC' }
    });
  }

  async findOne(id: string): Promise<Exercise | null> {
    return this.exercisesRepository.findOne({
      where: { id },
      relations: ['exerciseMuscles', 'exerciseMuscles.muscle']
    });
  }

  async update(
    id: string,
    updateExerciseDto: UpdateExerciseDto,
  ): Promise<Exercise | null> {
    // If muscles are being updated, we need to re-validate everything
    // We can't partially update muscles array easily without complex logic, so we assume full replacement if provided.

    let legacyMuscleGroupName: string | undefined;

    if (updateExerciseDto.muscles) {
      // Validation needs to happen before any DB changes
      // Use CreateExerciseDto logic for validation (since structure matches)
      this.validateMuscles(updateExerciseDto.muscles);

      const primaryDto = updateExerciseDto.muscles.find(m => m.role === MuscleRole.PRIMARY);
      if (!primaryDto) throw new BadRequestException('Falta músculo primario.'); // TS Check

      const primaryMuscleEntity = await this.musclesRepository.findOne({ where: { id: primaryDto.muscleId } });
      if (!primaryMuscleEntity) throw new BadRequestException('Músculo primario inválido');
      legacyMuscleGroupName = primaryMuscleEntity.name;
    }

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const { muscles, ...simpleFields } = updateExerciseDto;

      await queryRunner.manager.update(Exercise, id, {
        ...simpleFields,
        ...(legacyMuscleGroupName ? { muscleGroup: legacyMuscleGroupName } : {})
      });

      if (muscles) {
        // Hard replacement: Delete old relations
        await queryRunner.manager.delete(ExerciseMuscle, { exercise: { id } });

        // Create new ones
        const newRelations = muscles.map(mDto => {
          return this.exerciseMusclesRepository.create({
            exercise: { id } as Exercise,
            muscle: { id: mDto.muscleId } as Muscle,
            role: mDto.role,
            loadPercentage: mDto.loadPercentage
          });
        });
        await queryRunner.manager.save(newRelations);
      }

      await queryRunner.commitTransaction();
      return this.findOne(id);

    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  async remove(id: string): Promise<void> {
    try {
      await this.exercisesRepository.delete(id);
    } catch (error) {
      // console.error(`Failed to delete Exercise ${id}`, error); 
      if (error.code === '23503') {
        const { ConflictException } = require('@nestjs/common');
        throw new ConflictException(`No se puede eliminar el ejercicio porque es parte de planes o ejecuciones históricas. Detalle: ${error.detail}`);
      }
      throw error;
    }
  }

  async cloneBaseExercises(gym: any): Promise<void> {
    const { BASE_EXERCISES } = require('./constants/base-exercises');
    console.log(`[ExercisesService] Starting Base Exercises Cloning for Gym: ${gym.businessName} (${gym.id})`);

    let successCount = 0;
    let failCount = 0;
    const errors: string[] = [];

    // Pre-fetch all muscles to avoid N+1 queries during loop
    const allMuscles = await this.musclesRepository.find();

    // Normalize muscle names for case-insensitive lookup
    const muscleMap = new Map<string, Muscle>();
    allMuscles.forEach(m => muscleMap.set(m.name.toLowerCase(), m));

    for (const baseEx of BASE_EXERCISES) {
      const queryRunner = this.dataSource.createQueryRunner();
      await queryRunner.connect();
      await queryRunner.startTransaction();

      try {
        // 1. Validate Muscles Existence
        const resolvedMuscles: { entity: Muscle; role: any; load: number }[] = [];
        let missingMuscleError = null;

        for (const mDto of baseEx.muscles) {
          const muscleEntity = muscleMap.get(mDto.name.toLowerCase());
          if (!muscleEntity) {
            missingMuscleError = `Muscle '${mDto.name}' not found in DB`;
            break;
          }
          resolvedMuscles.push({
            entity: muscleEntity,
            role: mDto.role,
            load: mDto.loadPercentage
          });
        }

        if (missingMuscleError) {
          throw new Error(missingMuscleError);
        }

        // 2. Create Exercise
        const exercise = this.exercisesRepository.create({
          name: baseEx.name,
          description: baseEx.description,
          gym: gym,
          createdBy: null as any, // System created
          muscleGroup: baseEx.muscles.find((m: any) => m.role === 'PRIMARY')?.name,
        });

        const savedExercise = await queryRunner.manager.save(exercise);

        // 3. Create Relations
        const exerciseMuscles = resolvedMuscles.map(rm => {
          return this.exerciseMusclesRepository.create({
            exercise: savedExercise,
            muscle: rm.entity,
            role: rm.role,
            loadPercentage: rm.load
          });
        });

        await queryRunner.manager.save(exerciseMuscles);
        await queryRunner.commitTransaction();
        successCount++;

      } catch (error) {
        await queryRunner.rollbackTransaction();
        failCount++;
        const sendErr = `Failed to clone '${baseEx.name}': ${error.message}`;
        console.error(`[ExercisesService] ${sendErr}`);
        errors.push(sendErr);
      } finally {
        await queryRunner.release();
      }
    }

    console.log(`[ExercisesService] Cloning Finished. Success: ${successCount}, Failed: ${failCount}`);
    if (failCount > 0) {
      console.error('[ExercisesService] Cloning Errors Summary:', errors);
    }
  }
}
