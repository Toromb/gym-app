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

        if (ledgerEntries.length > 0) {
            await manager.save(MuscleLoadLedger, ledgerEntries);
        }
    }

    /**
     * Retrieves the current load state for all muscles of a student.
     * Applies recovery logic up to targetDate (default: today).
     */
    async getLoadsForStudent(studentId: string, targetDateStr?: string): Promise<any> {
        const targetDate = targetDateStr ? new Date(targetDateStr) : new Date();
        // Normalize to YYYY-MM-DD for consistency
        const targetDateIso = targetDate.toISOString().split('T')[0];

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

            // Default Initial State
            let currentLoad = currentState ? currentState.currentLoad : 0;
            let lastDate = currentState ? new Date(currentState.lastComputedDate) : new Date(targetDateIso);
            // If no state, we assume fresh 0 from targetDate effectively, 
            // BUT for calculation correctness if there are ledger entries, we should look back?
            // MVP Strategy: If no state, we assume 0 load at targetDate unless we want to rebuild from history.
            // Rebuilding from eternity is expensive.
            // Simplification: If no state, calculate from start of time or just 0?
            // Better: If no state, try to find ANY ledger entry. If none, it's 0.

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

            // 4. Fetch NEW Stimulus from Ledger (since lastComputedDate + 1 day)
            // If no state, we need to fetch all history? Or just assume 0.
            // Risk: If user has many ledger entries but never checked muscle-loads, state is empty.
            // Solution: If state is missing, look back 30 days? Or just query ALL ledger entries <= targetDate if usage is low.
            // Let's query Ledger entries > lastComputedDate AND <= targetDate.

            let queryDateStart = currentState ? new Date(currentState.lastComputedDate) : new Date('2020-01-01');
            // We want strictly greater than last computed date, because last computed included that date.
            // Wait, if I computed yesterday, I want events from TODAY onwards.

            // If state doesn't exist, query all history (or capped).

            const ledgerEvents = await this.ledgerRepo.find({
                where: {
                    student: { id: studentId },
                    muscle: { id: muscle.id },
                    date: Between(
                        this.addDays(queryDateStart, 1).toISOString().split('T')[0],
                        targetDateIso
                    )
                }
            });

            // Sum Deltas
            let sumDelta = 0;
            for (const event of ledgerEvents) {
                sumDelta += event.deltaLoad;
            }

            // Apply Recovery for the gaps between events?
            // COMPLEXITY simplified:
            // The simple algorithm proposed:
            // 1. Recover from LastDate to TargetDate (full span)
            // 2. Add SumDelta (from that span)
            // This is an APPROXIMATION. It assumes all load happened at the END or doesn't matter?
            // User Spec: "3) Aplicar recuperación... 4) Traer ledger SUM... 5) Aplicar estímulo"
            // This aligns with the approximation. Recover first, then add load.
            // Issue: If I rested 10 days then trained today, I recover 10 days then add load. Correct.
            // Issue: If I trained 10 days ago then rested, I add load then recover? 
            // The proposed Algo: Recover currentLoad (old) by days. Then Add new loads.
            // This implicitly assumes new loads are "fresh".
            // Correct Logic for precise timeline:
            // We should ideally iterate day by day.
            // BUT for MVP based on spec:
            // "3) Apply recovery (daysPassed * RECOVERY) -> 4) Add Ledger Sum"
            // This implies NEW loads are not decayed immediately.

            currentLoad = Math.min(this.MAX_LOAD, Math.max(0, currentLoad + sumDelta));

            // 6. Update State (Materialize)
            // We only update if we are querying for "Today" or future, usually.
            // Or we always update checking user.
            // Optimization: Update state so next query is fast.

            const newState = new MuscleLoadState();
            newState.student = { id: studentId } as any;
            newState.muscle = { id: muscle.id } as any;
            newState.currentLoad = currentLoad;
            newState.lastComputedDate = targetDateIso;

            newStates.push(newState);

            result.push({
                muscleId: muscle.id,
                name: muscle.name,
                region: muscle.region,
                load: currentLoad,
                status: this.getStatus(currentLoad)
            });
        }

        // Batch Save
        if (newStates.length > 0) {
            await this.stateRepo.save(newStates);
        }

        return {
            date: targetDateIso,
            muscles: result
        };
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
