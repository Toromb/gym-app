import { TrainingSession, ExecutionStatus } from '../entities/training-session.entity';
import { PlanDay } from '../entities/plan.entity';
import { SessionExercise } from '../entities/session-exercise.entity';

export interface SyncResult {
    toCreate: Partial<SessionExercise>[];
    toUpdate: SessionExercise[];
    toDelete: SessionExercise[];
    hasChanges: boolean;
}

export class SessionSynchronizer {
    static calculateDiff(
        session: TrainingSession,
        day: PlanDay,
    ): SyncResult {
        const isCompleted = session.status === ExecutionStatus.COMPLETED;
        const toCreate: Partial<SessionExercise>[] = [];
        const toUpdate: SessionExercise[] = [];
        const toDelete: SessionExercise[] = [];

        // Quick Lookup for Existing Session Exercises by PlanExerciseID
        // Map<planExerciseId, SessionExercise>
        const existingSessionExMap = new Map<string, SessionExercise>();

        session.exercises.forEach((ex) => {
            if (ex.planExerciseId) {
                existingSessionExMap.set(ex.planExerciseId, ex);
            }
        });

        // Track matched IDs to identify orphans (deletions) later
        const matchedSessionExIds = new Set<string>();

        // 1. ITERATE PLAN: Identify Creates & Updates
        for (const planEx of day.exercises) {
            const sessionEx = existingSessionExMap.get(planEx.id);

            if (sessionEx) {
                // --- MATCH FOUND: Check for Updates ---
                matchedSessionExIds.add(sessionEx.id);
                let updated = false;

                // Video URL Update
                if (!sessionEx.videoUrl && planEx.videoUrl) {
                    sessionEx.videoUrl = planEx.videoUrl;
                    updated = true;
                }

                // Equipment Sync
                const exEquipments = sessionEx.equipmentsSnapshot || [];
                const planEquipments = planEx.equipments || [];
                // Simple ID-based comparison
                const exIds = exEquipments.map(e => e.id).sort().join(',');
                const planIds = planEquipments.map(e => e.id).sort().join(',');

                if (exIds !== planIds) {
                    sessionEx.equipmentsSnapshot = planEquipments;
                    updated = true;
                }

                // Snapshot Updates (Sets, Reps, Weight) - ONLY if Not Completed
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
                        updated = true;
                    }

                    // Order Update
                    if (sessionEx.order !== planEx.order) {
                        sessionEx.order = planEx.order;
                        updated = true;
                    }
                }

                if (updated) {
                    toUpdate.push(sessionEx);
                }

            } else {
                // --- NO MATCH: New Exercise in Plan -> Create in Session ---
                toCreate.push({
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
                    // Link to session is handled by the caller or typeorm structure, 
                    // but usually we pass the parent or let the repo handle it. 
                    // We will let the service assign 'session' if needed, or pass it here.
                    session: session,
                });
            }
        }

        // 2. ITERATE SESSION: Identify Deletions (Orphans)
        session.exercises.forEach((ex) => {
            // If it has a plan ID (was part of plan) BUT wasn't matched in the loop above
            if (ex.planExerciseId && !matchedSessionExIds.has(ex.id)) {

                // If session is completed, we generally preserve history, so NO delete.
                if (!isCompleted) {
                    toDelete.push(ex);
                }
            }
            // If !ex.planExerciseId -> It's a manual extra exercise -> KEEP IT (Do nothing)
        });

        return {
            toCreate,
            toUpdate,
            toDelete,
            hasChanges: toCreate.length > 0 || toUpdate.length > 0 || toDelete.length > 0,
        };
    }
}
