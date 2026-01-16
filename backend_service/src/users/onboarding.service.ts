import { Injectable, BadRequestException, NotFoundException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { OnboardingProfile } from './entities/onboarding-profile.entity';
import { CreateOnboardingDto } from './dto/create-onboarding.dto';
import { User } from './entities/user.entity';

@Injectable()
export class OnboardingService {
    private readonly logger = new Logger(OnboardingService.name);

    constructor(
        @InjectRepository(OnboardingProfile)
        private profileRepo: Repository<OnboardingProfile>,
        @InjectRepository(User)
        private userRepo: Repository<User>,
        private dataSource: DataSource,
    ) { }

    async createProfile(userId: string, dto: CreateOnboardingDto): Promise<OnboardingProfile> {

        // 1. Validate User
        const user = await this.userRepo.findOne({
            where: { id: userId },
            relations: ['onboardingProfile', 'gym']
        });

        if (!user) throw new NotFoundException('User not found');
        if (user.onboardingProfile) {
            throw new BadRequestException('User has already completed onboarding');
        }
        if (!user.gym) {
            throw new BadRequestException('User must be assigned to a Gym to complete onboarding');
        }

        // 2. Transactional Save
        const queryRunner = this.dataSource.createQueryRunner();
        await queryRunner.connect();
        await queryRunner.startTransaction();

        try {
            // A. Update User Fields
            const userUpdates: Partial<User> = {};
            if (dto.birthDate) userUpdates.birthDate = new Date(`${dto.birthDate}T12:00:00Z`);
            if (dto.phone) userUpdates.phone = dto.phone;
            if (dto.height) userUpdates.height = dto.height;
            if (dto.gender) userUpdates.gender = dto.gender;

            // If weight is provided, set initialWeight if null, and always update currentWeight
            if (dto.weight) {
                if (!user.initialWeight) userUpdates.initialWeight = dto.weight;
                userUpdates.currentWeight = dto.weight;
                userUpdates.weightUpdateDate = new Date();
            }
            if (dto.goal) userUpdates.trainingGoal = dto.goal; // Sync goal to User entity

            await queryRunner.manager.update(User, userId, userUpdates);

            // B. Create Onboarding Profile
            const profile = this.profileRepo.create({
                goal: dto.goal,
                goalDetails: dto.goalDetails,
                experience: dto.experience,
                injuries: dto.injuries,
                injuryDetails: dto.injuryDetails,
                activityLevel: dto.activityLevel,
                desiredFrequency: dto.desiredFrequency,
                preferences: dto.preferences,
                canLieDown: dto.canLieDown,
                canKneel: dto.canKneel,
                user: user,
                gym: user.gym,
            });

            const savedProfile = await queryRunner.manager.save(OnboardingProfile, profile);

            await queryRunner.commitTransaction();

            this.logger.log(`Onboarding completed for user ${userId}`);
            return savedProfile;

        } catch (err) {
            await queryRunner.rollbackTransaction();
            this.logger.error(`Failed to complete onboarding for ${userId}`, err);
            throw err;
        } finally {
            await queryRunner.release();
        }
    }

    async getProfile(userId: string): Promise<OnboardingProfile | null> {
        return this.profileRepo.findOne({
            where: { user: { id: userId } },
        });
    }

    async hasProfile(userId: string): Promise<boolean> {
        const count = await this.profileRepo.count({
            where: { user: { id: userId } }
        });
        return count > 0;
    }
}
