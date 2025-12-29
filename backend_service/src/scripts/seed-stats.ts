
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { User } from '../users/entities/user.entity';
import { UserStats } from '../stats/entities/user-stats.entity';
import { TrainingSession, ExecutionStatus } from '../plans/entities/training-session.entity';

import { Repository } from 'typeorm';
import { getRepositoryToken } from '@nestjs/typeorm';
import { UserRole } from '../users/entities/user.entity';

async function bootstrap() {
    const app = await NestFactory.create(AppModule);

    const userRepo = app.get<Repository<User>>(getRepositoryToken(User));
    const statsRepo = app.get<Repository<UserStats>>(getRepositoryToken(UserStats));
    const sessionRepo = app.get<Repository<TrainingSession>>(getRepositoryToken(TrainingSession));

    console.log('--- SEEDING USER STATS ---');

    const users = await userRepo.find({ where: { role: UserRole.ALUMNO } });
    console.log(`Found ${users.length} students.`);

    for (const user of users) {
        const existing = await statsRepo.findOne({ where: { userId: user.id } });
        if (existing) {
            console.log(`Stats already exist for ${user.email}`);
            continue;
        }

        console.log(`Creating stats for ${user.email}...`);

        const sessions = await sessionRepo.find({
            where: { student: { id: user.id }, status: ExecutionStatus.COMPLETED },
            order: { date: 'DESC' }
        });

        const totalWorkouts = sessions.length;
        const lastWorkout = sessions.length > 0 ? new Date(sessions[0].date) : null;

        // Simple streak (consecutive days backward from last workout) - simplified
        let streak = 0;
        // ... (streak logic omit for now, just seed count)

        const newStats = statsRepo.create({
            userId: user.id,
            workoutCount: totalWorkouts,
            currentStreak: streak,
            lastWorkoutDate: lastWorkout
        } as any);
        await statsRepo.save(newStats);
    }

    console.log('--- SEEDING COMPLETE ---');
    await app.close();
}

bootstrap();
