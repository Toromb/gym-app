import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  ManyToOne,
  OneToMany,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Exclude } from 'class-transformer';
import { User } from '../../users/entities/user.entity';
import { Exercise } from '../../exercises/entities/exercise.entity';
import { Equipment } from '../../exercises/entities/equipment.entity';
import { ManyToMany, JoinTable } from 'typeorm';

import { PlanWeek } from './plan-week.entity';

@Entity('plans')
export class Plan {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ nullable: true })
  description: string;

  @Column({ nullable: true })
  objective?: string;

  @Column({ type: 'text', nullable: true })
  generalNotes?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL' })
  teacher: User;

  @Column({ type: 'date', nullable: true })
  startDate: string;

  @Column({ default: 4 })
  durationWeeks: number;

  @Column({ default: false })
  isTemplate: boolean;

  @OneToMany(() => PlanWeek, (week) => week.plan, { cascade: true })
  weeks: PlanWeek[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

@Entity('plan_days')
export class PlanDay {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Exclude()
  @ManyToOne(() => PlanWeek, (week) => week.days, { onDelete: 'CASCADE' })
  week: PlanWeek;

  @Column({ nullable: true })
  title?: string;

  @Column()
  dayOfWeek: number; // 0=Sunday, 1=Monday, etc.

  @Column({ default: 0 })
  order: number;

  @Column({ type: 'text', nullable: true })
  dayNotes?: string;

  @OneToMany(() => PlanExercise, (exercise) => exercise.day, { cascade: true })
  exercises: PlanExercise[];
}

@Entity('plan_exercises')
export class PlanExercise {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Exclude()
  @ManyToOne(() => PlanDay, (day) => day.exercises, { onDelete: 'CASCADE' })
  day: PlanDay;

  @ManyToOne(() => Exercise, { onDelete: 'CASCADE' })
  exercise: Exercise;

  @Column({ nullable: true })
  sets?: number;

  @Column({ nullable: true })
  reps?: string; // "10-12" or "10"

  @Column({ nullable: true })
  suggestedLoad?: string;

  @Column({ nullable: true })
  rest?: string;

  @Column({ nullable: true })
  notes?: string;

  @Column({ nullable: true })
  // URL for the exercise video
  videoUrl?: string;

  @Column({ default: 0 })
  order: number;

  @ManyToMany(() => Equipment)
  @JoinTable({
    name: 'plan_exercise_equipments',
    joinColumn: { name: 'planExerciseId', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'equipmentId', referencedColumnName: 'id' },
  })
  equipments: Equipment[];
}
