import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  ManyToOne,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('payment_records')
export class PaymentRecord {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE', eager: false })
  user: User;

  /** Monto abonado — opcional */
  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  amount: number | null;

  /** Método de pago: 'efectivo' | 'transferencia' | 'otro' — opcional */
  @Column({ type: 'varchar', nullable: true })
  method: string | null;

  /** Nota libre del admin — opcional */
  @Column({ type: 'text', nullable: true })
  notes: string | null;

  /** Inicio del período que cubre este pago */
  @Column({ type: 'date' })
  periodFrom: string;

  /** Fin del período que cubre este pago */
  @Column({ type: 'date' })
  periodTo: string;

  /** Timestamp de registro (automático) */
  @CreateDateColumn()
  paidAt: Date;

  /** Admin que registró el pago */
  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL', eager: false })
  registeredBy: User | null;
}
