
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { TrainingSession } from '../plans/entities/training-session.entity';
import { UserStats } from '../stats/entities/user-stats.entity';
import { Repository } from 'typeorm';
import { getRepositoryToken } from '@nestjs/typeorm';
import { UserRole } from '../users/entities/user.entity';

async function bootstrap() {
    const app = await NestFactory.create(AppModule);
    // No need to listen

    const sessionRepo = app.get<Repository<TrainingSession>>(getRepositoryToken(TrainingSession));
    const statsRepo = app.get<Repository<UserStats>>(getRepositoryToken(UserStats));

    console.log('--- VERIFICATION START ---');

    // 1. Verify Historical Sessions
    const allSessions = await sessionRepo.find({
        take: 5,
        order: { date: 'DESC' },
        relations: ['plan']
    });
    console.log(`Found ${allSessions.length} total sessions (showing last 5).`);
    allSessions.forEach(s => {
        console.log(`- ID: ${s.id}, Date: ${s.date}, Status: ${s.status}, Source: ${s.source}, PlanID: ${s.plan?.id ?? 'NULL'}`);
    });

    // 2. Verify Free vs Plan Differentiation
    const freeSessions = await sessionRepo.find({ where: { source: 'FREE' }, take: 2 });
    const planSessions = await sessionRepo.find({ where: { source: 'PLAN' }, take: 2 });

    console.log('\n--- SOURCE DIFFERENTIATION ---');
    console.log(`Free Sessions found: ${freeSessions.length}`);
    freeSessions.forEach(s => console.log(`  [FREE] ID: ${s.id}, Plan: ${s.plan}`));

    console.log(`Plan Sessions found: ${planSessions.length}`);
    planSessions.forEach(s => console.log(`  [PLAN] ID: ${s.id}, Plan ID: ${s.plan?.id}`));

    if (freeSessions.length > 0 && freeSessions.every(s => s.plan === null)) {
        console.log('SUCCESS: Free sessions have null plan.');
    }

    // 3. Verify UserStats
    const stats = await statsRepo.find({ take: 5 });
    console.log('\n--- USER STATS ---');
    console.log(`Found ${stats.length} stats records.`);
    stats.forEach(s => {
        console.log(`- User: ${s.userId}, Total Workouts: ${s.workoutCount}, Current Streak: ${s.currentStreak}, Last Workout: ${s.lastWorkoutDate}`);
    });

    console.log('--- VERIFICATION END ---');
    await app.close();
}

bootstrap();
