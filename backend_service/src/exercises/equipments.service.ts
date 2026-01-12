import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Equipment } from './entities/equipment.entity';
import { Gym } from '../gyms/entities/gym.entity';

@Injectable()
export class EquipmentsService {
    private readonly logger = new Logger(EquipmentsService.name);

    constructor(
        @InjectRepository(Equipment)
        private equipmentsRepository: Repository<Equipment>,
    ) { }

    async initializeGymEquipments(gym: Gym): Promise<void> {
        this.logger.log(`Initializing equipments for Gym: ${gym.businessName}`);

        // System Equipment: Peso Corporal
        const bodyWeight = this.equipmentsRepository.create({
            name: 'Peso Corporal',
            gym: gym,
            isBodyWeight: true,
            isEditable: false,
        });

        // Default Equipment List
        const defaults = [
            'Mancuerna',
            'Barra',
            'Discos',
            'Kettlebell',
            'Máquina',
            'Polea',
            'Smith',
            'Banco',
            'Rack / Jaula',
            'Banda elástica',
            'TRX / Suspensión',
            'Balón medicinal',
            'Colchoneta',
            'Step / Cajón',
        ];

        const defaultEntities = defaults.map((name) =>
            this.equipmentsRepository.create({
                name,
                gym: gym,
                isBodyWeight: false,
                isEditable: true,
            }),
        );

        // Save All
        await this.equipmentsRepository.save([bodyWeight, ...defaultEntities]);
        this.logger.log(`Created ${1 + defaults.length} equipments for gym.`);
    }

    async findAll(gymId: string): Promise<Equipment[]> {
        // Lazy Check: Ensure 'Peso Corporal' exists for existing gyms
        const bodyWeightExists = await this.equipmentsRepository.findOne({
            where: { gym: { id: gymId }, isBodyWeight: true }
        });

        if (!bodyWeightExists) {
            this.logger.log(`Lazy creation of 'Peso Corporal' for gym ${gymId}`);
            await this.equipmentsRepository.save({
                name: 'Peso Corporal',
                gym: { id: gymId },
                isBodyWeight: true,
                isEditable: false
            });
        }

        return this.equipmentsRepository.find({
            where: { gym: { id: gymId } },
            order: {
                isBodyWeight: 'DESC', // Body Weight first
                name: 'ASC',
            },
        });
    }

    // Basic CRUD for subsequent features
    async create(name: string, gymId: string): Promise<Equipment> {
        // Check duplicate in gym handled by DB constraint unique
        const eq = this.equipmentsRepository.create({
            name,
            gym: { id: gymId } as any
        });
        return this.equipmentsRepository.save(eq);
    }

    async remove(id: string, gymId: string): Promise<void> {
        await this.equipmentsRepository.delete({ id, gym: { id: gymId }, isEditable: true });
    }
}
