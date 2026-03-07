import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { GymLead } from './entities/gym-lead.entity';
import { CreateGymLeadDto } from './dto/create-gym-lead.dto';

@Injectable()
export class GymLeadsService {
    constructor(
        @InjectRepository(GymLead)
        private readonly gymLeadsRepository: Repository<GymLead>,
    ) { }

    async create(createDto: CreateGymLeadDto): Promise<GymLead> {
        const defaultSource = createDto.source || 'web_app';
        const lead = this.gymLeadsRepository.create({
            ...createDto,
            source: defaultSource,
        });
        return await this.gymLeadsRepository.save(lead);
    }

    // Future scaffold for listing B2B leads internally
    async findAll(): Promise<GymLead[]> {
        return await this.gymLeadsRepository.find({
            order: { createdAt: 'DESC' },
        });
    }
}
