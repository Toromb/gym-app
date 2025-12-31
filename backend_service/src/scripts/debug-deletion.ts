
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { DataSource } from 'typeorm';
import { Plan } from '../plans/entities/plan.entity';
import { StudentPlan } from '../plans/entities/student-plan.entity';
import { User } from '../users/entities/user.entity';
import { Exercise } from '../exercises/entities/exercise.entity';

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const dataSource = app.get(DataSource);

    const targetEmail = 'prof_exec_1765690454481@test.com';
    const user = await dataSource.getRepository(User).findOne({ where: { email: targetEmail } });

    if (!user) {
        console.log(`Target user ${targetEmail} NOT FOUND in DB.`);
        await app.close();
        return;
    }
    const userId = user.id;

    // Find a plan to test deletion (just grab the first one found)
    const plan = await dataSource.getRepository(Plan).findOne({});
    const planId = plan ? plan.id : 'unknown';

    // Find an exercise to test deletion
    const exercise = await dataSource.getRepository(Exercise).findOne({});
    const exerciseId = exercise ? exercise.id : 'unknown';

    console.log('\n--- ATTEMPTING DELETION SIMULATION ---');
    const queryRunner = dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
        // 1. Try Delete Plan
        console.log(`\n[Attempting Plan Deletion: ${planId}]`);
        const assignments = await queryRunner.manager.find(StudentPlan, { where: { plan: { id: planId }, isActive: true } });
        if (assignments.length > 0) {
            console.log(`BLOCKED: ${assignments.length} active assignments found.`);
        } else {
            console.log('No active assignments. Proceeding to delete...');
            await queryRunner.manager.delete(Plan, planId);
            console.log('SUCCESS: Plan deleted (simulated)');
        }

    } catch (err) {
        console.error('FAILED PLAN MSG:', err.message);
        if (err.detail) console.error('DETAIL:', err.detail);
        if (err.table) console.error('TABLE:', err.table);
        if (err.constraint) console.error('CONSTRAINT:', err.constraint);
    }

    try {
        // 2. Try Delete User
        console.log(`\n[Attempting User Deletion: ${userId}]`);
        await queryRunner.manager.delete(User, userId);
        console.log('SUCCESS: User deleted (simulated)');
    } catch (err) {
        console.error('FAILED USER MSG:', err.message);
        if (err.detail) console.error('DETAIL:', err.detail);
        if (err.table) console.error('TABLE:', err.table);
        if (err.constraint) console.error('CONSTRAINT:', err.constraint);
    }

    try {
        // 3. Try Delete Exercise (Find one first)
        console.log(`\n[Attempting Exercise Deletion]`);
        const exercise = await queryRunner.manager.findOne(Exercise, { where: { createdBy: { id: userId } } });
        if (exercise) {
            console.log(`Found Exercise: ${exercise.name} (${exercise.id})`);
            await queryRunner.manager.delete(Exercise, exercise.id);
            console.log('SUCCESS: Exercise deleted (simulated)');
        } else {
            console.log('No exercises found for this user to test.');
        }
    } catch (err) {
        console.error('FAILED EXERCISE MSG:', err.message);
        if (err.detail) console.error('DETAIL:', err.detail);
        if (err.table) console.error('TABLE:', err.table);
        if (err.constraint) console.error('CONSTRAINT:', err.constraint);
    }

    // Always rollback for safety in debug script
    await queryRunner.rollbackTransaction();
    await queryRunner.release();

    await app.close();
}

bootstrap();
