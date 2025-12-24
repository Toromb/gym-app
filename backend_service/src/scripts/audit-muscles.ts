import '../polyfill';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { DataSource } from 'typeorm';
import { Exercise } from '../exercises/entities/exercise.entity';
import { Muscle } from '../exercises/entities/muscle.entity';
import { ExerciseMuscle, MuscleRole } from '../exercises/entities/exercise-muscle.entity';

async function audit() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const dataSource = app.get(DataSource);

    const muscleRepo = dataSource.getRepository(Muscle);
    const exerciseRepo = dataSource.getRepository(Exercise);
    const exerciseMuscleRepo = dataSource.getRepository(ExerciseMuscle);

    console.log('📊 --- MUSCLE MAPPING AUDIT --- 📊');

    // 1. Muscles
    const muscleCount = await muscleRepo.count();
    console.log(`1️⃣  Muscles Total: ${muscleCount}`);

    // 2. Exercises
    const exercises = await exerciseRepo.find({
        relations: ['exerciseMuscles', 'exerciseMuscles.muscle']
    });
    console.log(`2️⃣  Exercises Total: ${exercises.length}`);

    let validCount = 0;
    let errorCount = 0;
    let legacySyncCount = 0;

    for (const ex of exercises) {
        if (!ex.exerciseMuscles || ex.exerciseMuscles.length === 0) {
            console.log(`   🟡 [WARN] Exercise "${ex.name}" has NO mapped muscles.`);
            continue;
        }

        const primaries = ex.exerciseMuscles.filter(em => em.role === MuscleRole.PRIMARY);
        const totalLoad = ex.exerciseMuscles.reduce((sum, em) => sum + em.loadPercentage, 0);
        const duplicateMuscles = new Set(ex.exerciseMuscles.map(em => em.muscle.id)).size !== ex.exerciseMuscles.length;

        let hasError = false;

        // Rule: Exactly 1 Primary
        if (primaries.length !== 1) {
            console.log(`   🔴 [ERR] "${ex.name}": Primaries count = ${primaries.length}`);
            hasError = true;
        }

        // Rule: Load = 100%
        if (totalLoad !== 100) {
            console.log(`   🔴 [ERR] "${ex.name}": Total Load = ${totalLoad}%`);
            hasError = true;
        }

        // Rule: No duplicates
        if (duplicateMuscles) {
            console.log(`   🔴 [ERR] "${ex.name}": contains Duplicate Muscles`);
            hasError = true;
        }

        // Rule: Legacy Sync
        if (primaries.length === 1) {
            if (ex.muscleGroup !== primaries[0].muscle.name) {
                console.log(`   🟠 [LEGACY MISMATCH] "${ex.name}": muscleGroup="${ex.muscleGroup}" vs Primary="${primaries[0].muscle.name}"`);
                // Note: This matches strictly. If casing differs it might flag.
            } else {
                legacySyncCount++;
            }
        }

        if (!hasError) validCount++;
        else errorCount++;
    }

    console.log(`\n3️⃣  Validation Results:`);
    console.log(`   ✅ Valid Exercises: ${validCount}`);
    console.log(`   ❌ Invalid Exercises: ${errorCount}`);
    console.log(`   🔄 Legacy Field Synced: ${legacySyncCount}`);

    // 4. Sample API Payload Structure
    if (validCount > 0) {
        const sample = exercises.find(e => e.exerciseMuscles.length > 0);
        console.log('\n4️⃣  Sample Payload (Internal representation):');
        const simplified = {
            name: sample?.name,
            muscleGroup: sample?.muscleGroup,
            muscles: sample?.exerciseMuscles.map(em => ({
                muscle: em.muscle.name,
                role: em.role,
                load: em.loadPercentage
            }))
        };
        console.log(JSON.stringify(simplified, null, 2));
    }

    await app.close();
}

audit();
