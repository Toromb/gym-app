import { User } from '../../users/entities/user.entity';
export declare class Exercise {
    id: string;
    name: string;
    description: string;
    videoUrl: string;
    imageUrl: string;
    createdBy: User;
    createdAt: Date;
    updatedAt: Date;
}
