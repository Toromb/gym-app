import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  ManyToOne,
  OneToMany,
} from 'typeorm';
import { AssignedPlan } from './assigned-plan.entity';
import { AssignedPlanDay } from './assigned-plan-day.entity';

@Entity('assigned_plan_weeks')
export class AssignedPlanWeek {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => AssignedPlan, (plan) => plan.weeks, { onDelete: 'CASCADE' })
  assignedPlan: AssignedPlan;

  @Column()
  weekNumber: number;

  @OneToMany(() => AssignedPlanDay, (day) => day.week, { cascade: true })
  days: AssignedPlanDay[];
}
