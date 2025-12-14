
import { Module } from '@nestjs/common';
import { StatsController } from './stats.controller';
import { UsersModule } from '../users/users.module';
import { GymsModule } from '../gyms/gyms.module';

@Module({
    imports: [UsersModule, GymsModule],
    controllers: [StatsController],
})
export class StatsModule { }
