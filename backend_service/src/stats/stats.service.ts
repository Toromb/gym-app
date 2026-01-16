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
            relations: ['exercises'],
            order: { date: 'DESC' },
        });

        // 2. Identify Pending Sessions for EXP
        const pendings = history.filter(s => !s.processedForExp);

        // 3. Process Pending EXP
        let stats = await this.statsRepo.findOne({ where: { userId } });
        if (!stats) {
            stats = this.statsRepo.create({ userId, totalExperience: 0, currentLevel: 1 });
        }

        // Ensure defaults
        if (stats.totalExperience === undefined) stats.totalExperience = 0;
        if (stats.currentLevel === undefined) stats.currentLevel = 1;

        // Current Week Buffer info
        const now = new Date();
        const d = new Date(now);
        const day = d.getDay();
        const diff = d.getDate() - day + (day == 0 ? -6 : 1);
        const monday = new Date(d.setDate(diff));
        monday.setHours(0, 0, 0, 0);

        // Calculate Weekly Workouts (All time, not just pending)
        const weeklyCount = history.filter(h => new Date(h.date) >= monday).length;

        // Bonus Logic Check
        // Week Key: "YYYY-WW"
        const getWeekKey = (date: Date) => {
            const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
            const dayNum = d.getUTCDay() || 7;
            d.setUTCDate(d.getUTCDate() + 4 - dayNum);
            const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
            const weekNo = Math.ceil((((d.getTime() - yearStart.getTime()) / 86400000) + 1) / 7);
            return `${d.getUTCFullYear()}-${weekNo}`;
        };
        const currentWeekKey = getWeekKey(new Date());

        for (const session of pendings) {
            // A. Volume EXP
            const vol = this._calculateVolume(session);
            const expVol = Math.floor(vol / 1000);

            // B. Session EXP
            const expSession = 10;

            // C. Bonus EXP
            // Rules: If weekly count >= 3 AND bonus not yet applied for THIS week.
            // But wait, we are iterating pendings. If we have multiple pendings for this week, we check state.
            // The 'weeklyCount' variable is static for the "now" moment. 
            // Better: Check if the session itself contributed to hitting the 3-mark? 
            // Simplification V1: If CURRENT weekly count is >= 3 and we haven't given bonus yet, give it now.
            // Tricky edge case: Bulk upload of 3 sessions. All are pending.
            // We just award once.

            let expBonus = 0;
            if (weeklyCount >= 3 && stats.lastBonusWeek !== currentWeekKey) {
                expBonus = 20;
                stats.lastBonusWeek = currentWeekKey;
            }

            stats.totalExperience += (expVol + expSession + expBonus);
            session.processedForExp = true;
        }

        // 4. Update Level
        stats.currentLevel = this._calculateLevel(stats.totalExperience);

        // 5. Save Sessions (processed status)
        if (pendings.length > 0) {
            await this.sessionRepo.save(pendings);
        }

        // 6. Recalculate Standard Stats (Streak, Counts) - Existing Logic
        const count = history.length;

        // ... streak logic ...
        let streak = 0;
        const todayStr = new Date().toISOString().split('T')[0];
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        const yesterdayStr = yesterday.toISOString().split('T')[0];

        const uniqueDates = Array.from(new Set(history.map(h => {
            return typeof h.date === 'string' ? h.date : (h.date as Date).toISOString().split('T')[0];
        })));

        if (uniqueDates.length > 0) {
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

        stats.workoutCount = count;
        stats.weeklyWorkouts = weeklyCount;
        stats.currentStreak = streak;
        if (history.length > 0) {
            const last = history[0];
            stats.lastWorkoutDate = last.finishedAt || new Date(last.date);
        }

        return this.statsRepo.save(stats);
    }

    // Helper: Calculate Level from EXP
    private _calculateLevel(exp: number): number {
        // Thresholds (Cumulative)
        // 1: 0
        // 5: 100
        // 10: 300
        // 20: 1300
        // ...
        // Let's implement a formula or lookup. 
        // User spec: 1->0, 5->100, 10->300, 20->1300, 30->3000, 40->6000, 50->10000.
        // Simple piecewise check for V1.

        if (exp < 100) return 1 + Math.floor(exp / 25); // 1..4
        if (exp < 300) return 5 + Math.floor((exp - 100) / 40); // 5..9
        if (exp < 1300) return 10 + Math.floor((exp - 300) / 100); // 10..19
        if (exp < 3000) return 20 + Math.floor((exp - 1300) / 170); // 20..29
        if (exp < 6000) return 30 + Math.floor((exp - 3000) / 300); // 30..39
        if (exp < 10000) return 40 + Math.floor((exp - 6000) / 400); // 40..49
        if (exp < 16000) return 50 + Math.floor((exp - 10000) / 600); // 50..59
        if (exp < 30000) return 60 + Math.floor((exp - 16000) / 700); // 60..79
        if (exp < 50000) return 80 + Math.floor((exp - 30000) / 1000); // 80..99

        return 100 + Math.floor((exp - 50000) / 2000); // 100+
    }

    _calculateVolume(session: TrainingSession): number {
        let vol = 0;
        if (!session.exercises) return 0;

        for (const ex of session.exercises) {
            if (!ex.isCompleted) continue;

            const parse = (str: string) => {
                if (!str) return [];
                return str.toString().split(',').map(s => parseFloat(s.trim()) || 0);
            };

            const sets = parse(ex.setsDone);
            const reps = parse(ex.repsDone);
            let weights = parse(ex.weightUsed);

            let count = Math.max(sets.length, reps.length, weights.length);
            if (sets.length === 1 && sets[0] > count) {
                count = sets[0];
            }

            for (let i = 0; i < count; i++) {
                const r = reps[i] !== undefined ? reps[i] : (reps[0] || 0);
                const w = weights[i] !== undefined ? weights[i] : (weights[0] || 0);
                vol += r * w;
            }
        }
        return vol;
    }

    async getProgress(userId: string) {
        // 1. Fetch User
        const user = await this.userRepo.findOne({ where: { id: userId } });
        if (!user) throw new Error('User not found');

        // 2. Fetch UserStats for Level info
        const stats = await this.statsRepo.findOne({ where: { userId } });
        const currentLevel = stats?.currentLevel || 1;
        const totalExp = stats?.totalExperience || 0;

        // 3. Fetch All Completed Sessions
        const sessions = await this.sessionRepo.find({
            where: {
                student: { id: userId },
                status: ExecutionStatus.COMPLETED,
            },
            relations: ['exercises'],
            order: { date: 'ASC' },
        });

        // 4. Calculate Volumes
        let lifetimeVolume = 0;
        const volumeHistory: { date: string; volume: number }[] = [];
        const monthlyVolume = new Map<string, number>();
        let thisWeekVolume = 0;
        let thisMonthVolume = 0;

        const now = new Date();
        const fourWeeksAgo = new Date();
        fourWeeksAgo.setDate(fourWeeksAgo.getDate() - 28);
        const d = new Date(now);
        const day = d.getDay();
        const diff = d.getDate() - day + (day == 0 ? -6 : 1);
        const monday = new Date(d.setDate(diff));
        monday.setHours(0, 0, 0, 0);

        for (const session of sessions) {
            const vol = this._calculateVolume(session);
            lifetimeVolume += vol;
            const date = new Date(session.date);

            if (date.getMonth() === now.getMonth() && date.getFullYear() === now.getFullYear()) {
                thisMonthVolume += vol;
            }
            if (date >= monday) {
                thisWeekVolume += vol;
            }
            if (date >= fourWeeksAgo) {
                const sDay = date.getDay();
                const sDiff = date.getDate() - sDay + (sDay == 0 ? -6 : 1);
                const sMonday = new Date(date.setDate(sDiff));
                const key = sMonday.toISOString().split('T')[0];
                const current = monthlyVolume.get(key) || 0;
                monthlyVolume.set(key, current + vol);
            }
        }

        const chartData = Array.from(monthlyVolume.entries())
            .map(([date, vol]) => ({ date, volume: vol }))
            .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());

        // 5. Calculate Average/Total
        const weeklyAverage = (() => {
            if (sessions.length === 0) return 0;
            const firstSession = new Date(sessions[0].date);
            const now = new Date();
            const diffTime = Math.abs(now.getTime() - firstSession.getTime());
            const diffWeeks = diffTime / (1000 * 60 * 60 * 24 * 7);
            const weeks = Math.max(1, diffWeeks);
            return parseFloat((sessions.length / weeks).toFixed(1));
        })();

        return {
            level: {
                current: currentLevel,
                exp: totalExp,
                // Optional: nextLevelExp logic here or frontend
            },
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
                thisMonth: sessions.filter(s => {
                    const d = new Date(s.date);
                    const n = new Date();
                    return d.getMonth() === n.getMonth() && d.getFullYear() === n.getFullYear();
                }).length,
                thisWeek: sessions.filter(s => new Date(s.date) >= monday).length,
                weeklyAverage: weeklyAverage
            }
        };
    }
}
