import '../polyfill';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { DataSource } from 'typeorm';
import { Exercise } from '../exercises/entities/exercise.entity';
import { Muscle } from '../exercises/entities/muscle.entity';
import { ExerciseMuscle, MuscleRole } from '../exercises/entities/exercise-muscle.entity';

// EXERCICIO: "Bench Press" -> Chest (P), Triceps (S), Front Deltoid (S)
// ... (omitting comments for brevity in source, but keeping logic)

const mappings = [
    {
        exercise: 'Banca Plana', // Bench Press
        muscles: [
            { name: 'Pecho', role: MuscleRole.PRIMARY, load: 70 },
            { name: 'Tríceps', role: MuscleRole.SECONDARY, load: 15 },
            { name: 'Deltoides Anterior', role: MuscleRole.SECONDARY, load: 15 },
        ]
    },
    {
        exercise: 'Sentadilla', // Squat
        muscles: [
            { name: 'Cuádriceps', role: MuscleRole.PRIMARY, load: 60 },
            { name: 'Glúteos', role: MuscleRole.SECONDARY, load: 20 },
            { name: 'Isquiotibiales', role: MuscleRole.SECONDARY, load: 20 },
        ]
    },
    {
        exercise: 'Peso Muerto', // Deadlift
        muscles: [
            { name: 'Glúteos', role: MuscleRole.PRIMARY, load: 50 },
            { name: 'Isquiotibiales', role: MuscleRole.SECONDARY, load: 30 },
            { name: 'Lumbares', role: MuscleRole.SECONDARY, load: 20 },
        ]
    },
    {
        exercise: 'Dominadas', // Pull Ups
        muscles: [
            { name: 'Dorsales', role: MuscleRole.PRIMARY, load: 60 },
            { name: 'Bíceps', role: MuscleRole.SECONDARY, load: 20 },
            { name: 'Romboides', role: MuscleRole.SECONDARY, load: 20 },
        ]
    },
    {
        exercise: 'Remo con Barra', // Barbell Row
        muscles: [
            { name: 'Dorsales', role: MuscleRole.PRIMARY, load: 60 },
            { name: 'Romboides', role: MuscleRole.SECONDARY, load: 20 },
            { name: 'Deltoides Posterior', role: MuscleRole.SECONDARY, load: 20 },
        ]
    },
    {
        exercise: 'Press Militar', // Shoulder Press
        muscles: [
            { name: 'Deltoides Anterior', role: MuscleRole.PRIMARY, load: 60 },
            { name: 'Tríceps', role: MuscleRole.SECONDARY, load: 20 },
            { name: 'Trapecios', role: MuscleRole.SECONDARY, load: 20 },
        ]
    },
    {
        exercise: 'Curl de Biceps', // Biceps Curl
        muscles: [
            { name: 'Bíceps', role: MuscleRole.PRIMARY, load: 80 },
            { name: 'Antebrazos', role: MuscleRole.SECONDARY, load: 20 },
        ]
    },
    {
        exercise: 'Triceps en Polea', // Triceps Pushdown
        muscles: [
            { name: 'Tríceps', role: MuscleRole.PRIMARY, load: 100 },
        ]
    },
    {
        exercise: 'Plancha Abdominal', // Plank
        muscles: [
            { name: 'Abdominales', role: MuscleRole.PRIMARY, load: 70 },
            { name: 'Lumbares', role: MuscleRole.SECONDARY, load: 30 },
        ]
    },
    {
        exercise: 'Estocadas', // Lunges
        muscles: [
            { name: 'Cuádriceps', role: MuscleRole.PRIMARY, load: 60 },
            { name: 'Glúteos', role: MuscleRole.SECONDARY, load: 40 },
        ]
    }
];

export async function seedExerciseMuscles(dataSource: DataSource) {
    const exerciseRepo = dataSource.getRepository(Exercise);
    const muscleRepo = dataSource.getRepository(Muscle);
    const exerciseMuscleRepo = dataSource.getRepository(ExerciseMuscle);

    console.log('🔗 Starting Exercise-Muscle Mapping Seed...');

    for (const map of mappings) {
        // 1. Find Exercise
        const exercise = await exerciseRepo.createQueryBuilder('exercise')
            .leftJoinAndSelect('exercise.exerciseMuscles', 'exerciseMuscles')
            .where('LOWER(exercise.name) = LOWER(:name)', { name: map.exercise })
            .getOne();

        if (!exercise) {
            console.log(`⚠️ [SKIP] Exercise "${map.exercise}" not found.`);
            continue;
        }

        // 2. Check if already has muscles
        if (exercise.exerciseMuscles && exercise.exerciseMuscles.length > 0) {
            const totalLoad = exercise.exerciseMuscles.reduce((sum, em) => sum + em.loadPercentage, 0);

            if (totalLoad === 100) {
                console.log(`✅ [SKIP] Exercise "${exercise.name}" is valid (100% load).`);
                continue;
            } else {
                console.log(`⚠️ [REPAIR] Exercise "${exercise.name}" has invalid load (${totalLoad}%). Re-seeding...`);
                // Delete existing to re-create correctly
                await exerciseMuscleRepo.delete({ exercise: { id: exercise.id } });
            }
        }

        console.log(`Processing "${exercise.name}"...`);
        let primaryMuscleName = '';

        for (const item of map.muscles) {
            const muscle = await muscleRepo.findOne({ where: { name: item.name } });
            if (!muscle) {
                console.error(`  ❌ Muscle "${item.name}" not found!`);
                continue;
            }

            if (item.role === MuscleRole.PRIMARY) {
                primaryMuscleName = muscle.name;
            }

            await exerciseMuscleRepo.save(exerciseMuscleRepo.create({
                exercise: exercise,
                muscle: muscle,
                role: item.role,
                loadPercentage: item.load,
            }));
            console.log(`  ➕ Mapped "${muscle.name}" (${item.load}%)`);
        }

        // 3. Sync Legacy muscleGroup if missing
        if (!exercise.muscleGroup && primaryMuscleName) {
            console.log(`  🔧 Syncing Legacy muscleGroup to "${primaryMuscleName}"`);
            await exerciseRepo.update(exercise.id, { muscleGroup: primaryMuscleName });
        }
    }
    console.log('🏁 Mapping Seed Completed.');
}

if (require.main === module) {
    (async () => {
        const app = await NestFactory.createApplicationContext(AppModule);
        const dataSource = app.get(DataSource);
        await seedExerciseMuscles(dataSource);
        await app.close();
    })();
}
