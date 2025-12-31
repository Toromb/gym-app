
import '../polyfill';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { DataSource } from 'typeorm';
import { UsersService } from '../users/users.service';

async function migrate() {
    console.log('🚀 Starting Training Session Migration...');

    const app = await NestFactory.createApplicationContext(AppModule);
    const dataSource = app.get(DataSource);
    const queryRunner = dataSource.createQueryRunner();
    await queryRunner.connect();

    try {
        // 1. Rename Tables
        console.log('📦 Checking for "plan_executions" table...');
        const hasPlanExecutions = await queryRunner.hasTable('plan_executions');
        const hasTrainingSessions = await queryRunner.hasTable('training_sessions');

        if (hasPlanExecutions && !hasTrainingSessions) {
            console.log('🔄 Renaming table "plan_executions" to "training_sessions"...');
            await queryRunner.renameTable('plan_executions', 'training_sessions');

            // Rename Indexes if necessary (Postgres usually handles this, but good to be aware)
            // We will let TypeORM sync handle index naming updates on next start

            // Update planId column to be nullable?
            // TypeORM Sync will likely handle the column definition update when we change the Entity code.
            // But we can preemptively do it if we want safety.
            // await queryRunner.query('ALTER TABLE training_sessions ALTER COLUMN "planId" DROP NOT NULL'); 
            // Let's leave strict schema changes to TypeORM sync to avoid conflicts.

            // Add 'source' column default 'PLAN'
            console.log('➕ Adding "source" column...');
            await queryRunner.query('ALTER TABLE training_sessions ADD COLUMN IF NOT EXISTS "source" VARCHAR DEFAULT \'PLAN\'');

            // Drop Unique Index explicitly if known content
            // await queryRunner.dropIndex('training_sessions', 'IDX_...'); 
            // We'll trust TypeORM to sync constraints.
        } else if (hasTrainingSessions) {
            console.log('✅ Table "training_sessions" already exists. Skipping rename.');
        } else {
            console.log('⚠️ Source table "plan_executions" not found! Is this a fresh install?');
        }

        // 2. Rename Exercise Executions
        console.log('📦 Checking for "exercise_executions" table...');
        const hasExerciseExecutions = await queryRunner.hasTable('exercise_executions');
        const hasSessionExercises = await queryRunner.hasTable('session_exercises');

        if (hasExerciseExecutions && !hasSessionExercises) {
            console.log('🔄 Renaming table "exercise_executions" to "session_exercises"...');
            await queryRunner.renameTable('exercise_executions', 'session_exercises');

            // Fix foreign key column naming if strict?
            // TypeORM maps "executionId" -> relationship. 
            // If we rename Entity from Execution -> Session, the FK might surely stay "executionId" unless we rename property.
            // We will rename property in Entity to "session", so TypeORM expects "sessionId".
            // SO WE MUST RENAME COLUMN too.
            console.log('🔄 Renaming FK column "executionId" to "sessionId"...');
            await queryRunner.renameColumn('session_exercises', 'executionId', 'sessionId');
        } else {
            console.log('✅ Table "session_exercises" already checked.');
        }

        // 3. User Stats Creation
        // We let TypeORM Sync create the table 'user_stats' when we start the app next time?
        // OR we create it now to seed it.
        // If we seed now, we need the table. 
        console.log('📊 Creating/Seeding UserStats...');
        const hasUserStats = await queryRunner.hasTable('user_stats');
        if (!hasUserStats) {
            console.log('➕ Creating "user_stats" table manually for seeding...');
            await queryRunner.query(`
         CREATE TABLE IF NOT EXISTS "user_stats" (
           "userId" uuid NOT NULL,
           "currentStreak" integer NOT NULL DEFAULT 0,
           "weeklyWorkouts" integer NOT NULL DEFAULT 0,
           "workoutCount" integer NOT NULL DEFAULT 0,
           "lastWorkoutDate" TIMESTAMP,
           CONSTRAINT "PK_user_stats" PRIMARY KEY ("userId")
         )
       `);
        }

        // 4. Calculate Stats
        console.log('🧮 Calculating Stats for all users...');
        const usersService = app.get(UsersService);
        const users = await usersService.findAllStudents(); // Use existing method to get all students

        // We need raw query to training_sessions because Entity is not mapped yet in code
        // (Code still thinks it is PlanExecution -> plan_executions, but we just renamed it!)
        // So we must use raw SQL.

        for (const user of users) {
            // Fetch completed sessions
            const history = await queryRunner.query(`
            SELECT * FROM training_sessions 
            WHERE "studentId" = $1 AND status = 'COMPLETED' 
            ORDER BY date DESC
        `, [user.id]);

            const count = history.length;
            if (count === 0) continue;

            const lastWorkout = history[0]; // Most recent
            const lastDate = lastWorkout.date; // YYYY-MM-DD string or Date object depending on driver

            // Weekly Count
            const now = new Date();
            // Calculate start of week (Monday)
            const d = new Date(now);
            const day = d.getDay();
            const diff = d.getDate() - day + (day == 0 ? -6 : 1); // adjust when day is sunday
            const monday = new Date(d.setDate(diff));
            monday.setHours(0, 0, 0, 0);

            const weekly = history.filter((h: any) => new Date(h.date) >= monday).length;

            // Streak Calculation (Strict Consecutive)
            let streak = 0;
            // Check if last workout was today or yesterday. If older, streak is 0.
            const todayStr = new Date().toISOString().split('T')[0];
            const yesterday = new Date(); yesterday.setDate(yesterday.getDate() - 1);
            const yesterdayStr = yesterday.toISOString().split('T')[0];

            // Map history dates to set of strings
            // history is ordered DESC.
            const uniqueDates = Array.from(new Set(history.map((h: any) => {
                // handle if date is string or date object
                // @ts-ignore
                return typeof h.date === 'string' ? h.date : new Date(h.date).toISOString().split('T')[0];
            })));

            // If most recent is not today/yesterday, streak broken
            if (uniqueDates[0] === todayStr || uniqueDates[0] === yesterdayStr) {
                streak = 1;
                // iterate backward
                let checkDate = new Date(uniqueDates[0]);

                for (let i = 1; i < uniqueDates.length; i++) {
                    const prevDate = new Date(uniqueDates[i] as string); // Cast to string

                    // Difference in days
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

            console.log(`👤 User ${user.email}: Count=${count}, Weekly=${weekly}, Streak=${streak}`);

            // Upsert
            await queryRunner.query(`
            INSERT INTO user_stats ("userId", "workoutCount", "weeklyWorkouts", "currentStreak", "lastWorkoutDate")
            VALUES ($1, $2, $3, $4, $5)
            ON CONFLICT ("userId") DO UPDATE SET
            "workoutCount" = $2,
            "weeklyWorkouts" = $3,
            "currentStreak" = $4,
            "lastWorkoutDate" = $5
        `, [user.id, count, weekly, streak, lastWorkout.finishedAt || new Date(lastWorkout.date)]);
        }

        console.log('✅ Migration & Seeding Completed successfully.');

    } catch (err) {
        console.error('❌ Migration Failed:', err);
        throw err;
    } finally {
        await queryRunner.release();
        await app.close();
    }
}

migrate();
