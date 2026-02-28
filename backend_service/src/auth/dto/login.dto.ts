import { IsEmail, IsNotEmpty, IsString, IsOptional, IsIn } from 'class-validator';

export class LoginDto {
  @IsEmail()
  email: string;

  @IsString()
  @IsNotEmpty()
  password: string;

  @IsOptional()
  @IsString()
  @IsIn(['web', 'mobile'])
  platform?: string;

  @IsOptional()
  @IsString()
  deviceId?: string;
}
