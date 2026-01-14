import {
    Entity,
    Column,
    PrimaryGeneratedColumn,
    CreateDateColumn,
    UpdateDateColumn,
    OneToOne,
    ManyToOne,
    JoinColumn,
} from 'typeorm';
import { User } from './user.entity';
import { Gym } from '../../gyms/entities/gym.entity';

export enum TrainingGoal {
    MUSCULATION = 'musculation',
    HEALTH = 'health',
    CARDIO = 'cardio',
    MIXED = 'mixed',
    MOBILITY = 'mobility',
    SPORT = 'sport',
    REHAB = 'rehab',
}

export enum ExperienceLevel {
    NONE = 'none',
    LESS_THAN_YEAR = 'less_than_year',
    MORE_THAN_YEAR = 'more_than_year',
    CURRENT = 'current',
}

export enum ActivityLevel {
    SEDENTARY = 'sedentary',
    LIGHT = 'light',
    MODERATE = 'moderate',
    HIGH = 'high',
}

export enum TrainingFrequency {
    ONCE = 'once_per_week',
    TWICE = 'twice_per_week',
    THREE_TIMES = 'three_times_per_week',
    FOUR_OR_MORE = 'four_or_more',
}

@Entity('onboarding_profiles')
export class OnboardingProfile {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({
        type: 'enum',
        enum: TrainingGoal,
    })
    goal: TrainingGoal;

    @Column({ nullable: true })
    goalDetails: string; // specific sport or injury details

    @Column({
        type: 'enum',
        enum: ExperienceLevel,
    })
    experience: ExperienceLevel;

    @Column({ type: 'jsonb', nullable: true })
    injuries: string[]; // List of injury zones

    @Column({ nullable: true })
    injuryDetails: string;

    @Column({
        type: 'enum',
        enum: ActivityLevel,
    })
    activityLevel: ActivityLevel;

    @Column({
        type: 'enum',
        enum: TrainingFrequency,
        nullable: true,
    })
    desiredFrequency: TrainingFrequency;

    @Column({ type: 'text', nullable: true })
    preferences: string;

    @Column({ nullable: true })
    canLieDown: boolean;

    @Column({ nullable: true })
    canKneel: boolean;

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;

    // Relations

    @OneToOne(() => User, { onDelete: 'CASCADE' })
    @JoinColumn()
    user: User;

    @ManyToOne(() => Gym, { onDelete: 'CASCADE' })
    gym: Gym;
}
