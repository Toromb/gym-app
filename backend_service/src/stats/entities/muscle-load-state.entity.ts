import {
    Entity,
    Column,
    ManyToOne,
    JoinColumn,
    UpdateDateColumn,
    PrimaryColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Muscle } from '../../exercises/entities/muscle.entity';

@Entity('muscle_load_state')
export class MuscleLoadState {
    @PrimaryColumn()
    studentId: string;

    @PrimaryColumn()
    muscleId: string;

    @ManyToOne(() => User, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'studentId' })
    student: User;

    @ManyToOne(() => Muscle, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'muscleId' })
    muscle: Muscle;

    @Column({ type: 'float', default: 0 })
    currentLoad: number; // 0 to 100

    @Column({ type: 'date' })
    lastComputedDate: string; // YYYY-MM-DD

    @UpdateDateColumn()
    updatedAt: Date;
}
