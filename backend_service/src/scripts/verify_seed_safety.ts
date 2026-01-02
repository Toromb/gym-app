import '../polyfill';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { GymsService } from '../gyms/gyms.service';
import { ExercisesService } from '../exercises/exercises.service';
import { seedExerciseMuscles } from './seed-exercise-muscles';
import { DataSource } from 'typeorm';
import { Exercise } from '../exercises/entities/exercise.entity';
import { ExerciseMuscle, MuscleRole } from '../exercises/entities/exercise-muscle.entity';
import { Muscle } from '../exercises/entities/muscle.entity';

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const gymsService = app.get(GymsService);
    const dataSource = app.get(DataSource);
    const exerciseRepo = dataSource.getRepository(Exercise);
    const exerciseMuscleRepo = dataSource.getRepository(ExerciseMuscle);
    const muscleRepo = dataSource.getRepository(Muscle);

    console.log('🛡️ Starting Seed Safety Verification...');

    // 1. Setup Wrapper Gym
    const uniqueName = `Safety Test Gym ${Date.now()}`;
    const gym = await gymsService.create({
        businessName: uniqueName,
        address: 'Safety Lab',
        email: `safety${Date.now()}@gym.com`,
        maxProfiles: 5,
    });

    // 2. Setup Scenarios
    // Scenario A: "Banca Plana" - CUSTOM VALID (Modified to be 100% Pecho)
    const pecho = await muscleRepo.findOne({ where: { name: 'Pecho' } });
    if (!pecho) throw new Error('Muscle Pecho not found');

    const exValid = exerciseRepo.create({
        name: 'Banca Plana',
        description: 'Custom Valid Exercise',
        gym: gym,
        metricType: 'REPS',
        muscleGroup: 'Pecho'
    });
    const savedValid = await exerciseRepo.save(exValid);

    // Use create() for type safety
    const emValid = exerciseMuscleRepo.create({
        exercise: savedValid,
        muscle: pecho,
        role: MuscleRole.PRIMARY,
        loadPercentage: 100
    });
    await exerciseMuscleRepo.save(emValid);

    // Scenario B: "Sentadilla" - BROKEN (Modified to be 50% only)
    const cuad = await muscleRepo.findOne({ where: { name: 'Cuádriceps' } });
    if (!cuad) throw new Error('Muscle Cuádriceps not found');

    const exBroken = exerciseRepo.create({
        name: 'Sentadilla',
        description: 'Broken Exercise',
        gym: gym,
        metricType: 'REPS',
        muscleGroup: 'Cuádriceps'
    });
    const savedBroken = await exerciseRepo.save(exBroken);

    const emBroken = exerciseMuscleRepo.create({
        exercise: savedBroken,
        muscle: cuad,
        role: MuscleRole.PRIMARY,
        loadPercentage: 50
    });
    await exerciseMuscleRepo.save(emBroken);

    console.log('✅ Scenarios Prepared.');
    console.log('   - Banca Plana (Custom Valid): 100% Pecho');
    console.log('   - Sentadilla (Broken): 50% Cuadriceps');

    // 3. RUN THE SEED SCRIPT
    console.log('🚀 Running seedExerciseMuscles()...');
    try {
        await seedExerciseMuscles(dataSource);
    } catch (e) {
        console.error(e);
    }

    // 4. Verify Results
    console.log('🔍 Verifying Post-Seed State...');

    const checkValid = await exerciseRepo.findOne({
        where: { id: savedValid.id },
        relations: ['exerciseMuscles', 'exerciseMuscles.muscle']
    });

    const checkBroken = await exerciseRepo.findOne({
        where: { id: savedBroken.id },
        relations: ['exerciseMuscles', 'exerciseMuscles.muscle']
    });

    // Verification A
    const validTotal = checkValid?.exerciseMuscles.reduce((s, m) => s + m.loadPercentage, 0);
    const validCount = checkValid?.exerciseMuscles.length;
    // Should still be just 1 muscle (Pecho)
    if (validTotal === 100 && validCount === 1) {
        console.log('✅ PASS: Custom Valid Exercise was PRESERVED (Not Overwritten).');
    } else {
        console.error('❌ FAIL: Custom Valid Exercise was ALTERED.');
        if (checkValid) {
            console.log('Current State:', checkValid.exerciseMuscles.map(m => `${m.muscle.name}: ${m.loadPercentage}%`));
        }
    }

    // Verification B
    const brokenTotal = checkBroken?.exerciseMuscles.reduce((s, m) => s + m.loadPercentage, 0);
    const brokenCount = checkBroken?.exerciseMuscles.length;
    // Default Squat has 3 muscles
    if (brokenTotal === 100 && brokenCount === 3) {
        console.log('✅ PASS: Broken Exercise was REPAIRED (Reset to Defaults).');
    } else {
        console.error('❌ FAIL: Broken Exercise was NOT repaired correctly.');
        if (checkBroken) {
            console.log('Current State:', checkBroken.exerciseMuscles.map(m => `${m.muscle.name}: ${m.loadPercentage}%`));
        }
    }

    await app.close();
}

bootstrap();
