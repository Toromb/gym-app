import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    ManyToOne,
    OneToMany,
    CreateDateColumn,
    UpdateDateColumn,
} from 'typeorm';
import { Gym } from '../../gyms/entities/gym.entity';
import { FreeTrainingDefinitionExercise } from './free-training-definition-exercise.entity';

export enum FreeTrainingType {
    FUNCIONAL = 'FUNCIONAL',
    CROSSFIT = 'CROSSFIT',
    CARDIO = 'CARDIO',
    MUSCULACION = 'MUSCULACION',
    MUSCULACION_CARDIO = 'MUSCULACION_CARDIO',
}

export enum TrainingLevel {
    INICIAL = 'INICIAL',
    MEDIO = 'MEDIO',
    AVANZADO = 'AVANZADO',
}

export enum BodySector {
    PIERNAS = 'PIERNAS',
    ZONA_MEDIA = 'ZONA_MEDIA',
    HOMBROS = 'HOMBROS',
    ESPALDA = 'ESPALDA',
    PECHO = 'PECHO',
    FULL_BODY = 'FULL_BODY',
}

export enum CardioLevel {
    INICIAL = 'CARDIO_INICIAL',
    MEDIO = 'CARDIO_MEDIO', // Prefixed to avoid collision if desired, or simple MEDIO
    AVANZADO = 'CARDIO_AVANZADO',
}

@Entity('free_training_definitions')
export class FreeTrainingDefinition {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @ManyToOne(() => Gym, { onDelete: 'CASCADE' })
    gym: Gym;

    @Column()
    name: string;

    @Column({
        type: 'enum',
        enum: FreeTrainingType,
    })
    type: FreeTrainingType;

    @Column({
        type: 'enum',
        enum: TrainingLevel,
    })
    level: TrainingLevel;

    @Column({
        type: 'enum',
        enum: BodySector,
        nullable: true,
    })
    sector: BodySector;

    @Column({
        type: 'enum',
        enum: CardioLevel,
        nullable: true,
    })
    cardioLevel: CardioLevel;

    @OneToMany(() => FreeTrainingDefinitionExercise, (ex) => ex.freeTraining, {
        cascade: true,
    })
    exercises: FreeTrainingDefinitionExercise[];

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}
