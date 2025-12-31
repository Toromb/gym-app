import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserStats } from './entities/user-stats.entity';
import { TrainingSession, ExecutionStatus } from '../plans/entities/training-session.entity';

@Injectable()
export class StatsService {
    constructor(
        @InjectRepository(UserStats)
        private statsRepo: Repository<UserStats>,
        @InjectRepository(TrainingSession)
        private sessionRepo: Repository<TrainingSession>,
    ) { }

    async updateStats(userId: string): Promise<UserStats> {
        // 1. Fetch Completed Sessions (Ordered)
        const history = await this.sessionRepo.find({
            where: {
                student: { id: userId },
                status: ExecutionStatus.COMPLETED,
            },
            order: { date: 'DESC' },
        });

        const count = history.length;

        // 2. Calculate Weekly (Current Week)
        const now = new Date();
        const d = new Date(now);
        const day = d.getDay();
        const diff = d.getDate() - day + (day == 0 ? -6 : 1); // Monday
        const monday = new Date(d.setDate(diff));
        monday.setHours(0, 0, 0, 0);

        const weekly = history.filter(h => new Date(h.date) >= monday).length;

        // 3. Calculate Streak (Consecutive)
        let streak = 0;
        const todayStr = new Date().toISOString().split('T')[0];
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        const yesterdayStr = yesterday.toISOString().split('T')[0];

        const uniqueDates = Array.from(new Set(history.map(h => {
            return typeof h.date === 'string' ? h.date : (h.date as Date).toISOString().split('T')[0];
        })));

        if (uniqueDates.length > 0) {
            // If most recent is today or yesterday, streak is alive
            if (uniqueDates[0] === todayStr || uniqueDates[0] === yesterdayStr) {
                streak = 1;
                let checkDate = new Date(uniqueDates[0]);

                for (let i = 1; i < uniqueDates.length; i++) {
                    const prevDate = new Date(uniqueDates[i]);

                    const diffTime = Math.abs(checkDate.getTime() - prevDate.getTime());
                    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

                    if (diffDays === 1) {
                        streak++;
                        checkDate = prevDate;
                    } else {
                        break;
                    }
                }
            }
        }

        // 4. Save
        let stats = await this.statsRepo.findOne({ where: { userId } });
        if (!stats) {
            stats = this.statsRepo.create({ userId });
        }

        stats.workoutCount = count;
        stats.weeklyWorkouts = weekly;
        stats.currentStreak = streak;
        if (history.length > 0) {
            const last = history[0];
            stats.lastWorkoutDate = last.finishedAt || new Date(last.date);
        }

        return this.statsRepo.save(stats);
    }
}
