import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Gym, GymStatus } from './entities/gym.entity';
import { CreateGymDto } from './dto/create-gym.dto';
import { UpdateGymDto } from './dto/update-gym.dto';
import { ExercisesService } from '../exercises/exercises.service';
import { EquipmentsService } from '../exercises/equipments.service';
import { BASE_EXERCISES } from '../exercises/constants/base-exercises';

@Injectable()
export class GymsService {
  constructor(
    @InjectRepository(Gym)
    private gymsRepository: Repository<Gym>,
    private exercisesService: ExercisesService,
    private equipmentsService: EquipmentsService,
  ) { }

  async create(createGymDto: CreateGymDto) {
    const gym = this.gymsRepository.create(createGymDto);
    const savedGym = await this.gymsRepository.save(gym);

    // Initialize Base Exercises & Equipments
    console.log(`[GymsService] Initializing Gym: ${savedGym.id} (${savedGym.businessName})`);

    await Promise.all([
      this.exercisesService.cloneBaseExercises(savedGym),
      this.equipmentsService.initializeGymEquipments(savedGym),
    ]);

    return savedGym;
  }


  findAll() {
    return this.gymsRepository.find();
  }

  async findOne(id: string) {
    return this.gymsRepository.findOneBy({ id });
  }

  async update(id: string, updateGymDto: UpdateGymDto) {
    await this.gymsRepository.update(id, updateGymDto);
    return this.gymsRepository.findOneBy({ id });
  }

  remove(id: string) {
    // We are not allowing delete, just suspend? But for scaffolding adding it.
    // Logic: Do not delete if users exist.
    return this.gymsRepository.delete(id);
  }

  countAll() {
    return this.gymsRepository.count();
  }

  countActive() {
    return this.gymsRepository.count({ where: { status: GymStatus.ACTIVE } });
  }
}
