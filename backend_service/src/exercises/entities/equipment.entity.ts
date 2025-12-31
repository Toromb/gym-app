import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('equipments')
export class Equipment {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ unique: true })
    name: string;
}
