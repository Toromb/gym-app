import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Gym, GymStatus } from './entities/gym.entity';
import { CreateGymDto } from './dto/create-gym.dto';
import { UpdateGymDto } from './dto/update-gym.dto';

@Injectable()
export class GymsService {
  constructor(
    @InjectRepository(Gym)
    private gymsRepository: Repository<Gym>,
  ) {}

  create(createGymDto: CreateGymDto) {
    const gym = this.gymsRepository.create(createGymDto);
    return this.gymsRepository.save(gym);
  }

  findAll() {
    return this.gymsRepository.find();
  }

  findOne(id: string) {
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
