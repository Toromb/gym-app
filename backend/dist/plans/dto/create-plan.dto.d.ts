export declare class CreatePlanExerciseDto {
    exerciseId: string;
    sets: number;
    reps: string;
    suggestedLoad?: string;
    rest?: string;
    notes?: string;
    videoUrl?: string;
    order: number;
}
export declare class CreatePlanDayDto {
    title?: string;
    dayOfWeek: number;
    order: number;
    dayNotes?: string;
    exercises: CreatePlanExerciseDto[];
}
export declare class CreatePlanWeekDto {
    weekNumber: number;
    days: CreatePlanDayDto[];
}
export declare class CreatePlanDto {
    name: string;
    objective?: string;
    durationWeeks: number;
    generalNotes?: string;
    weeks: CreatePlanWeekDto[];
}
