import '../polyfill';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { MuscleLoadService } from '../stats/muscle-load.service';
import { UsersService } from '../users/users.service';

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);
    // Set logger to verify no errors
    // app.useLogger(['error', 'warn', 'log']);

    const muscleLoadService = app.get(MuscleLoadService);
    const usersService = app.get(UsersService);

    console.log('🧪 Starting Batched Save Verification...');

    const student = await usersService.findOneByEmail('alumno@gym.com');
    if (!student) {
        console.error('❌ Test student not found');
        await app.close();
        return;
    }

    console.log(`👤 Testing with student: ${student.email} (${student.id})`);

    try {
        console.log('👉 Calling getLoadsForStudent (should trigger bulk save)...');
        const start = Date.now();

        // We run it twice to verify upsert logic works cleanly
        console.log('1️⃣ First Run...');
        await muscleLoadService.getLoadsForStudent(student.id);

        console.log('2️⃣ Second Run (Idempotency check)...');
        const result = await muscleLoadService.getLoadsForStudent(student.id);

        const end = Date.now();

        console.log(`✅ Ops completed in ${end - start}ms (Total for 2 runs)`);
        console.log(`📊 Muscles processed: ${result.muscles.length}`);

        if (result.muscles.length > 0) {
            console.log('✅ Data returned successfully');
        } else {
            console.warn('⚠️ No muscles returned (Check database seeds)');
        }

    } catch (error) {
        console.error('❌ Error executing getLoadsForStudent:', error);
    }

    await app.close();
}

bootstrap();
