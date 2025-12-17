import { PlanExecution } from './plan-execution.entity';
import { Exercise } from '../../exercises/entities/exercise.entity';
export declare class ExerciseExecution {
    id: string;
    execution: PlanExecution;
    planExerciseId: string;
    exercise: Exercise;
    exerciseNameSnapshot: string;
    targetSetsSnapshot: number;
    targetRepsSnapshot: string;
    targetWeightSnapshot: string;
    videoUrl: string;
    isCompleted: boolean;
    setsDone: number;
    repsDone: string;
    weightUsed: string;
    timeSpent: string;
    notes: string;
    order: number;
}
