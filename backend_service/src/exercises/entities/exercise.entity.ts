import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Gym } from '../../gyms/entities/gym.entity';
import { ExerciseMuscle } from './exercise-muscle.entity';
import { Equipment } from './equipment.entity';
import { OneToMany, ManyToMany, JoinTable } from 'typeorm';

@Entity('exercises')
export class Exercise {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ nullable: true })
  description: string;

  @Column({ nullable: true })
  videoUrl: string;

  @Column({ nullable: true })
  imageUrl: string;

  @Column({ nullable: true })
  muscleGroup?: string;

  @Column({ nullable: true })
  type?: string;

  // Default Execution Params
  @Column({ nullable: true, type: 'int' })
  sets?: number;

  @Column({ nullable: true })
  reps?: string;

  @Column({ nullable: true })
  rest?: string;

  @Column({ nullable: true })
  load?: string;

  @Column({ nullable: true })
  notes?: string;

  // Professional Exercise Change System Config
  @Column({ type: 'float', nullable: true }) // Using float for decimal factor (e.g. 0.85)
  loadFactor?: number;

  @Column({ type: 'int', nullable: true })
  defaultSets?: number;

  @Column({ type: 'int', nullable: true })
  minReps?: number;

  @Column({ type: 'int', nullable: true })
  maxReps?: number;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL' })
  createdBy: User;

  @ManyToOne(() => Gym, { nullable: true, onDelete: 'CASCADE' })
  gym: Gym;

  @OneToMany(() => ExerciseMuscle, (em) => em.exercise)
  exerciseMuscles: ExerciseMuscle[];

  @ManyToMany(() => Equipment, { cascade: false })
  @JoinTable({
    name: 'exercise_equipments',
    joinColumn: { name: 'exerciseId', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'equipmentId', referencedColumnName: 'id' },
  })
  equipments: Equipment[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
