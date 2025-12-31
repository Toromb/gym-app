import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class UpdateGymScheduleDto {
  @ApiProperty({ description: 'Day of the week', example: 'MONDAY' })
  @IsString()
  @IsNotEmpty()
  dayOfWeek: string;

  @ApiProperty({ description: 'Is the gym closed?', example: false })
  @IsBoolean()
  isClosed: boolean;

  @ApiProperty({
    description: 'Morning Open Time',
    example: '08:00',
    required: false,
  })
  @IsOptional()
  @IsString()
  openTimeMorning?: string;

  @ApiProperty({
    description: 'Morning Close Time',
    example: '12:00',
    required: false,
  })
  @IsOptional()
  @IsString()
  closeTimeMorning?: string;

  @ApiProperty({
    description: 'Afternoon Open Time',
    example: '16:00',
    required: false,
  })
  @IsOptional()
  @IsString()
  openTimeAfternoon?: string;

  @ApiProperty({
    description: 'Afternoon Close Time',
    example: '21:00',
    required: false,
  })
  @IsOptional()
  @IsString()
  closeTimeAfternoon?: string;

  @ApiProperty({ description: 'Notes', example: 'Holiday', required: false })
  @IsOptional()
  @IsString()
  notes?: string;
}
