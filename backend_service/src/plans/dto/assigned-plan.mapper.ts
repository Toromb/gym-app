import { StudentPlan } from '../entities/student-plan.entity';
import { AssignedPlan } from '../entities/assigned-plan.entity';

export class AssignedPlanMapper {
  /**
   * Maps a StudentPlan preserving the structure expected by the frontend.
   * Replaces the internal `plan` variable with `assignedPlan` formatted as a native Plan.
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
