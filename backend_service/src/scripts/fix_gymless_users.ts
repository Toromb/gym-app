
import '../polyfill';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { Gym } from '../gyms/entities/gym.entity';
import { User } from '../users/entities/user.entity';
import { DataSource, IsNull } from 'typeorm';

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const dataSource = app.get(DataSource);
    const gymRepo = dataSource.getRepository(Gym);
    const userRepo = dataSource.getRepository(User);

    const gym = await gymRepo.findOne({ where: {} });
    if (!gym) {
        console.error('❌ No Gyms found in database! Can verify.');
        await app.close();
        return;
    }

    console.log(`🏢 Checkpoint: Using Gym '${gym.businessName}' (${gym.id})`);

    const users = await userRepo.find({
        where: { gym: IsNull() },
        relations: ['gym']
    });

    if (users.length === 0) {
        console.log('✅ No gymless users found.');
    } else {
        console.log(`⚠️ Found ${users.length} users without gym. Fixing...`);
        for (const u of users) {
            u.gym = gym;
            await userRepo.save(u);
            console.log(`   - Fixed: ${u.email}`);
        }
        console.log('✅ All fixed!');
    }

    await app.close();
}

bootstrap();
