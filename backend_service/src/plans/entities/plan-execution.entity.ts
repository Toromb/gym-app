import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  ManyToOne,
  OneToMany,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Plan } from './plan.entity';
import { ExerciseExecution } from './exercise-execution.entity';

export enum ExecutionStatus {
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
}

@Entity('plan_executions')
export class PlanExecution {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  student: User;

  @ManyToOne(() => Plan, { onDelete: 'CASCADE' })
  plan: Plan;

  @Column({ type: 'date' })
  date: string; // YYYY-MM-DD

  @Column()
  dayKey: string; // e.g., "W1-D1"

  @Column()
  weekNumber: number;

  @Column()
  dayOrder: number;

  @Column({
    type: 'enum',
    enum: ExecutionStatus,
    default: ExecutionStatus.IN_PROGRESS,
  })
  status: ExecutionStatus;

  @Column({ type: 'timestamp', nullable: true })
  finishedAt: Date | null;

  @Column({ type: 'json', nullable: true })
  details: any; // Flexible field for future use

  @OneToMany(() => ExerciseExecution, (ex) => ex.execution, { cascade: true })
  exercises: ExerciseExecution[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
