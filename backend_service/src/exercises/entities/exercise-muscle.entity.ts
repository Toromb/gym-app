import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, Unique } from 'typeorm';
import { Exercise } from './exercise.entity';
import { Muscle } from './muscle.entity';

export enum MuscleRole {
    PRIMARY = 'PRIMARY',
    SECONDARY = 'SECONDARY',
    STABILIZER = 'STABILIZER',
}

@Entity('exercise_muscles')
@Unique(['exercise', 'muscle']) // Prevent duplicate mappings
export class ExerciseMuscle {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @ManyToOne(() => Exercise, { onDelete: 'CASCADE' })
    exercise: Exercise;

    @ManyToOne(() => Muscle, { onDelete: 'CASCADE' })
    muscle: Muscle;

    @Column({
        type: 'enum',
        enum: MuscleRole,
    })
    role: MuscleRole;

    @Column({ type: 'int', default: 0 })
    loadPercentage: number;
}
