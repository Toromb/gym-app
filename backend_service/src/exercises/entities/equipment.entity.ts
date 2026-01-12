import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, Unique } from 'typeorm';
import { Gym } from '../../gyms/entities/gym.entity';

@Entity('equipments')
@Unique(['name', 'gym']) // Ensure unique name per gym
export class Equipment {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    name: string;

    @ManyToOne(() => Gym, { onDelete: 'CASCADE' })
    gym: Gym;

    @Column({ default: false })
    isBodyWeight: boolean;

    @Column({ default: true })
    isEditable: boolean;
}
