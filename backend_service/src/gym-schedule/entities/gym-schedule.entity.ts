import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';
import { Gym } from '../../gyms/entities/gym.entity';

@Entity('gym_schedule_v2')
export class GymSchedule {
    @ApiProperty({ example: 1, description: 'The unique identifier of the schedule record' })
    @PrimaryGeneratedColumn()
    id: number;

    @ApiProperty({ example: 'MONDAY', description: 'Day of the week' })
    @Column({ type: 'varchar' })
    dayOfWeek: string;

    @ApiProperty({ example: false, description: 'Whether the gym is closed on this day' })
    @Column({ type: 'boolean', default: false })
    isClosed: boolean;

    @ApiProperty({ example: '08:00', description: 'Opening time for the morning shift', required: false, nullable: true })
    @Column({ type: 'varchar', nullable: true })
    openTimeMorning: string | null;

    @ApiProperty({ example: '12:00', description: 'Closing time for the morning shift', required: false, nullable: true })
    @Column({ type: 'varchar', nullable: true })
    closeTimeMorning: string | null;

    @ApiProperty({ example: '16:00', description: 'Opening time for the afternoon shift', required: false, nullable: true })
    @Column({ type: 'varchar', nullable: true })
    openTimeAfternoon: string | null;

    @ApiProperty({ example: '21:00', description: 'Closing time for the afternoon shift', required: false, nullable: true })
    @Column({ type: 'varchar', nullable: true })
    closeTimeAfternoon: string | null;

    @ApiProperty({ example: 'Maintenance day', description: 'Additional notes', required: false, nullable: true })
    @Column({ type: 'text', nullable: true })
    notes: string | null;

    @ManyToOne(() => Gym, { onDelete: 'CASCADE' })
    gym: Gym;
}
