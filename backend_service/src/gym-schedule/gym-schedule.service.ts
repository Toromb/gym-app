import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { GymSchedule } from './entities/gym-schedule.entity';
import { UpdateGymScheduleDto } from './dto/update-gym-schedule.dto';

@Injectable()
export class GymScheduleService implements OnModuleInit {
    constructor(
        @InjectRepository(GymSchedule)
        private readonly gymScheduleRepository: Repository<GymSchedule>,
    ) { }

    async onModuleInit() {
        // No global seed anymore
    }

    async seedDefaultsForGym(gymId: string) {
        const count = await this.gymScheduleRepository.count({
            where: { gym: { id: gymId } }
        });

        if (count === 0) {
            const days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
            const defaultSchedule = days.map(day => {
                const schedule = new GymSchedule();
                schedule.dayOfWeek = day;
                schedule.isClosed = false;
                schedule.openTimeMorning = '08:00';
                schedule.closeTimeMorning = '12:00';
                schedule.openTimeAfternoon = '16:00';
                schedule.closeTimeAfternoon = '21:00';
                schedule.gym = { id: gymId } as any; // Associate with Gym

                if (day === 'SUNDAY') {
                    schedule.isClosed = true;
                    schedule.openTimeMorning = null;
                    schedule.closeTimeMorning = null;
                    schedule.openTimeAfternoon = null;
                    schedule.closeTimeAfternoon = null;
                }
                return schedule;
            });
            await this.gymScheduleRepository.save(defaultSchedule);
        }
    }

    async findAll(gymId: string): Promise<GymSchedule[]> {
        if (!gymId) return [];

        // Ensure defaults exist for this gym
        await this.seedDefaultsForGym(gymId);

        const daysOrder = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
        const schedules = await this.gymScheduleRepository.find({
            where: { gym: { id: gymId } }
        });

        // Sort by custom day order
        return schedules.sort((a, b) => {
            return daysOrder.indexOf(a.dayOfWeek) - daysOrder.indexOf(b.dayOfWeek);
        });
    }

    async update(updateGymScheduleDtos: UpdateGymScheduleDto[], gymId: string): Promise<GymSchedule[]> {
        const updatedSchedules = [];
        for (const dto of updateGymScheduleDtos) {
            let schedule = await this.gymScheduleRepository.findOne({
                where: {
                    dayOfWeek: dto.dayOfWeek,
                    gym: { id: gymId }
                }
            });

            // If strictly missing (logic gap), rely on findAll seeding or create missing on fly?
            // Safer to just update existing. findAll ensures they exist.
            if (schedule) {
                if (dto.isClosed !== undefined) schedule.isClosed = dto.isClosed;

                // Handle time fields, allowing update if provided
                if (dto.openTimeMorning !== undefined) schedule.openTimeMorning = dto.openTimeMorning || null;
                if (dto.closeTimeMorning !== undefined) schedule.closeTimeMorning = dto.closeTimeMorning || null;
                if (dto.openTimeAfternoon !== undefined) schedule.openTimeAfternoon = dto.openTimeAfternoon || null;
                if (dto.closeTimeAfternoon !== undefined) schedule.closeTimeAfternoon = dto.closeTimeAfternoon || null;
                if (dto.notes !== undefined) schedule.notes = dto.notes || null;

                updatedSchedules.push(await this.gymScheduleRepository.save(schedule));
            }
        }
        return updatedSchedules;
    }
}
