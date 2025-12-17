import { GymPlan, GymStatus } from '../entities/gym.entity';
export declare class CreateGymDto {
    businessName: string;
    address: string;
    phone?: string;
    email?: string;
    status?: GymStatus;
    suspensionReason?: string;
    subscriptionPlan?: GymPlan;
    expirationDate?: Date;
    maxProfiles?: number;
}
