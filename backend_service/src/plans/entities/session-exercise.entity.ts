import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, JoinColumn } from 'typeorm';
import { TrainingSession } from './training-session.entity';
import { Exercise } from '../../exercises/entities/exercise.entity';
import { Equipment } from '../../exercises/entities/equipment.entity';
import { ManyToMany, JoinTable } from 'typeorm';

@Entity('session_exercises')
export class SessionExercise {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => TrainingSession, (session) => session.exercises, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'sessionId' })
  session: TrainingSession;

  @Column({ nullable: true })
  planExerciseId: string; // Reference to original plan exercise ID if available (Nullable)

  @ManyToOne(() => Exercise, { eager: true, onDelete: 'SET NULL' }) // Eager load to show name easily
  exercise: Exercise;

  // --- SNAPSHOTS (From Plan) ---
  @Column({ nullable: true })
  exerciseNameSnapshot: string;

  @Column({ nullable: true })
  targetSetsSnapshot?: number;

  @Column({ nullable: true })
  targetRepsSnapshot?: string;

  @Column({ nullable: true })
  targetWeightSnapshot?: string;

  @Column({ nullable: true, type: 'int' })
  targetTimeSnapshot?: number; // Seconds

  @Column({ nullable: true, type: 'float' })
  targetDistanceSnapshot?: number; // Meters

  @Column({ nullable: true })
  videoUrl: string; // Snapshot or resolved URL for the video

  @ManyToMany(() => Equipment, { cascade: false, eager: true }) // Eager load for Session View
  @JoinTable({
    name: 'exercise_execution_equipments',
    joinColumn: { name: 'exerciseExecutionId', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'equipmentId', referencedColumnName: 'id' },
  })
  equipmentsSnapshot: Equipment[];

  // --- REAL DATA (User input) ---
  @Column({ default: false })
  isCompleted: boolean;

  @Column({ nullable: true })
  setsDone: string;

  @Column({ nullable: true })
  repsDone: string;

  @Column({ nullable: true })
  weightUsed: string;

  @Column({ nullable: true })
  timeSpent: string;

  @Column({ nullable: true, type: 'float' })
  distanceCovered?: number; // Meters

  @Column({ type: 'text', nullable: true })
  notes: string;

  @Column({ default: 0 })
  order: number;
}
