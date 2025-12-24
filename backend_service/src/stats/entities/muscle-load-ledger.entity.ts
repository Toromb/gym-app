import {
    Entity,
    Column,
    PrimaryGeneratedColumn,
    ManyToOne,
    CreateDateColumn,
    Unique,
    JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Muscle } from '../../exercises/entities/muscle.entity';
import { PlanExecution } from '../../plans/entities/plan-execution.entity';

@Entity('muscle_load_ledger')
@Unique(['student', 'muscle', 'date', 'planExecution']) // Prevent duplicate events for same context
export class MuscleLoadLedger {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @ManyToOne(() => User, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'studentId' })
    student: User;

    @Column()
    studentId: string;

    @ManyToOne(() => Muscle, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'muscleId' })
    muscle: Muscle;

    @Column()
    muscleId: string;

    @Column({ type: 'date' })
    date: string; // YYYY-MM-DD

    @Column({ type: 'float' })
    deltaLoad: number;

    @ManyToOne(() => PlanExecution, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'planExecutionId' })
    planExecution: PlanExecution;

    @Column()
    planExecutionId: string;

    @CreateDateColumn()
    createdAt: Date;
}
