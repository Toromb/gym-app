
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { UsersService } from '../src/users/users.service';
import { DataSource } from 'typeorm';

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const usersService = app.get(UsersService);
    const dataSource = app.get(DataSource);

    console.log('Starting Migration: Set isActive=true for existing users with passwords...');

    try {
        const result = await dataSource
            .getRepository('User')
            .createQueryBuilder()
            .update()
            .set({ isActive: true })
            .where('passwordHash IS NOT NULL')
            .andWhere('isActive = :isActive', { isActive: false })
            .execute();

        console.log(`Migration Complete. Updated ${result.affected} users.`);
    } catch (e) {
        console.error('Migration Failed:', e);
    } finally {
        await app.close();
    }
}

bootstrap();
