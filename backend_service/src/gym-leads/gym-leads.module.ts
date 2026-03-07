import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { GymLeadsService } from './gym-leads.service';
import { GymLeadsController } from './gym-leads.controller';
import { GymLead } from './entities/gym-lead.entity';

@Module({
    imports: [TypeOrmModule.forFeature([GymLead])],
    controllers: [GymLeadsController],
    providers: [GymLeadsService],
})
export class GymLeadsModule { }
