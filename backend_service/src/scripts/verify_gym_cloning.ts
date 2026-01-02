import '../polyfill';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { GymsService } from '../gyms/gyms.service';
import { ExercisesService } from '../exercises/exercises.service';
import { DataSource } from 'typeorm';

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const gymsService = app.get(GymsService);
    const exercisesService = app.get(ExercisesService);

    console.log('🧪 Starting Verification: Gym Cloning...');

    // 1. Create a Test Gym
    const uniqueName = `Test Gym ${Date.now()}`;
    console.log(`Creating Gym: ${uniqueName}`);

    const gym = await gymsService.create({
        businessName: uniqueName,
        address: 'Test Address',
        email: `test${Date.now()}@gym.com`,
        maxProfiles: 10,
    });

    console.log(`✅ Gym Created: ID ${gym.id}`);

    // 2. Verify Exercises
    console.log('Verifying Exercises...');
    const exercises = await exercisesService.findAll(gym.id);

    if (exercises.length > 0) {
        console.log(`✅ SUCCESS: Found ${exercises.length} exercises for the new gym.`);
        exercises.slice(0, 3).forEach(e => console.log(` - ${e.name} (MuscleGroup: ${e.muscleGroup})`));
    } else {
        console.error('❌ FAILURE: No exercises found for the new gym.');
        process.exit(1);
    }

    await app.close();
    process.exit(0);
}

bootstrap();
