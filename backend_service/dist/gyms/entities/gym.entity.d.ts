import { User } from '../../users/entities/user.entity';
export declare enum GymPlan {
    BASIC = "basic",
    PRO = "pro",
    PREMIUM = "premium"
}
export declare enum GymStatus {
    ACTIVE = "active",
    SUSPENDED = "suspended"
}
export declare class Gym {
    id: string;
    businessName: string;
    address: string;
    phone: string;
    email: string;
    status: GymStatus;
    suspensionReason: string;
    subscriptionPlan: GymPlan;
    expirationDate: Date;
    maxProfiles: number;
    logoUrl: string;
    primaryColor: string;
    secondaryColor: string;
    welcomeMessage: string;
    openingHours: string;
    paymentAlias: string;
    paymentCbu: string;
    paymentAccountName: string;
    paymentBankName: string;
    paymentNotes: string;
    createdAt: Date;
    updatedAt: Date;
    users: User[];
}
