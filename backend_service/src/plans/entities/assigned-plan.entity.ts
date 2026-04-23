import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  OneToMany,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { AssignedPlanWeek } from './assigned-plan-week.entity';
import { StudentPlan } from './student-plan.entity';

@Entity('assigned_plans')
export class AssignedPlan {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid', nullable: true })
  originalPlanId: string | null;

  @Column({ type: 'varchar', nullable: true })
  originalPlanName: string | null;

  @Column({ type: 'timestamp', nullable: true })
  assignedAt: Date | null;

  @Column({ type: 'uuid', nullable: true })
  assignedByUserId: string | null;

  @Column()
  name: string;

  @Column({ type: 'varchar', nullable: true })
  description: string | null;

  @Column({ nullable: true })
  objective?: string;

  @Column({ type: 'text', nullable: true })
  generalNotes?: string;

  @Column({ type: 'date', nullable: true })
  startDate: string | null;

  @Column({ default: 4 })
  durationWeeks: number;

  @OneToMany(() => AssignedPlanWeek, (week) => week.assignedPlan, { cascade: true })
  weeks: AssignedPlanWeek[];

  @OneToMany(() => StudentPlan, (sp) => sp.assignedPlan)
  studentPlans: StudentPlan[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
