import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, OneToMany } from 'typeorm';
import { Exclude } from 'class-transformer';
import { Plan, PlanDay } from './plan.entity';

@Entity('plan_weeks')
export class PlanWeek {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Exclude()
    @ManyToOne(() => Plan, (plan) => plan.weeks, { onDelete: 'CASCADE' })
    plan: Plan;

    @Column()
    weekNumber: number;

    @OneToMany(() => PlanDay, (day) => day.week, { cascade: true })
    days: PlanDay[];
}
