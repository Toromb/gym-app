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

    @Column({ type: 'timestamp', nullable: true })
    lastWorkoutDate: Date | null;

    @UpdateDateColumn()
    updatedAt: Date;
}
