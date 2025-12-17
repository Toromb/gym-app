import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Plan } from './plan.entity';

@Entity('student_plans')
export class StudentPlan {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @ManyToOne(() => User, (user) => user.studentPlans, { onDelete: 'CASCADE' })
    student: User;

    @ManyToOne(() => Plan, { onDelete: 'CASCADE' })
    plan: Plan;

    @Column({ type: 'date' })
    assignedAt: string;

    @Column({ type: 'date' })
    startDate: string;

    @Column({ type: 'date', nullable: true })
    endDate: string;

    @Column({ default: true })
    isActive: boolean;

    @Column({ type: 'json', default: {} })
    progress: any;

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}
