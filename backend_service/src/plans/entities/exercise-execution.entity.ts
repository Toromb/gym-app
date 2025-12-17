import { Entity, Column, PrimaryGeneratedColumn, ManyToOne } from 'typeorm';
import { PlanExecution } from './plan-execution.entity';
import { Exercise } from '../../exercises/entities/exercise.entity';

@Entity('exercise_executions')
export class ExerciseExecution {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @ManyToOne(() => PlanExecution, (execution) => execution.exercises, { onDelete: 'CASCADE' })
    execution: PlanExecution;

    @Column({ nullable: true })
    planExerciseId: string; // Reference to original plan exercise ID if available

    @ManyToOne(() => Exercise, { eager: true }) // Eager load to show name easily
    exercise: Exercise;

    // --- SNAPSHOTS (From Plan) ---
    @Column({ nullable: true })
    exerciseNameSnapshot: string;

    @Column({ nullable: true })
    targetSetsSnapshot: number;

    @Column({ nullable: true })
    targetRepsSnapshot: string;

    @Column({ nullable: true })
    targetWeightSnapshot: string;

    @Column({ nullable: true })
    videoUrl: string; // Snapshot or resolved URL for the video

    // --- REAL DATA (User input) ---
    @Column({ default: false })
    isCompleted: boolean;

    @Column({ default: 0 })
    setsDone: number;

    @Column({ nullable: true })
    repsDone: string;

    @Column({ nullable: true })
    weightUsed: string;

    @Column({ nullable: true })
    timeSpent: string;

    @Column({ type: 'text', nullable: true })
    notes: string;

    @Column({ default: 0 })
    order: number;
}
