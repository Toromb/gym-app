import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { UsersService } from '../users/users.service';
import { UserRole } from '../users/entities/user.entity';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const { getRepositoryToken } = require('@nestjs/typeorm');
  const { User } = require('../users/entities/user.entity');
  const userRepository = app.get(getRepositoryToken(User));

  console.log('🌱 Seeding Payment Statuses...');

  // Fetch Students and Professors
  const users = await userRepository.find({
    where: [{ role: UserRole.ALUMNO }, { role: UserRole.PROFE }],
  });

  console.log(`Found ${users.length} users to update.`);

  const now = new Date();
  let updatedCount = 0;

  for (let i = 0; i < users.length; i++) {
    const user = users[i];
    const scenario = i % 3; // 0: Paid, 1: Pending (Yellow), 2: Overdue (Red)

    const newExpiration = new Date();
    // Determine date based on scenario
    // Green: Expiration > Today (e.g., +15 days)
    // Yellow: Expiration < Today but within 10 days grace (e.g., -5 days)
    // Red: Expiration < Today and > 10 days grace (e.g., -20 days)

    let statusLabel = '';

    if (scenario === 0) {
      // PAID (Green)
      newExpiration.setDate(now.getDate() + 15);
      statusLabel = 'PAID (Green)';
    } else if (scenario === 1) {
      // PENDING (Yellow / Por Vencer)
      newExpiration.setDate(now.getDate() - 5);
      statusLabel = 'PENDING (Yellow)';
    } else {
      // OVERDUE (Red)
      newExpiration.setDate(now.getDate() - 20);
      statusLabel = 'OVERDUE (Red)';
    }

    user.membershipExpirationDate = newExpiration;
    // Also set start date just to be safe
    if (!user.membershipStartDate) {
      const start = new Date(newExpiration);
      start.setMonth(start.getMonth() - 1);
      user.membershipStartDate = start;
    }

    await userRepository.save(user);
    console.log(
      `User ${user.email} -> ${statusLabel} | Exp: ${newExpiration.toISOString().split('T')[0]}`,
    );
    updatedCount++;
  }

  console.log(`✅ Updated ${updatedCount} users.`);
  await app.close();
}

bootstrap();
