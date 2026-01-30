
import '../polyfill';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Muscle } from '../exercises/entities/muscle.entity';
import { DataSource } from 'typeorm';

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const dataSource = app.get(DataSource);
    const repo = dataSource.getRepository(Muscle);

    const count = await repo.count();
    console.log(`💪 Total Muscles in DB: ${count}`);

    if (count === 0) {
        console.error('❌ NO MUSCLES FOUND! You need to run the seed script.');
    } else {
        const muscles = await repo.find();
        console.log('✅ Muscles found:', muscles.map(m => m.name).join(', '));
    }

    await app.close();
}

bootstrap();
