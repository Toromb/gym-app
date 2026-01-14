import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, ManyToMany, JoinTable } from 'typeorm';
import { FreeTrainingDefinition } from './free-training-definition.entity';
import { Exercise } from '../../exercises/entities/exercise.entity';
import { Equipment } from '../../exercises/entities/equipment.entity';

@Entity('free_training_definition_exercises')
export class FreeTrainingDefinitionExercise {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @ManyToOne(() => FreeTrainingDefinition, (ft) => ft.exercises, { onDelete: 'CASCADE' })
    freeTraining: FreeTrainingDefinition;

    @ManyToOne(() => Exercise, { eager: true })
    exercise: Exercise;

    @Column({ default: 0 })
    order: number;

    @Column({ nullable: true })
    sets: number;

    @Column({ nullable: true })
    reps: string;

    @Column({ nullable: true })
    suggestedLoad: string;

    @Column({ nullable: true })
    rest: string;

    @Column({ nullable: true })
    notes: string;

    @Column({ nullable: true })
    videoUrl: string;

    @ManyToMany(() => Equipment)
    @JoinTable()
    equipments: Equipment[];
}
