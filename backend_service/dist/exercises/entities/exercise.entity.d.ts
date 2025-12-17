import { User } from '../../users/entities/user.entity';
export declare class Exercise {
    id: string;
    name: string;
    description: string;
    videoUrl: string;
    imageUrl: string;
    muscleGroup?: string;
    type?: string;
    sets?: number;
    reps?: string;
    rest?: string;
    load?: string;
    notes?: string;
    createdBy: User;
    createdAt: Date;
    updatedAt: Date;
}
