import '../polyfill';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { DataSource } from 'typeorm';
import { Muscle, MuscleRegion, BodySide } from '../exercises/entities/muscle.entity';

const musclesData = [
    // TREN SUPERIOR (FRENTE)
    { name: 'Pecho', region: MuscleRegion.UPPER, bodySide: BodySide.FRONT, order: 1 },
    { name: 'Deltoides Anterior', region: MuscleRegion.UPPER, bodySide: BodySide.FRONT, order: 2 },
    { name: 'Bíceps', region: MuscleRegion.UPPER, bodySide: BodySide.FRONT, order: 3 },
    { name: 'Antebrazos', region: MuscleRegion.UPPER, bodySide: BodySide.FRONT, order: 4 },
    { name: 'Abdominales', region: MuscleRegion.CORE, bodySide: BodySide.FRONT, order: 5 },
    { name: 'Oblicuos', region: MuscleRegion.CORE, bodySide: BodySide.FRONT, order: 6 },
    // TREN SUPERIOR (ESPALDA)
    { name: 'Dorsales', region: MuscleRegion.UPPER, bodySide: BodySide.BACK, order: 7 },
    { name: 'Trapecios', region: MuscleRegion.UPPER, bodySide: BodySide.BACK, order: 8 }, // Common simplification or keep Upper Traps -> Trapecios Superiores? "Trapecios" is cleaner for app unless specific. stick to generic if fine, or specific. Let's use 'Trapecios' for Upper Traps generally or 'Trapecio Superior'. Let's use 'Trapecios'.
    { name: 'Trapecio Inferior', region: MuscleRegion.UPPER, bodySide: BodySide.BACK, order: 9 }, // Mid-Lower Traps
    { name: 'Romboides', region: MuscleRegion.UPPER, bodySide: BodySide.BACK, order: 10 },
    { name: 'Deltoides Posterior', region: MuscleRegion.UPPER, bodySide: BodySide.BACK, order: 11 },
    { name: 'Tríceps', region: MuscleRegion.UPPER, bodySide: BodySide.BACK, order: 12 },
    { name: 'Lumbares', region: MuscleRegion.CORE, bodySide: BodySide.BACK, order: 13 },
    // TREN INFERIOR (FRENTE)
    { name: 'Cuádriceps', region: MuscleRegion.LOWER, bodySide: BodySide.FRONT, order: 14 },
    { name: 'Aductores', region: MuscleRegion.LOWER, bodySide: BodySide.FRONT, order: 15 },
    { name: 'Tibial Anterior', region: MuscleRegion.LOWER, bodySide: BodySide.FRONT, order: 16 },
    // TREN INFERIOR (ESPALDA)
    { name: 'Glúteos', region: MuscleRegion.LOWER, bodySide: BodySide.BACK, order: 17 },
    { name: 'Isquiotibiales', region: MuscleRegion.LOWER, bodySide: BodySide.BACK, order: 18 },
    { name: 'Gemelos', region: MuscleRegion.LOWER, bodySide: BodySide.BACK, order: 19 },
];

export async function seedMuscles(dataSource: DataSource) {
    const muscleRepo = dataSource.getRepository(Muscle);

    console.log('🚀 Starting Muscle Seed...');

    for (const data of musclesData) {
        const existing = await muscleRepo.findOne({ where: { name: data.name } });
        if (existing) {
            // console.log(`✅ [SKIP] Muscle "${data.name}" already exists.`);
        } else {
            await muscleRepo.save(muscleRepo.create(data));
            console.log(`➕ [CREATED] Muscle "${data.name}"`);
        }
    }
    console.log('🏁 Muscle Seed Completed.');
}

if (require.main === module) {
    (async () => {
        const app = await NestFactory.createApplicationContext(AppModule);
        const dataSource = app.get(DataSource);
        await seedMuscles(dataSource);
        await app.close();
    })();
}
