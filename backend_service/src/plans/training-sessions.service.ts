import {
  Injectable,
  NotFoundException,
  ConflictException,
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
    private readonly muscleLoadService: MuscleLoadService,
    private readonly statsService: StatsService,
  ) { }

  // 1. Start or Resume Session
  async startSession(
    userId: string,
    planId: string | null, // Nullable for free sessions
    weekNumber?: number,
    dayOrder?: number,
    date?: string, // YYYY-MM-DD
  ): Promise<TrainingSession> {
    try {
      const finalDate = date || new Date().toISOString().split('T')[0];

      // Case A: Plan-based Session
      if (planId) {
        if (!weekNumber || !dayOrder) throw new ConflictException('Week and Day required for Plan sessions');

        const dayKey = `W${weekNumber}-D${dayOrder}`;

        // Check if there is an IN_PROGRESS session to resume
        // We allow multiple COMPLETED sessions, but only one IN_PROGRESS per dayKey usually?
        // Or just resume the latest one if it's today? 
        // Let's resume any IN_PROGRESS session for this day/plan to avoid abandonment spam.
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

        // Reload to ensure relations
        const reloaded = await this.findOne(newSession.id);
        if (!reloaded) throw new NotFoundException('Error creating session');
        return reloaded;

      } else {
        // Case B: Free Session (No Plan)
        // TODO: Logic for Free Session (Create empty session, allow user to add exercises)
        // For now, we return empty session.
        const newSession = this.sessionRepo.create({
          student: { id: userId } as User,
          plan: null,
          date: finalDate,
          source: 'FREE',
          status: ExecutionStatus.IN_PROGRESS,
          exercises: [],
        });

        await this.sessionRepo.save(newSession);
        return newSession;
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
      if (!sessionEx.weightUsed) {
        sessionEx.weightUsed = sessionEx.targetWeightSnapshot ?? '';
      }
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

    // TODO: Call StatsService.updateStats(userId) here

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
        relations: ['weeks', 'weeks.days', 'weeks.days.exercises', 'weeks.days.exercises.exercise', 'weeks.days.exercises.equipments']
      });

      if (!plan) return session;

      const week = plan.weeks.find(w => w.weekNumber === session.weekNumber);
      const day = week?.days.find(d => d.order === session.dayOrder);

      if (!day) return session;

      let updatesNeeded = false;
      const isCompleted = session.status === ExecutionStatus.COMPLETED;

      // 2. Map existing SessionExercises by PlanExerciseId for quick lookup
      const existingSessionExMap = new Map<string, SessionExercise>();
      const sessionExToRemove: SessionExercise[] = [];

      session.exercises.forEach(ex => {
        if (ex.planExerciseId) {
          existingSessionExMap.set(ex.planExerciseId, ex);
        } else {
          // Keep exercises without plan ID (e.g. manually added extras)
        }
      });

      // 3. Structural Sync: Identify New & Existing
      const mergedExercises: SessionExercise[] = [];

      // Tracks which session exercises are "kept" (matched to plan)
      const matchedSessionExIds = new Set<string>();

      for (const planEx of day.exercises) {
        let sessionEx = existingSessionExMap.get(planEx.id);

        if (sessionEx) {
          // --- EXISTING: Update Values ---
          matchedSessionExIds.add(sessionEx.id);

          if (!sessionEx.videoUrl && planEx.videoUrl) {
            sessionEx.videoUrl = planEx.videoUrl;
            updatesNeeded = true;
          }

          const exEquipments = sessionEx.equipmentsSnapshot || [];
          const planEquipments = planEx.equipments || [];
          const exIds = exEquipments.map(e => e.id).sort().join(',');
          const planIds = planEquipments.map(e => e.id).sort().join(',');

          if (exIds !== planIds) {
            sessionEx.equipmentsSnapshot = planEquipments;
            updatesNeeded = true;
          }

          if (!isCompleted) {
            const snapSets = Number(sessionEx.targetSetsSnapshot);
            const planSets = Number(planEx.sets);

            if (
              snapSets !== planSets ||
              String(sessionEx.targetRepsSnapshot) !== String(planEx.reps) ||
              String(sessionEx.targetWeightSnapshot) !== String(planEx.suggestedLoad)
            ) {

              sessionEx.targetSetsSnapshot = planSets;
              sessionEx.targetRepsSnapshot = planEx.reps;
              sessionEx.targetWeightSnapshot = planEx.suggestedLoad;
              updatesNeeded = true;
            }

            // Also Update Order
            if (sessionEx.order !== planEx.order) {
              sessionEx.order = planEx.order;
              updatesNeeded = true;
            }
          }
          mergedExercises.push(sessionEx);

        } else {
          // --- NEW: Create ---

          const newEx = this.sessionExerciseRepo.create({
            session: session, // Important to link
            planExerciseId: planEx.id,
            exercise: planEx.exercise,
            exerciseNameSnapshot: planEx.exercise.name,
            targetSetsSnapshot: planEx.sets,
            targetRepsSnapshot: planEx.reps,
            targetWeightSnapshot: planEx.suggestedLoad,
            videoUrl: planEx.videoUrl || planEx.exercise.videoUrl,
            equipmentsSnapshot: planEx.equipments,
            order: planEx.order,
            isCompleted: false,
          });
          // We need to save it to generate ID or just return it? 
          // Better to save it later in batch? 
          // session.exercises array needs to have it.
          mergedExercises.push(newEx);
          updatesNeeded = true;
        }
      }

      // 4. Identify Removed (Orphans)
      // Only remove if it HAS a planExerciseId but that ID is no longer in the day.
      session.exercises.forEach(ex => {
        if (ex.planExerciseId && !existingSessionExMap.has(ex.planExerciseId) && !matchedSessionExIds.has(ex.id)) {
          // Wait, logic check:
          // If ex has planExerciseId, we looked it up in existingSessionExMap.
          // If it was in the map, we iterated it in the plan loop? 
          // No, the map is session->plan lookup.
          // We iterated PLAN. If plan had it, we marked matchedSessionExIds.
          // IF ex has planExerciseId AND is NOT in matchedSessionExIds, it means it's not in the Plan Day anymore.
          // REMOVE IT.
        }
      });

      // Re-construct session.exercises preserving "extras" (manual)
      const finalExercises: SessionExercise[] = [];

      // 4a. Add Matched (Existing & New)
      finalExercises.push(...mergedExercises);

      // 4b. Add Manual Extras (No planExerciseId)
      session.exercises.forEach(ex => {
        if (!ex.planExerciseId) {
          finalExercises.push(ex);
        } else if (!matchedSessionExIds.has(ex.id)) {
          // It has an ID but wasn't matched -> It was DELETED from Plan.
          // We should delete it from DB or mark removed?
          // For now, let's remove it from the list (which implicitly deletes if cascade? No).
          // We must explicitly delete.
          if (!isCompleted) {

            sessionExToRemove.push(ex);
            updatesNeeded = true;
          } else {
            // If completed, maybe keep it but flag it? 
            finalExercises.push(ex); // Keep history
          }
        }
      });

      if (updatesNeeded) {
        // Sort by order
        finalExercises.sort((a, b) => (a.order || 0) - (b.order || 0));

        // SAVE Changes
        // 1. Remove deleted
        if (sessionExToRemove.length > 0) {
          await this.sessionExerciseRepo.remove(sessionExToRemove);
        }

        // 2. Save Updates/New
        // We link them to session just in case
        finalExercises.forEach(e => e.session = session);
        await this.sessionExerciseRepo.save(finalExercises);

        // 3. Update Session object
        session.exercises = finalExercises;
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
      equipmentsSnapshot: exercise.equipments,
      videoUrl: exercise.videoUrl,
      order: session.exercises.length + 1,
      isCompleted: false,
    });

    await this.sessionExerciseRepo.save(newExercise);
    return newExercise;
  }
}
