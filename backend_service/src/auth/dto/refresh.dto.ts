import { IsNotEmpty, IsString, IsOptional } from 'class-validator';

export class RefreshDto {
    @IsString()
    @IsNotEmpty()
    refreshToken: string;

    @IsOptional()
    @IsString()
    deviceId?: string;
}
