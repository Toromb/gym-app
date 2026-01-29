import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, LessThanOrEqual } from 'typeorm';
import { MuscleLoadLedger } from './entities/muscle-load-ledger.entity';
import { MuscleLoadState } from './entities/muscle-load-state.entity';
import { TrainingSession } from '../plans/entities/training-session.entity';
import { ExerciseMuscle, MuscleRole } from '../exercises/entities/exercise-muscle.entity';
import { Muscle, MuscleRegion } from '../exercises/entities/muscle.entity';

@Injectable()
export class MuscleLoadService {
    private readonly logger = new Logger(MuscleLoadService.name);

    // --- CONFIG CONSTANTS ---
    private readonly STIMULUS_BY_ROLE = {
        [MuscleRole.PRIMARY]: 15,
        [MuscleRole.SECONDARY]: 8,
        [MuscleRole.STABILIZER]: 3,
    };
    private readonly RECOVERY_PER_DAY = 10;
    private readonly MAX_LOAD = 100;

    constructor(
        @InjectRepository(MuscleLoadLedger)
        private ledgerRepo: Repository<MuscleLoadLedger>,
        @InjectRepository(MuscleLoadState)
        private stateRepo: Repository<MuscleLoadState>,
        @InjectRepository(ExerciseMuscle)
        private exerciseMuscleRepo: Repository<ExerciseMuscle>,
        @InjectRepository(Muscle)
        private muscleRepo: Repository<Muscle>,
    ) { }

    /**
     * Syncs the muscle load impact of a specific TrainingSession.
     * - Calculates load based on completed exercises.
     * - Replaces existing ledger entries for this session (Idempotent).
     * - If session is NOT completed, clears the ledger (removes impact).
     */
    async syncExecutionLoad(
        session: TrainingSession,
        transactionalEntityManager?: any, // Optional for transactions
    ): Promise<void> {
        const manager = transactionalEntityManager || this.ledgerRepo.manager;

        // 1. Clear existing ledger for this session
        // Note: Ledger uses 'session' property which maps to 'planExecutionId' column in DB (if valid)
        // But wait, the Entity still has @JoinColumn({ name: 'planExecutionId' }) session: TrainingSession
        // So in Find/Delete we use 'session'.
        await manager.delete(MuscleLoadLedger, {
            session: { id: session.id },
        });

        // If not completed, we are done (load removed)
        this.logger.log(`[DEBUG] syncExecutionLoad: Session ${session.id} Status=${session.status}`);
        if (session.status !== 'COMPLETED') {
            return;
        }

        // 2. Identify Muscles & Calculate Delta
        // We need the ACTUAL exercises performed.
        const exerciseExecutions = session.exercises || [];

        const muscleDeltas = new Map<string, number>();

        for (const exExec of exerciseExecutions) {
            if (!exExec.isCompleted) continue;

            if (!exExec.exercise) {
                this.logger.warn(`Exercise not loaded for Session ${exExec.id}`);
                continue;
            }

            const mappings = await this.exerciseMuscleRepo.find({
                where: { exercise: { id: exExec.exercise.id } },
                relations: ['muscle'],
            });

            this.logger.log(`[DEBUG] Exercise ${exExec.exercise.name} (ID: ${exExec.exercise.id}) - Mappings found: ${mappings.length}`);

            for (const map of mappings) {
                const stimulus = this.STIMULUS_BY_ROLE[map.role] || 0;
                const current = muscleDeltas.get(map.muscle.id) || 0;
                muscleDeltas.set(map.muscle.id, current + stimulus);
            }
        }

        // 3. Insert new Ledger entries
        const ledgerEntries: MuscleLoadLedger[] = [];
        for (const [muscleId, delta] of muscleDeltas.entries()) {
            const entry = new MuscleLoadLedger();
            entry.student = { id: session.student.id } as any;
            entry.muscle = { id: muscleId } as any;
            entry.date = session.date;
            entry.deltaLoad = delta;
            entry.session = { id: session.id } as any; // Updated property

            ledgerEntries.push(entry);
        }

        this.logger.log(`[DEBUG] Saving ${ledgerEntries.length} ledger entries. Sample: ${JSON.stringify(ledgerEntries[0])}`);

        if (ledgerEntries.length > 0) {
            await manager.save(MuscleLoadLedger, ledgerEntries);
        }
    }

    /**
     * Retrieves the current load state for all muscles of a student.
     * Applies recovery logic up to targetDate (default: today).
     */
    async getLoadsForStudent(studentId: string): Promise<any> {
        try {
            const targetDate = new Date();
            targetDate.setHours(0, 0, 0, 0); // Normalize to Midnight to avoid intra-day recovery
            const targetDateIso = targetDate.toISOString().split('T')[0];

            this.logger.log(`[DEBUG] getLoadsForStudent: Student=${studentId}, TargetDate=${targetDateIso}`);
            const totalLedger = await this.ledgerRepo.count({ where: { student: { id: studentId } } });
            this.logger.log(`[DEBUG] Total Ledger Entries for Student: ${totalLedger}`);

            // 1. Get All Muscles (to ensure we return full body state)
            const allMuscles = await this.muscleRepo.find();

            // 2. Get Materialized State
            const states = await this.stateRepo.find({
                where: { student: { id: studentId } },
            });

            const result = [];
            const newStates: MuscleLoadState[] = [];

            for (const muscle of allMuscles) {
                let currentState = states.find((s) => s.muscleId === muscle.id);

                if (currentState && currentState.lastComputedDate === targetDateIso) {
                    // If the state is already "up to date" (Today), we must ignore it to force a re-calculation 
                    // from the ledger, effectively rebuilding "Today's" value from history/scratch.
                    // This is crucial for intra-day updates.
                    // this.logger.log(`[DEBUG] Ignoring Today's State for ${muscle.name}`);
                    currentState = undefined;
                }

                // Default Initial State
                let currentLoad = currentState ? currentState.currentLoad : 0;
                let lastDate = currentState ? new Date(currentState.lastComputedDate) : new Date(targetDateIso);

                // RECOVERY ALGORITHM
                if (currentState) {
                    // Calculate days passed since last computation
                    const diffTime = Math.abs(targetDate.getTime() - lastDate.getTime());
                    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

                    if (lastDate < targetDate) {
                        // Apply Recovery
                        const recovery = diffDays * this.RECOVERY_PER_DAY;
                        currentLoad = Math.max(0, currentLoad - recovery);
                    }
                }

                // 3. Apply Ledger Delta (New Workouts since last compute)
                // Query needs to be strictly AFTER lastComputedDate to avoid double counting?
                // Actually, ledger saves EXACT date. User might work out multiple times a day or backfill.
                // Safe logic: From (lastComputed + 1 day) TILL targetDate.
                // BUT if lastComputed is today (and we ignored it), we start from 2020.
                const queryDateStart = currentState ? new Date(currentState.lastComputedDate) : new Date('2020-01-01');
                // If currentState exists, we want NEXT day. If not, from beginning.
                if (currentState) queryDateStart.setDate(queryDateStart.getDate() + 1);

                const startStr = queryDateStart.toISOString().split('T')[0];

                // Only log for a specific muscle to reduce noise?
                if (muscle.name === 'Biceps' || muscle.name === 'Pecho') {
                    this.logger.log(`[DEBUG] Querying ${muscle.name} (${muscle.id}): ${startStr} to ${targetDateIso}`);
                }

                const ledgerEvents = await this.ledgerRepo.find({
                    where: {
                        student: { id: studentId },
                        muscle: { id: muscle.id },
                        date: Between(startStr, targetDateIso),
                    },
                    order: { date: 'ASC' } // Critical: Process in order
                });

                if (ledgerEvents.length > 0) {
                    this.logger.log(`[DEBUG] ${muscle.name}: Found ${ledgerEvents.length} events!`);
                }

                // SIMULATION LOGIC:
                // We must apply recovery between events to avoid massive accumulation from history.
                // Start simulation from: 'currentLoad' (from state) at 'lastDate' (from state)

                let simLoad = currentLoad;
                let simDate = lastDate; // This is either 'lastComputedDate' or '2020-01-01'

                // If starting from scratch (no state), ensure we don't carry garbage
                if (!currentState) {
                    simLoad = 0;
                    simDate = new Date('2020-01-01');
                }

                for (const ev of ledgerEvents) {
                    const eventDate = new Date(ev.date); // This is a string YYYY-MM-DD from DB usually, or Date object?
                    // TypeORM returns Date object for 'date' column type usually, or string if simple.
                    // Let's ensure it is a Date.

                    // Calculate days passed since last simulation point
                    const diffTime = Math.max(0, eventDate.getTime() - simDate.getTime());
                    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24)); // Floor to be safe on same-day

                    if (diffDays > 0) {
                        const recovery = diffDays * this.RECOVERY_PER_DAY;
                        simLoad = Math.max(0, simLoad - recovery);
                    }

                    // Apply Load
                    simLoad += ev.deltaLoad;

                    // Update simulation pointer
                    simDate = eventDate;
                }

                // Final Recovery: From last event (or start) to Target Date
                const targetDateUtc = new Date(targetDateIso);
                const finalDiffTime = Math.max(0, targetDateUtc.getTime() - simDate.getTime());
                const finalDiffDays = Math.ceil(finalDiffTime / (1000 * 60 * 60 * 24));

                if (finalDiffDays > 0) {
                    const recovery = finalDiffDays * this.RECOVERY_PER_DAY;
                    simLoad = Math.max(0, simLoad - recovery);
                }

                currentLoad = Math.min(this.MAX_LOAD, Math.max(0, simLoad));

                if (currentLoad > 0) {
                    this.logger.log(`[DEBUG] ${muscle.name}: FinalLoad=${currentLoad} (Simulated)`);
                }

                // 6. Update State (Materialize)
                // We only update if we are querying for "Today" or future, usually.
                // Or we always update checking user.
                // Optimization: Update state so next query is fast.

                const newState = new MuscleLoadState();
                // if (currentState) newState.id = currentState.id; // Removed: Composite Key used instead
                newState.student = { id: studentId } as any;
                newState.muscle = { id: muscle.id } as any;
                newState.currentLoad = currentLoad;
                newState.lastComputedDate = targetDateIso;

                newStates.push(newState);

                result.push({
                    muscleId: muscle.id,
                    muscleName: muscle.name,
                    load: currentLoad,
                    status: this.getStatus(currentLoad),
                    lastComputedDate: targetDateIso
                });
            } // End loop

            // Batch Save
            // We save if we have new states that differ from DB.
            const statesToSave = newStates.filter(ns => {
                const existing = states.find(s => s.muscleId === ns.muscle.id);
                if (!existing) return true; // New record
                // If date changed, we must save.
                if (existing.lastComputedDate !== ns.lastComputedDate) return true;
                // If load changed significantly (float comparison), we must save.
                if (Math.abs(existing.currentLoad - ns.currentLoad) > 0.01) return true;

                return false; // No change, skip write
            });

            if (statesToSave.length > 0) {
                this.logger.log(`[DEBUG] Saving ${statesToSave.length} updated muscle states`);
                await this.stateRepo.save(statesToSave);
            }

            return result;
        } catch (e) {
            this.logger.error(`[CRITICAL] Error in getLoadsForStudent: ${e.message}`, e.stack);
            throw e;
        }
    }

    private addDays(date: Date, days: number): Date {
        const result = new Date(date);
        result.setDate(result.getDate() + days);
        return result;
    }

    private getStatus(load: number): string {
        if (load >= 80) return 'OVERLOADED';
        if (load >= 50) return 'FATIGUED';
        if (load >= 20) return 'ACTIVE';
        return 'RECOVERED';
    }
}
