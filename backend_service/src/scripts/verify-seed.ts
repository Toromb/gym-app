import '../polyfill';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { DataSource } from 'typeorm';
import { Muscle } from '../exercises/entities/muscle.entity';
import { ExerciseMuscle } from '../exercises/entities/exercise-muscle.entity';

async function verify() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const dataSource = app.get(DataSource);

    const muscleCount = await dataSource.getRepository(Muscle).count();
    console.log(`💪 Total Muscles: ${muscleCount} (Expected: 19)`);

    const mappings = await dataSource.getRepository(ExerciseMuscle).find({
        relations: ['exercise', 'muscle'],
        take: 10,
    });

    console.log(`🔗 Total Sample Mappings found: ${mappings.length}`);
    if (mappings.length > 0) {
        console.log('Sample Mapping:');
        console.log(`  Exercise: ${mappings[0].exercise.name}`);
        console.log(`  Muscle: ${mappings[0].muscle.name} (${mappings[0].role})`);
    }

    await app.close();
}

verify();
