import { Entity, Column, PrimaryGeneratedColumn, OneToMany } from 'typeorm';
import { ExerciseMuscle } from './exercise-muscle.entity';

export enum MuscleRegion {
    UPPER = 'UPPER',
    LOWER = 'LOWER',
    CORE = 'CORE',
}

export enum BodySide {
    FRONT = 'FRONT',
    BACK = 'BACK',
}

@Entity('muscles')
export class Muscle {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ unique: true })
    name: string;

    @Column({
        type: 'enum',
        enum: MuscleRegion,
    })
    region: MuscleRegion;

    @Column({
        type: 'enum',
        enum: BodySide,
    })
    bodySide: BodySide;

    @Column({ default: 0 })
    order: number;

    @Column({ default: true })
    isActive: boolean;

    @OneToMany(() => ExerciseMuscle, (em) => em.muscle)
    exerciseMuscles: ExerciseMuscle[];
}
