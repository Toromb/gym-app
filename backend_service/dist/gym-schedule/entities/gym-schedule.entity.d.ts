import { Gym } from '../../gyms/entities/gym.entity';
export declare class GymSchedule {
    id: number;
    dayOfWeek: string;
    isClosed: boolean;
    openTimeMorning: string | null;
    closeTimeMorning: string | null;
    openTimeAfternoon: string | null;
    closeTimeAfternoon: string | null;
    notes: string | null;
    gym: Gym;
}
