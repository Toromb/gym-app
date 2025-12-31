import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn, OneToMany, ManyToOne } from 'typeorm';
import { StudentPlan } from '../../plans/entities/student-plan.entity';
import { Exclude } from 'class-transformer';
import { Gym } from '../../gyms/entities/gym.entity';


export enum UserRole {
    ADMIN = 'admin',
    PROFE = 'profe',
    ALUMNO = 'alumno',
    SUPER_ADMIN = 'super_admin',
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

    @Exclude()
    @Column({ type: 'varchar', select: false, nullable: true })
    passwordHash: string | null;

    @Exclude()
    @Column({ type: 'varchar', nullable: true, select: false })
    activationTokenHash: string | null;

    @Column({ type: 'timestamp', nullable: true })
    activationTokenExpires: Date | null;

    @Exclude()
    @Column({ type: 'varchar', nullable: true, select: false })
    resetTokenHash: string | null;

    @Column({ type: 'timestamp', nullable: true })
    resetTokenExpires: Date | null;

    @Column({ default: false })
    isActive: boolean;

    @Column({ nullable: true })
    phone: string;

    @Column({ nullable: true })
    age: number;

    @Column({ nullable: true })
    gender: string;

    @Column({ type: 'text', nullable: true })
    notes: string;

    @Column({ type: 'float', nullable: true })
    height: number;

    // Student Specific
    @Column({ nullable: true })
    trainingGoal: string;

    @Column({ type: 'text', nullable: true })
    professorObservations: string;

    @Column({ type: 'float', nullable: true })
    initialWeight: number;

    @Column({ type: 'float', nullable: true })
    currentWeight: number;

    @Column({ type: 'date', nullable: true })
    weightUpdateDate: Date;

    @Column({ type: 'text', nullable: true })
    personalComment: string;

    // isActive moved to top

    @Column({ type: 'date', nullable: true })
    membershipStartDate: Date;

    @Column({ type: 'date', nullable: true })
    membershipExpirationDate: Date;

    // Professor Specific
    @Column({ nullable: true })
    specialty: string;

    @Column({ type: 'text', nullable: true })
    internalNotes: string;

    // Admin Specific
    @Column({ type: 'text', nullable: true })
    adminNotes: string;

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

    @Column({ default: true })
    paysMembership: boolean;

    @Column({ type: 'date', nullable: true })
    lastPaymentDate: string;

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;

    @OneToMany(() => StudentPlan, (studentPlan) => studentPlan.student)
    studentPlans: StudentPlan[];

    @ManyToOne(() => User, (user) => user.students, { nullable: true, onDelete: 'SET NULL' })
    professor: User | null;

    @OneToMany(() => User, (user) => user.professor)
    students: User[];

    @ManyToOne(() => Gym, (gym) => gym.users, { nullable: true, onDelete: 'CASCADE' })
    gym: Gym;
}

