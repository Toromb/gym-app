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
import { SessionExercise } from './session-exercise.entity';

import { FreeTrainingDefinition } from './free-training-definition.entity';

export enum ExecutionStatus {
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  ABANDONED = 'ABANDONED',
}

@Entity('training_sessions')
export class TrainingSession {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  student: User;

  @ManyToOne(() => Plan, { onDelete: 'CASCADE', nullable: true })
  plan: Plan | null;

  @ManyToOne(() => FreeTrainingDefinition, { nullable: true, onDelete: 'SET NULL' })
  freeTrainingDefinition: FreeTrainingDefinition | null;


  @Column({ type: 'date' })
  date: string; // YYYY-MM-DD

  @Column({ default: 'PLAN' })
  source: string; // 'PLAN', 'FREE', 'CLASS'

  @Column({ nullable: true })
  dayKey: string; // e.g., "W1-D1" (Nullable for free sessions)

  @Column({ nullable: true })
  weekNumber: number;

  @Column({ nullable: true })
  dayOrder: number;

  @Column({
    type: 'enum',
    enum: ExecutionStatus,
    default: ExecutionStatus.IN_PROGRESS,
  })
  status: ExecutionStatus;

  @Column({ type: 'timestamp', nullable: true })
  finishedAt: Date | null;

  @Column({ default: false })
  processedForExp: boolean;

  @Column({ type: 'json', nullable: true })
  details: any; // Flexible field for future use

  @OneToMany(() => SessionExercise, (ex) => ex.session, { cascade: true })
  exercises: SessionExercise[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
