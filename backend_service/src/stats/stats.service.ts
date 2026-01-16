import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserStats } from './entities/user-stats.entity';
import { TrainingSession, ExecutionStatus } from '../plans/entities/training-session.entity';
import { User } from '../users/entities/user.entity';

@Injectable()
export class StatsService {
    constructor(
        @InjectRepository(UserStats)
        private statsRepo: Repository<UserStats>,
        @InjectRepository(TrainingSession)
        private sessionRepo: Repository<TrainingSession>,
        @InjectRepository(User)
        private userRepo: Repository<User>,
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

    async getProgress(userId: string) {
        // 1. Fetch User for Weight Info
        const user = await this.userRepo.findOne({ where: { id: userId } });
        if (!user) throw new Error('User not found');

        // 2. Fetch All Completed Sessions with Exercises
        const sessions = await this.sessionRepo.find({
            where: {
                student: { id: userId },
                status: ExecutionStatus.COMPLETED,
            },
            relations: ['exercises'],
            order: { date: 'ASC' },
        });

        // 3. Calculate Volume
        let lifetimeVolume = 0;
        const volumeHistory: { date: string; volume: number }[] = [];

        // Helper to parse volume from a session
        const calculateSessionVolume = (session: TrainingSession) => {
            let vol = 0;
            if (!session.exercises) return 0;

            for (const ex of session.exercises) {
                if (!ex.isCompleted) continue;

                // Parse sets, reps, weight
                // Formats: "10,10,10" or "10"
                const parse = (str: string) => {
                    if (!str) return [];
                    return str.toString().split(',').map(s => parseFloat(s.trim()) || 0);
                };

                const sets = parse(ex.setsDone);
                const reps = parse(ex.repsDone);
                // Priority: weightUsed (Total), then addedWeight (Lastre), then 0.
                // Note: user might input just '10', implying constant weight for all sets.
                let weights = parse(ex.weightUsed);

                // Fallback logic if weights array is empty but addedWeight exists?
                // For now, adhere to scope "Simple Parse"

                // Identify max updated length (should be sets count)
                // Fix: If setsDone is a single number (e.g. "3"), it represents the iteration count.
                // If it's a list (e.g. "10,12,10"), the length is the count.
                let count = Math.max(sets.length, reps.length, weights.length);
                if (sets.length === 1 && sets[0] > count) {
                    count = sets[0];
                }

                for (let i = 0; i < count; i++) {
                    const r = reps[i] !== undefined ? reps[i] : (reps[0] || 0);
                    const w = weights[i] !== undefined ? weights[i] : (weights[0] || 0);
                    // Standard Volume = Reps * Weight
                    vol += r * w;
                }
            }
            return vol;
        };

        // Monthly aggregation map
        const monthlyVolume = new Map<string, number>(); // Key: YYYY-MM-Week
        let thisWeekVolume = 0;
        let thisMonthVolume = 0;

        // Filter for chart: Last 4 Weeks
        const now = new Date();
        const fourWeeksAgo = new Date();
        fourWeeksAgo.setDate(fourWeeksAgo.getDate() - 28);

        // Helper for "This Week" check
        const d = new Date(now);
        const day = d.getDay();
        const diff = d.getDate() - day + (day == 0 ? -6 : 1); // Monday
        const monday = new Date(d.setDate(diff));
        monday.setHours(0, 0, 0, 0);

        for (const session of sessions) {
            const vol = calculateSessionVolume(session);
            lifetimeVolume += vol;

            const date = new Date(session.date);

            // This Month calculation
            if (date.getMonth() === now.getMonth() && date.getFullYear() === now.getFullYear()) {
                thisMonthVolume += vol;
            }

            // This Week calculation
            if (date >= monday) {
                thisWeekVolume += vol;
            }

            // Chart Data (Last 4 weeks)
            if (date >= fourWeeksAgo) {
                // Group by Week? Or just by Session?
                // Spec: "Volume Chart showing volume per week".
                // Let's get "Week Number" or "Start of Week Date"
                const sDay = date.getDay();
                const sDiff = date.getDate() - sDay + (sDay == 0 ? -6 : 1); // Monday
                const sMonday = new Date(date.setDate(sDiff));
                const key = sMonday.toISOString().split('T')[0]; // YYYY-MM-DD (Monday)

                const current = monthlyVolume.get(key) || 0;
                monthlyVolume.set(key, current + vol);
            }
        }

        // Convert Map to Array
        const chartData = Array.from(monthlyVolume.entries())
            .map(([date, vol]) => ({ date, volume: vol }))
            .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());

        return {
            weight: {
                initial: user.initialWeight || 0,
                current: user.currentWeight || 0,
                change: (user.currentWeight || 0) - (user.initialWeight || 0),
            },
            volume: {
                lifetime: lifetimeVolume,
                thisWeek: thisWeekVolume,
                thisMonth: thisMonthVolume,
                chart: chartData,
            },
            workouts: {
                total: sessions.length,
                // "Days trained this month"
                thisMonth: sessions.filter(s => {
                    const d = new Date(s.date);
                    const n = new Date();
                    return d.getMonth() === n.getMonth() && d.getFullYear() === n.getFullYear();
                }).length,
                // "Days trained this week" (Logic from updateStats)
                thisWeek: sessions.filter(s => {
                    const now = new Date();
                    const d = new Date(now);
                    const day = d.getDay();
                    const diff = d.getDate() - day + (day == 0 ? -6 : 1); // Monday
                    const monday = new Date(d.setDate(diff));
                    monday.setHours(0, 0, 0, 0);
                    return new Date(s.date) >= monday;
                }).length,
                weeklyAverage: (() => {
                    if (sessions.length === 0) return 0;
                    const firstSession = new Date(sessions[0].date); // Sessions are ordered ASC
                    const now = new Date();
                    const diffTime = Math.abs(now.getTime() - firstSession.getTime());
                    const diffWeeks = diffTime / (1000 * 60 * 60 * 24 * 7);
                    // Avoid division by small numbers if first session was just now. 
                    // Min 1 week denominator to avoid inflated averages for new users.
                    const weeks = Math.max(1, diffWeeks);
                    return parseFloat((sessions.length / weeks).toFixed(1));
                })()
            }
        };
    }
}
