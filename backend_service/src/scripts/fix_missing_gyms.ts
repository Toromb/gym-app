import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { UsersService } from '../users/users.service';
import { GymsService } from '../gyms/gyms.service';
import { UserRole } from '../users/entities/user.entity';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const userService = app.get(UsersService);
  const gymsService = app.get(GymsService);
  const { getRepositoryToken } = require('@nestjs/typeorm');
  const { User } = require('./users/entities/user.entity');
  const userRepository = app.get(getRepositoryToken(User));

  console.log('🔧 Running Global Gym Fix...');

  // 1. Find Default Gym
  const gyms = await gymsService.findAll();
  const defaultGym = gyms.find((g) => g.businessName === 'Default Gym');

  if (!defaultGym) {
    console.error('❌ Default Gym not found! Cannot proceed.');
    await app.close();
    return;
  }
  console.log(`✅ Default Gym found: ${defaultGym.businessName}`);

  // 2. Fetch ALL users (raw query to ensure we see relation state?)
  // Using Repository directly is safer for scanning.
  const allUsers = await userRepository.find({ relations: ['gym'] });
  console.log(`🔍 Scanning ${allUsers.length} users...`);

  let fixedCount = 0;

  for (const user of allUsers) {
    // Skip Super Admin (system level)
    if (user.role === UserRole.SUPER_ADMIN) {
      continue;
    }

    if (!user.gym) {
      console.log(`⚠️ User [${user.role}] ${user.email} has NO GYM. Fixing...`);
      user.gym = defaultGym;
      await userRepository.save(user);
      fixedCount++;
    }
  }

  console.log('--------------------------------------------------');
  console.log(`✅ Scan Complete. Fixed ${fixedCount} users.`);

  await app.close();
}

bootstrap();
