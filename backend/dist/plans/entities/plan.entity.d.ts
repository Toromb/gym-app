import { User } from '../../users/entities/user.entity';
import { Exercise } from '../../exercises/entities/exercise.entity';
import { PlanWeek } from './plan-week.entity';
export declare class Plan {
    id: string;
    name: string;
    description: string;
    objective?: string;
    generalNotes?: string;
    teacher: User;
    startDate: string;
    durationWeeks: number;
    isTemplate: boolean;
    weeks: PlanWeek[];
    createdAt: Date;
    updatedAt: Date;
}
export declare class PlanDay {
    id: string;
    week: PlanWeek;
    title?: string;
    dayOfWeek: number;
    order: number;
    dayNotes?: string;
    exercises: PlanExercise[];
}
export declare class PlanExercise {
    id: string;
    day: PlanDay;
    exercise: Exercise;
    sets?: number;
    reps?: string;
    suggestedLoad?: string;
    rest?: string;
    notes?: string;
    videoUrl?: string;
    order: number;
}
