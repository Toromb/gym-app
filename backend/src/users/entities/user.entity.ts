import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn, OneToMany, ManyToOne } from 'typeorm';
import { StudentPlan } from '../../plans/entities/student-plan.entity';


export enum UserRole {
    ADMIN = 'admin',
    PROFE = 'profe',
    ALUMNO = 'alumno',
}

export enum PaymentStatus {
    PENDING = 'pending',
    PAID = 'paid',
    OVERDUE = 'overdue',
}

@Entity('users')
export class User {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    firstName: string;

    @Column()
    lastName: string;

    @Column({ unique: true })
    email: string;

    @Column()
    passwordHash: string;

    @Column({ nullable: true })
    phone: string;

    @Column({ nullable: true })
    age: number;

    @Column({ nullable: true })
    gender: string;

    @Column({ type: 'text', nullable: true })
    notes: string;

    @Column({
        type: 'enum',
        enum: UserRole,
        default: UserRole.ALUMNO,
    })
    role: UserRole;

    @Column({
        type: 'enum',
        enum: PaymentStatus,
        default: PaymentStatus.PENDING,
    })
    paymentStatus: PaymentStatus;

    @Column({ type: 'date', nullable: true })
    lastPaymentDate: string;

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;

    @OneToMany(() => StudentPlan, (studentPlan) => studentPlan.student)
    studentPlans: StudentPlan[];

    @ManyToOne(() => User, (user) => user.students, { nullable: true, onDelete: 'SET NULL' })
    professor: User;

    @OneToMany(() => User, (user) => user.professor)
    students: User[];
}

