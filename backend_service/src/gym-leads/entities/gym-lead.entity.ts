import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('gym_leads')
export class GymLead {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    fullName: string;

    @Column()
    gymName: string;

    @Column()
    city: string;

    @Column()
    email: string;

    @Column()
    phone: string;

    @Column({ nullable: true })
    studentsCount: number;

    @Column({ type: 'text', nullable: true })
    message: string;

    @Column({ default: 'web_app' })
    source: string;

    @CreateDateColumn()
    createdAt: Date;
}
