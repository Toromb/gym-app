import {
  Injectable,
  NotFoundException,
  ConflictException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, MoreThanOrEqual } from 'typeorm';
import {
  TrainingSession,
  ExecutionStatus,
} from './entities/training-session.entity';
import { SessionExercise } from './entities/session-exercise.entity';
import { Plan, PlanExercise } from './entities/plan.entity';
import { User } from '../users/entities/user.entity';
import { Exercise } from '../exercises/entities/exercise.entity';
import { StudentPlan } from './entities/student-plan.entity';
import { MuscleLoadService } from '../stats/muscle-load.service';
import { StatsService } from '../stats/stats.service';
import { SessionSynchronizer } from './utils/session-synchronizer';
import { UsersService } from '../users/users.service';
import { UserRole } from '../users/entities/user.entity';
import { FreeTrainingDefinition } from './entities/free-training-definition.entity';

@Injectable()
export class TrainingSessionsService {
  constructor(
    @InjectRepository(TrainingSession)
    private sessionRepo: Repository<TrainingSession>,
    @InjectRepository(SessionExercise)
    private sessionExerciseRepo: Repository<SessionExercise>,
    @InjectRepository(Plan)
    private planRepo: Repository<Plan>,
    @InjectRepository(StudentPlan)
    private studentPlanRepo: Repository<StudentPlan>,
    @InjectRepository(PlanExercise)
    private planExerciseRepo: Repository<PlanExercise>,
    @InjectRepository(Exercise)
    private exerciseRepo: Repository<Exercise>,
    @InjectRepository(FreeTrainingDefinition)
    private freeTrainingRepo: Repository<FreeTrainingDefinition>,
    private readonly muscleLoadService: MuscleLoadService,
    private readonly statsService: StatsService,
    private readonly usersService: UsersService,
  ) { }

  // 1. Start or Resume Session
  async startSession(
    userId: string,
    planId: string | null, // Nullable for free sessions
    weekNumber?: number,
    dayOrder?: number,
    date?: string, // YYYY-MM-DD
    freeTrainingId?: string,
  ): Promise<TrainingSession> {
    try {
      const finalDate = date || new Date().toISOString().split('T')[0];

      // Case A: Plan-based Session
      if (planId) {
        if (!weekNumber || !dayOrder) throw new ConflictException('Week and Day required for Plan sessions');

        const dayKey = `W${weekNumber}-D${dayOrder}`;

        const existingInProgress = await this.sessionRepo.findOne({
          where: {
            student: { id: userId },
            plan: { id: planId },
            dayKey: dayKey,
            date: finalDate,
            status: ExecutionStatus.IN_PROGRESS,
          },
          relations: [
            'plan',
            'exercises',
            'exercises.exercise',
            'exercises.exercise.exerciseMuscles',
            'exercises.exercise.exerciseMuscles.muscle',
          ],
        });

        if (existingInProgress) {
          return this._syncSnapshots(existingInProgress);
        }

        // Create NEW Plan Session
        const plan = await this.planRepo.findOne({
          where: { id: planId },
          relations: [
            'weeks',
            'weeks.days',
            'weeks.days.exercises',
            'weeks.days.exercises.exercise',
            'weeks.days.exercises.equipments',
          ],
        });
        if (!plan) throw new NotFoundException('Plan not found');

        const week = plan.weeks.find((w) => w.weekNumber === weekNumber);
        if (!week) throw new NotFoundException(`Week ${weekNumber} not found`);

        const day = week.days.find((d) => d.order === dayOrder);
        if (!day) throw new NotFoundException(`Day ${dayOrder} not found`);

        const newSession = this.sessionRepo.create({
          student: { id: userId } as User,
          plan: { id: planId } as Plan,
          date: finalDate,
          dayKey: dayKey,
          weekNumber,
          dayOrder,
          source: 'PLAN',
          status: ExecutionStatus.IN_PROGRESS,
          exercises: [],
        });

        // Create SessionExercises with Snapshots
        const sessionExercises: SessionExercise[] = day.exercises.map(
          (planEx) => {
            return this.sessionExerciseRepo.create({
              planExerciseId: planEx.id,
              exercise: planEx.exercise,
              // SNAPSHOTS
              exerciseNameSnapshot: planEx.exercise.name,
              targetSetsSnapshot: planEx.sets,
              targetRepsSnapshot: planEx.reps,
              targetWeightSnapshot: planEx.suggestedLoad,
              // If Body Weight, pre-fill addedWeight from plan load (interpreted as lastre)
              addedWeight: (planEx.exercise.equipments?.some(e => e.isBodyWeight) || planEx.equipments?.some(e => e.isBodyWeight))
                && planEx.suggestedLoad
                ? parseFloat(planEx.suggestedLoad)
                : 0,
              targetTimeSnapshot: planEx.targetTime,
              targetDistanceSnapshot: planEx.targetDistance,
              videoUrl: planEx.videoUrl || planEx.exercise.videoUrl,
              equipmentsSnapshot: planEx.equipments,
              // DEFAULTS
              order: planEx.order,
              isCompleted: false,
            });
          },
        );

        newSession.exercises = sessionExercises;
        await this.sessionRepo.save(newSession);

        const reloaded = await this.findOne(newSession.id);
        if (!reloaded) throw new NotFoundException('Error creating session');
        return reloaded;

      } else if (freeTrainingId) {
        // Case B: Free Training Session

        // 1. Check for existing IN_PROGRESS for this FreeTraining today? 
        // Actually, user might want to repeat? But let's check to avoid dupes on accidental clicks.
        const existingFree = await this.sessionRepo.findOne({
          where: {
            student: { id: userId },
            freeTrainingDefinition: { id: freeTrainingId }, // Check relation
            date: finalDate,
            status: ExecutionStatus.IN_PROGRESS,
            source: 'FREE'
          },
          relations: [
            'freeTrainingDefinition',
            'exercises',
            'exercises.exercise',
          ],
        });

        if (existingFree) {
          const loaded = await this.findOne(existingFree.id);
          if (!loaded) throw new NotFoundException('Session not found');
          return loaded;
        }

        // 2. Load Definition
        const freeDef = await this.freeTrainingRepo.findOne({
          where: { id: freeTrainingId },
          relations: ['exercises', 'exercises.exercise', 'exercises.equipments'] // Load deeply
        });
        if (!freeDef) throw new NotFoundException('Free Training Definition not found');

        // 3. Create Session
        const newSession = this.sessionRepo.create({
          student: { id: userId },
          plan: null,
          freeTrainingDefinition: freeDef,
          date: finalDate,
          dayKey: null,
          weekNumber: null,
          dayOrder: null,
          source: 'FREE',
          status: ExecutionStatus.IN_PROGRESS,
          exercises: [],
        } as any) as unknown as TrainingSession;

        // 4. Snapshot Exercises
        // Map from FreeTrainingDefinitionExercise -> SessionExercise
        // Notes: ftEx doesn't have targetTime/Distance usually unless we add them to entity. Assuming Reps based for now.
        const sessionExercises: SessionExercise[] = freeDef.exercises.map((ftEx) => {
          return this.sessionExerciseRepo.create({
            exercise: ftEx.exercise,
            exerciseNameSnapshot: ftEx.exercise.name,
            targetSetsSnapshot: ftEx.sets || ftEx.exercise.defaultSets || 3,
            targetRepsSnapshot: ftEx.reps || '10',
            targetWeightSnapshot: ftEx.suggestedLoad,
            addedWeight: 0,
            videoUrl: ftEx.videoUrl || ftEx.exercise.videoUrl,
            equipmentsSnapshot: ftEx.equipments ?? [],
            order: ftEx.order,
            isCompleted: false,
            // TODO: If we add time/distance to FT Def, map here.
          });
        });

        newSession.exercises = sessionExercises;
        await this.sessionRepo.save(newSession);

        const reloaded = await this.findOne(newSession.id);
        if (!reloaded) throw new NotFoundException('Error creating session');
        return reloaded;

      } else {
        throw new BadRequestException('Either planId or freeTrainingId must be provided');
      }

    } catch (e) {
      console.error('Error starting session:', e);
      throw e;
    }
  }

  // 2. Update Session Exercise
  async updateExercise(
    exerciseId: string,
    updateData: Partial<SessionExercise>,
  ): Promise<SessionExercise> {
    const sessionEx = await this.sessionExerciseRepo.findOne({
      where: { id: exerciseId },
      relations: ['session', 'exercise', 'exercise.equipments', 'equipmentsSnapshot'],
    });

    if (!sessionEx)
      throw new NotFoundException('Session exercise not found');

    // Auto-fill actuals
    if (updateData.isCompleted === true) {
      if (!sessionEx.setsDone || sessionEx.setsDone === '0') {
        sessionEx.setsDone = (sessionEx.targetSetsSnapshot ?? 0).toString();
      }
      if (!sessionEx.repsDone) {
        sessionEx.repsDone = sessionEx.targetRepsSnapshot ?? '';
      }

      // WEIGHT LOGIC: Check if it's Body Weight
      const isBodyWeight = sessionEx.exercise?.equipments?.some(e => e.isBodyWeight)
        || sessionEx.equipmentsSnapshot?.some(e => e.isBodyWeight);

      if (isBodyWeight) {
        // Fetch User Weight
        const sessionWithUser = await this.sessionRepo.findOne({
          where: { id: sessionEx.session.id },
          relations: ['student'],
        });
        const currentWeight = sessionWithUser?.student?.currentWeight || sessionWithUser?.student?.initialWeight || 0;
        const addedWeight = updateData.addedWeight || sessionEx.addedWeight || 0;

        // Total Load = Body + Added
        sessionEx.weightUsed = (currentWeight + addedWeight).toString();
        // Ensure addedWeight is saved
        if (updateData.addedWeight !== undefined) sessionEx.addedWeight = updateData.addedWeight;
      } else {
        // Standard Logic
        if (!sessionEx.weightUsed) {
          sessionEx.weightUsed = sessionEx.targetWeightSnapshot ?? '';
        }
      }
    }


    // Protect weightUsed from overwrite for Body Weight exercises
    // The backend calculation above should determine the final value.
    if (sessionEx.exercise?.equipments?.some(e => e.isBodyWeight) || sessionEx.equipmentsSnapshot?.some(e => e.isBodyWeight)) {
      delete updateData.weightUsed;
    }

    Object.assign(sessionEx, updateData);

    const savedEx = await this.sessionExerciseRepo.save(sessionEx);

    // If uncompleting, check if we need to downgrade Session status
    if (updateData.isCompleted === false) {
      // Logic to uncomplete session if it was completed?
      // For now, simple logic:
      const fullEx = await this.sessionExerciseRepo.findOne({
        where: { id: exerciseId },
        relations: ['session'],
      });
      if (fullEx && fullEx.session && fullEx.session.status === ExecutionStatus.COMPLETED) {
        fullEx.session.status = ExecutionStatus.IN_PROGRESS;
        fullEx.session.finishedAt = null;
        await this.sessionRepo.save(fullEx.session);
      }
    }

    // Sync Load
    if (updateData.isCompleted !== undefined) {
      if (sessionEx.session) { // if loaded
        await this._trySyncLoad(sessionEx.session.id);
      } else {
        // reload
        const fresh = await this.sessionExerciseRepo.findOne({ where: { id: exerciseId }, relations: ['session'] });
        if (fresh && fresh.session) await this._trySyncLoad(fresh.session.id);
      }
    }

    return savedEx;
  }

  private async _trySyncLoad(sessionId: string) {
    const fullSession = await this.sessionRepo.findOne({
      where: { id: sessionId },
      relations: ['exercises', 'exercises.exercise', 'student'],
    });
    if (fullSession) {
      // Cast to any if muscleLoadService expects PlanExecution but structure is compatible
      await this.muscleLoadService.syncExecutionLoad(fullSession as any);
    }
  }

  // 3. Complete Session
  async completeSession(
    sessionId: string,
    userId: string,
    finalDate: string,
  ): Promise<TrainingSession> {
    const session = await this.sessionRepo.findOne({
      where: { id: sessionId, student: { id: userId } },
      relations: ['plan'],
    });
    if (!session) throw new NotFoundException('Session not found');

    // REMOVED: Conflict Check (Allow multiple sessions per day)

    session.date = finalDate;
    session.status = ExecutionStatus.COMPLETED;
    session.finishedAt = new Date();

    const saved = await this.sessionRepo.save(session);

    // Sync Muscle Load
    await this._trySyncLoad(saved.id);

    // LEGACY SYNC (Deprecated)
    // We keep it ONLY if linked to a plan, for backward compat with StudentPlan.progress
    if (session.plan) {
      const studentPlan = await this.studentPlanRepo.findOne({
        where: {
          student: { id: userId },
          plan: { id: session.plan.id },
          isActive: true
        },
        order: { createdAt: 'DESC' }
      });

      if (studentPlan) {
        // Simplified Legacy Sync: just mark day as done
        const planStruct = await this.planRepo.findOne({
          where: { id: session.plan.id },
          relations: ['weeks', 'weeks.days'],
        });

        if (planStruct && session.weekNumber && session.dayOrder) {
          const week = planStruct.weeks.find(w => w.weekNumber === session.weekNumber);
          const day = week?.days.find(d => d.order === session.dayOrder);

          if (day) {
            const progress = studentPlan.progress ? JSON.parse(JSON.stringify(studentPlan.progress)) : {};
            if (!progress['days']) progress['days'] = {};
            progress['days'][day.id] = { completed: true, date: finalDate };
            studentPlan.progress = progress;
            await this.studentPlanRepo.save(studentPlan);
          }
        }
      }
    }

    // Update Stats
    await this.statsService.updateStats(userId);

    return saved;
  }

  // 4. Get Calendar
  async getCalendar(
    userId: string,
    from: string,
    to: string,
  ): Promise<TrainingSession[]> {
    return this.sessionRepo.find({
      where: {
        student: { id: userId },
        date: Between(from, to),
        status: ExecutionStatus.COMPLETED,
      },
      relations: [
        'plan',
        'exercises',
        'exercises.exercise',
        'exercises.exercise.exerciseMuscles',
        'exercises.exercise.exerciseMuscles.muscle',
      ],
      order: { date: 'ASC' },
    });
  }

  async findOne(id: string): Promise<TrainingSession | null> {
    const session = await this.sessionRepo.findOne({
      where: { id },
      relations: [
        'exercises',
        'exercises.exercise',
        'exercises.exercise.exerciseMuscles',
        'exercises.exercise.exerciseMuscles.muscle',
        'plan',
      ],
    });

    if (!session) return null;
    return this._syncSnapshots(session);
  }

  async findSessionByStructure(
    userId: string,
    planId: string,
    weekNumber: number,
    dayOrder: number,
    startDate?: string,
  ): Promise<TrainingSession | null> {
    try {
      const whereClause: any = {
        student: { id: userId },
        plan: { id: planId },
        weekNumber: weekNumber,
        dayOrder: dayOrder,
      };

      if (startDate) {
        whereClause.date = MoreThanOrEqual(startDate);
      }

      const session = await this.sessionRepo.findOne({
        where: whereClause,
        order: { createdAt: 'DESC' },
        relations: [
          'exercises',
          'exercises.exercise',
          'exercises.exercise.exerciseMuscles',
          'exercises.exercise.exerciseMuscles.muscle',
          'plan', // Ensure plan is loaded for sync
        ],
      });

      if (!session) return null;
      return this._syncSnapshots(session);
    } catch (e) {
      console.error('Error finding session by structure:', e);
      throw e;
    }
  }

  private async _syncSnapshots(
    session: TrainingSession,
  ): Promise<TrainingSession> {
    try {
      if (!session.plan || !session.weekNumber || !session.dayOrder) {
        return session;
      }

      // 1. Fetch Definitive Plan Day Structure
      const plan = await this.planRepo.findOne({
        where: { id: session.plan.id },
        relations: [
          'weeks',
          'weeks.days',
          'weeks.days.exercises',
          'weeks.days.exercises.exercise',
          'weeks.days.exercises.equipments',
        ],
      });

      if (!plan) return session;

      const week = plan.weeks.find((w) => w.weekNumber === session.weekNumber);
      const day = week?.days.find((d) => d.order === session.dayOrder);

      if (!day) return session;

      // 2. Delegate Logic to Pure Class
      const diff = SessionSynchronizer.calculateDiff(session, day);

      if (diff.hasChanges) {
        // A. Remove Deleted
        if (diff.toDelete.length > 0) {
          await this.sessionExerciseRepo.remove(diff.toDelete);
        }

        // B. Create New
        if (diff.toCreate.length > 0) {
          const newEntities = diff.toCreate.map((partial) => {
            const entity = this.sessionExerciseRepo.create(partial);
            entity.session = session;
            return entity;
          });
          await this.sessionExerciseRepo.save(newEntities);
        }

        // C. Update Existing
        if (diff.toUpdate.length > 0) {
          await this.sessionExerciseRepo.save(diff.toUpdate);
        }

        // D. Reload Session Exercises to ensure consistency
        const freshExercises = await this.sessionExerciseRepo.find({
          where: { session: { id: session.id } },
          relations: [
            'exercise',
            'exercise.exerciseMuscles',
            'exercise.exerciseMuscles.muscle',
          ],
          order: { order: 'ASC' },
        });
        session.exercises = freshExercises;
      }

      return session;
    } catch (e) {
      console.error('Error syncing snapshots:', e);
      throw e;
    }
  }

  async addSessionExercise(
    sessionId: string,
    exerciseId: string,
    settings: { sets?: number; reps?: string; weight?: string },
  ) {
    const session = await this.sessionRepo.findOne({
      where: { id: sessionId },
      relations: ['exercises'],
    });
    if (!session) throw new NotFoundException('Session not found');

    const exercise = await this.exerciseRepo.findOne({
      where: { id: exerciseId },
      relations: ['exerciseMuscles', 'exerciseMuscles.muscle', 'equipments'],
    });
    if (!exercise) throw new NotFoundException('Exercise not found');

    const newExercise = this.sessionExerciseRepo.create({
      session,
      exercise,
      exerciseNameSnapshot: exercise.name,
      targetSetsSnapshot: settings.sets || exercise.defaultSets || 3,
      targetRepsSnapshot: settings.reps || '10-12',
      targetWeightSnapshot: settings.weight,
      addedWeight: (exercise.equipments?.some(e => e.isBodyWeight) && settings.weight)
        ? parseFloat(settings.weight)
        : 0,
      equipmentsSnapshot: exercise.equipments,
      videoUrl: exercise.videoUrl,
      order: session.exercises.length + 1,
      isCompleted: false,
    });

    await this.sessionExerciseRepo.save(newExercise);
    return newExercise;
  }

  // 5. Delete Session Exercise
  async deleteSessionExercise(exerciseExecId: string, requester: any): Promise<void> {
    const sessionExercise = await this.sessionExerciseRepo.findOne({
      where: { id: exerciseExecId },
      relations: ['session', 'session.student', 'session.student.gym', 'exercise'], // Include gym and exercise
    });

    if (!sessionExercise) {
      throw new NotFoundException('Session exercise not found');
    }

    const session = sessionExercise.session;
    const student = session.student;

    // --- SECURITY CHECK ---
    const requesterFull = await this.usersService.findOne(requester.id);
    if (!requesterFull) throw new ForbiddenException('User not found');

    const role = requesterFull.role;

    if (role === UserRole.SUPER_ADMIN) {
      // Allow all
    } else if (role === UserRole.ADMIN || role === UserRole.PROFE) {
      // Must be same gym
      if (requesterFull.gym?.id !== student.gym?.id) {
        throw new ForbiddenException('You can only manage sessions for students in your Gym');
      }
    } else {
      // Student
      if (requesterFull.id !== student.id) {
        throw new ForbiddenException('You cannot manage other students sessions');
      }

      // Business Rule: Student CANNOT delete assigned exercises (from Plan)
      if (sessionExercise.planExerciseId) {
        throw new ForbiddenException('No puedes borrar ejercicios asignados por tu plan');
      }
    }

    await this.sessionExerciseRepo.remove(sessionExercise);

    // Sync Load if it was part of a session
    if (sessionExercise.session) {
      await this._trySyncLoad(sessionExercise.session.id);
    }
  }
}
