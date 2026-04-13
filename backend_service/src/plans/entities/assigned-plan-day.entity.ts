import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  ManyToOne,
  OneToMany,
} from 'typeorm';
import { AssignedPlanWeek } from './assigned-plan-week.entity';
import { AssignedPlanExercise } from './assigned-plan-exercise.entity';
import { TrainingIntent } from './plan.entity';

@Entity('assigned_plan_days')
export class AssignedPlanDay {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => AssignedPlanWeek, (week) => week.days, { onDelete: 'CASCADE' })
  week: AssignedPlanWeek;

  @Column({ nullable: true })
  title?: string;

  @Column()
  dayOfWeek: number;

  @Column({ default: 0 })
  order: number;

  @Column({
    type: 'enum',
    enum: TrainingIntent,
    default: TrainingIntent.GENERAL,
  })
  trainingIntent: TrainingIntent;

  @Column({ type: 'text', nullable: true })
  dayNotes?: string;

  @OneToMany(() => AssignedPlanExercise, (exercise) => exercise.day, { cascade: true })
  exercises: AssignedPlanExercise[];
}
