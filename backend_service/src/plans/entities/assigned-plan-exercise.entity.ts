import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  ManyToOne,
  ManyToMany,
  JoinTable,
} from 'typeorm';
import { AssignedPlanDay } from './assigned-plan-day.entity';
import { Exercise } from '../../exercises/entities/exercise.entity';
import { Equipment } from '../../exercises/entities/equipment.entity';

@Entity('assigned_plan_exercises')
export class AssignedPlanExercise {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => AssignedPlanDay, (day) => day.exercises, { onDelete: 'CASCADE' })
  day: AssignedPlanDay;

  @ManyToOne(() => Exercise, { onDelete: 'CASCADE' })
  exercise: Exercise;

  @Column({ nullable: true })
  sets?: number;

  @Column({ nullable: true })
  reps?: string;

  @Column({ nullable: true })
  suggestedLoad?: string;

  @Column({ nullable: true })
  rest?: string;

  @Column({ nullable: true })
  notes?: string;

  @Column({ nullable: true })
  videoUrl?: string;

  @Column({ nullable: true })
  targetTime?: number;

  @Column({ type: 'float', nullable: true })
  targetDistance?: number;

  @Column({ default: 0 })
  order: number;

  @ManyToMany(() => Equipment)
  @JoinTable({
    name: 'assigned_plan_exercise_equipments',
    joinColumn: { name: 'assignedPlanExerciseId', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'equipmentId', referencedColumnName: 'id' },
  })
  equipments: Equipment[];
}
