
import '../polyfill';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { Gym } from '../gyms/entities/gym.entity';
import { DataSource } from 'typeorm';

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const dataSource = app.get(DataSource);
    const repo = dataSource.getRepository(Gym);

    const gyms = await repo.find();
    console.log(`Available Gyms:`);
    gyms.forEach(g => console.log(` - ${g.businessName} (ID: ${g.id})`));

    await app.close();
}

bootstrap();
