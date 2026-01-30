
import '../polyfill';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';

import { User } from '../users/entities/user.entity';
import { DataSource, IsNull } from 'typeorm';

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const dataSource = app.get(DataSource);
    const repo = dataSource.getRepository(User);

    const gymless = await repo.find({
        where: { gym: IsNull() },
        relations: ['gym']
    });

    console.log(`⚠️ Found ${gymless.length} users without a Gym:`);
    gymless.forEach(u => console.log(`   - ${u.firstName} ${u.lastName} (${u.email}) [Role: ${u.role}]`));

    await app.close();
}

bootstrap();
