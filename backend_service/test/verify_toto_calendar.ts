
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { ExecutionsService } from '../src/plans/executions.service';
import { User } from '../src/users/entities/user.entity';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

async function bootstrap() {
    const app = await NestFactory.create(AppModule);
    await app.init();

    const userRepo: Repository<User> = app.get(getRepositoryToken(User));
    const executionsService = app.get(ExecutionsService);

    const email = 'toto@gym.com';
    console.log(`Checking data for ${email}...`);

    const user = await userRepo.findOne({ where: { email } });
    if (!user) {
        console.error('User not found!');
        process.exit(1);
    }
    console.log(`User ID: ${user.id}`);

    // Check Calendar
    const from = '2025-12-01';
    const to = '2025-12-31';
    const history = await executionsService.getCalendar(user.id, from, to);

    console.log(`Found ${history.length} executions between ${from} and ${to}.`);
    history.forEach(ex => {
        console.log(`ID: ${ex.id} | Date: ${ex.date} | Status: ${ex.status}`);
    });

    await app.close();
    process.exit(0);
}

bootstrap().catch(err => {
    console.error(err);
    process.exit(1);
});
