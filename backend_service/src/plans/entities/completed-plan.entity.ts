import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  ManyToOne,
  OneToMany,
  CreateDateColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Gym } from '../../gyms/entities/gym.entity';
import { TrainingSession } from './training-session.entity';

export enum CompletedReason {
  COMPLETED = 'COMPLETED',
  RESTARTED = 'RESTARTED',
  CANCELLED = 'CANCELLED',
  ARCHIVED = 'ARCHIVED',
}

@Entity('completed_plans')
export class CompletedPlan {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, (user) => user.completedPlans, { onDelete: 'CASCADE' })
  student: User;

  @ManyToOne(() => Gym, { onDelete: 'CASCADE', nullable: true })
  gym: Gym;

  @Column({ type: 'varchar', nullable: true })
  assignedPlanId: string | null; // The specific snapshot they executed

  @Column({ type: 'varchar', nullable: true })
  originalPlanId: string | null; // The origin plan template

  @Column()
  planNameSnapshot: string;

  @Column({ type: 'date' })
  startedAt: string;

  @Column({ type: 'timestamp' })
  completedAt: Date;

  @Column({
    type: 'enum',
    enum: CompletedReason,
    default: CompletedReason.COMPLETED,
  })
  completedReason: CompletedReason;

  @OneToMany(() => TrainingSession, (session) => session.completedPlan)
  sessions: TrainingSession[];

  @CreateDateColumn()
  createdAt: Date;
}
