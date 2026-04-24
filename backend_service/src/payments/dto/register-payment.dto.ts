import {
  IsOptional,
  IsNumber,
  IsString,
  IsInt,
  Min,
  Max,
} from 'class-validator';

export class RegisterPaymentDto {
  /** Monto abonado — opcional */
  @IsOptional()
  @IsNumber()
  amount?: number;

  /** Método de pago: 'efectivo', 'transferencia', 'otro' — opcional */
  @IsOptional()
  @IsString()
  method?: string;

  /** Nota libre del admin — opcional */
  @IsOptional()
  @IsString()
  notes?: string;

  /**
   * Cantidad de meses a regularizar.
   * Default: 1. Máximo técnico: 24.
   */
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(24)
  periodMonths?: number;
}
