import { TrainingGoal, ExperienceLevel, ActivityLevel, TrainingFrequency } from '../entities/onboarding-profile.entity';

export class OnboardingProfileDto {
    id: string;
    goal: TrainingGoal;
    goalDetails?: string;
    experience: ExperienceLevel;
    injuries: string[];
    injuryDetails?: string;
    activityLevel: ActivityLevel;
    desiredFrequency: TrainingFrequency;
    preferences?: string;
    createdAt: Date;
}
