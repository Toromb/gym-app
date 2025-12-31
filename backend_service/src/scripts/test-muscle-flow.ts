
import '../polyfill';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { TrainingSessionsService } from '../plans/training-sessions.service';

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const sessionsService = app.get(TrainingSessionsService);

    // Add logic here if needed

    await app.close();
}

bootstrap();
