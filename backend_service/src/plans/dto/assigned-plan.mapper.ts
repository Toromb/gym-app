import { StudentPlan } from '../entities/student-plan.entity';
import { AssignedPlan } from '../entities/assigned-plan.entity';

/**
 * Translates the internal snapshot model into the shape the frontend expects.
 *
 * ## Why this exists
 * The frontend was built against a simple `{ plan: PlanDto }` structure in each
 * StudentPlan response. When we introduced the AssignedPlan snapshot system
 * (Phase 1), rather than changing every Flutter model and screen, the mapper
 * intercepts the response and *presents* the AssignedPlan as if it were the
 * original plan — keeping the API surface stable.
 *
 * ## Contract
 *  - `toResponseDto` must be called on every StudentPlan before sending it to
 *    the client. It replaces `assignedPlan` with a `plan` field (formatted via
 *    `assignedPlanToPlanDto`) and removes the raw `assignedPlan` key.
 *  - If `assignedPlan` is null (legacy record), the original `plan` FK is left
 *    untouched as a fallback.
 *
 * ## Important
 * The `id` returned inside `plan` is the AssignedPlan UUID, NOT the master
 * Plan UUID. The frontend uses this ID to call startSession(), which the backend
 * resolves by looking up AssignedPlan first. See TrainingSessionsService.
 */
export class AssignedPlanMapper {
  /**
   * Maps a StudentPlan preserving the structure expected by the frontend.
   * Replaces the internal `assignedPlan` with a `plan` formatted as a native Plan.
   */
  static toResponseDto(studentPlan: StudentPlan): any {
    const rawDto = { ...studentPlan };
    
    if (studentPlan.assignedPlan) {
      rawDto.plan = AssignedPlanMapper.assignedPlanToPlanDto(studentPlan.assignedPlan);
      // Remove assignedPlan key to avoid cluttering the response and ensure API compliance
      delete (rawDto as any).assignedPlan;
    }

    return rawDto;
  }

  static assignedPlanToPlanDto(assignedPlan: AssignedPlan): any {
    if (!assignedPlan) return null;

    return {
      id: assignedPlan.id,
      name: assignedPlan.name,
      description: assignedPlan.description,
      objective: assignedPlan.objective,
      generalNotes: assignedPlan.generalNotes,
      durationWeeks: assignedPlan.durationWeeks,
      startDate: assignedPlan.startDate,
      isTemplate: false, // snapshots are never templates
      originalPlanId: assignedPlan.originalPlanId,
      weeks: assignedPlan.weeks?.map((w) => ({
        id: w.id,
        weekNumber: w.weekNumber,
        days: w.days?.map((d) => ({
          id: d.id,
          title: d.title,
          dayOfWeek: d.dayOfWeek,
          order: d.order,
          trainingIntent: d.trainingIntent,
          dayNotes: d.dayNotes,
          exercises: d.exercises?.map((e) => ({
            id: e.id,
            sets: e.sets,
            reps: e.reps,
            suggestedLoad: e.suggestedLoad,
            rest: e.rest,
            notes: e.notes,
            videoUrl: e.videoUrl,
            targetTime: e.targetTime,
            targetDistance: e.targetDistance,
            order: e.order,
            exercise: e.exercise,
            equipments: e.equipments,
          })) || [],
        })) || [],
      })) || [],
      createdAt: assignedPlan.createdAt,
      updatedAt: assignedPlan.updatedAt,
    };
  }
}
