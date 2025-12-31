import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn, OneToMany } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Exclude } from 'class-transformer';

export enum GymPlan {
    BASIC = 'basic', // 0-50
    PRO = 'pro',     // 50-200
    PREMIUM = 'premium', // 200-1000
}

export enum GymStatus {
    ACTIVE = 'active',
    SUSPENDED = 'suspended',
}

@Entity('gyms')
export class Gym {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ unique: true })
    businessName: string;

    @Column()
    address: string;

    @Column({ nullable: true })
    phone: string;

    @Column({ nullable: true })
    email: string;

    @Column({
        type: 'enum',
        enum: GymStatus,
        default: GymStatus.ACTIVE,
    })
    status: GymStatus;

    @Column({ type: 'text', nullable: true })
    suspensionReason: string;

    @Column({
        type: 'enum',
        enum: GymPlan,
        default: GymPlan.BASIC,
    })
    subscriptionPlan: GymPlan;

    @Column({ type: 'date', nullable: true })
    expirationDate: Date;

    @Column({ type: 'int', default: 50 }) // Default to Basic limit
    maxProfiles: number;

    @Column({ nullable: true })
    logoUrl: string;

    @Column({ nullable: true })
    primaryColor: string;

    @Column({ nullable: true })
    secondaryColor: string;

    @Column({ nullable: true })
    welcomeMessage: string;

    @Column({ nullable: true })
    openingHours: string;

    @Column({ nullable: true })
    paymentAlias: string;

    @Column({ nullable: true })
    paymentCbu: string;

    @Column({ nullable: true })
    paymentAccountName: string;

    @Column({ nullable: true })
    paymentBankName: string;

    @Column({ type: 'text', nullable: true })
    paymentNotes: string;

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;

    @Exclude()
    @OneToMany(() => User, (user) => user.gym)
    users: User[];
}
