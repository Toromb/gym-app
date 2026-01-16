import { Entity, Column, PrimaryColumn, UpdateDateColumn } from 'typeorm';

@Entity('user_stats')
export class UserStats {
    @PrimaryColumn('uuid')
    userId: string; // Manually assigned to match User ID (or OneToOne relation)

    @Column({ default: 0 })
    currentStreak: number;

    @Column({ default: 0 })
    weeklyWorkouts: number;

    @Column({ default: 0 })
    workoutCount: number;

    @Column({ default: 0 })
    totalExperience: number;

    @Column({ default: 1 })
    currentLevel: number;

    @Column({ nullable: true })
    lastBonusWeek: string; // "YYYY-WW"

    @Column({ type: 'timestamp', nullable: true })
    lastWorkoutDate: Date | null;

    @UpdateDateColumn()
    updatedAt: Date;
}
