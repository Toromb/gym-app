import '../polyfill';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { UsersService } from '../users/users.service';
import { GymsService } from '../gyms/gyms.service';
import { ExercisesService } from '../exercises/exercises.service';
import { UserRole } from '../users/entities/user.entity';
import { DataSource } from 'typeorm';
import { seedMuscles } from './seed-muscles';
import { seedExerciseMuscles } from './seed-exercise-muscles';
import { BASE_EXERCISES } from '../exercises/constants/base-exercises';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const dataSource = app.get(DataSource);

  // --- PROD SAFETY: DISABLED SCHEMA DROP ---
  // console.log('🧨 DROPPING SCHEMA (RESET REQUESTED)...');
  // await dataSource.query('DROP SCHEMA public CASCADE');
  // await dataSource.query('CREATE SCHEMA public');
  // await dataSource.query('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"');
  // await dataSource.synchronize(); 
  await dataSource.query('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'); // Ensure extension exists
  // -----------------------------------------

  const userService = app.get(UsersService);
  const gymsService = app.get(GymsService);

  console.log('➡️ Ejecutando SEED MASTER (Safe Mode)…');

  // 0. SEED MUSCLES
  await seedMuscles(dataSource);

  // 1. Create Default Gym if not exists
  const gyms = await gymsService.findAll();
  let defaultGym = gyms.find((g) => g.businessName === 'Default Gym');

  if (!defaultGym) {
    console.log('➕ Creando Default Gym (Migración)');
    defaultGym = await gymsService.create({
      businessName: 'Default Gym',
      address: 'System',
      email: 'system@default.com',
      maxProfiles: 1000,
    });
  } else {
    console.log('✅ Default Gym ya existe');
  }

  const users = [
    {
      firstName: 'Super',
      lastName: 'Admin',
      email: 'superadmin@gym.com',
      password: 'admin123',
      role: UserRole.SUPER_ADMIN,
    },
    {
      firstName: 'Admin',
      lastName: 'User',
      email: 'admin@gym.com',
      password: 'admin123',
      role: UserRole.ADMIN,
      gymId: defaultGym.id,
    },
    {
      firstName: 'Pedro',
      lastName: 'Alumno',
      email: 'alumno@gym.com',
      password: 'admin123',
      role: UserRole.ALUMNO,
      gymId: defaultGym.id,
    },
    {
      firstName: 'Juan',
      lastName: 'Profe',
      email: 'profe@gym.com',
      password: 'admin123',
      role: UserRole.PROFE,
      gymId: defaultGym.id,
    },
  ];

  for (const u of users) {
    const exists = await userService.findOneByEmail(u.email);

    if (exists) {
      // console.log(`⚠️ El usuario ${u.email} ya existe — se salta.`);
      continue;
    }

    console.log(`➕ Creando usuario: ${u.email}`);
    await userService.create(u);
  }

  // 2. Seed Exercises
  console.log('💪 Verificando Ejercicios (Ahora gestionados per-Gym)...');
  const exercisesService = app.get(ExercisesService);
  const exercises = await exercisesService.findAll();

  if (exercises.length === 0) {
    console.log('ℹ️ No existen ejercicios globales. Esto es correcto ahora.');
    // Logic handled by Gym Creation or manual per gym. 
    // Since we created Default Gym above using GymsService.create, 
    // if logic worked, Default Gym should have exercises!

    const gymExercises = await exercisesService.findAll(defaultGym.id);
    if (gymExercises.length === 0) {
      console.log('⚠️ Alerta: Default Gym no tiene ejercicios. Forzando población...');
      // Optional: Force populate if Gym existed before migration
      // Initialize Base Exercises for Default Gym if missing
      for (const baseEx of BASE_EXERCISES) {
        await exercisesService.createForGym(
          {
            name: baseEx.name,
            description: baseEx.description,
            muscles: baseEx.muscles.map(m => ({
              muscleId: m.name,
              role: m.role as any,
              loadPercentage: m.loadPercentage
            })),
            videoUrl: '',
            imageUrl: '',
          } as any,
          defaultGym
        );
      }
      console.log('✅ Ejercicios base inyectados a Default Gym.');
    } else {
      console.log(`✅ Default Gym ya tiene ${gymExercises.length} ejercicios propios.`);
    }

  } else {
    console.log(`✅ Sistema tiene ${exercises.length} ejercicios en total.`);
  }

  // 3. SEED MAPPINGS
  await seedExerciseMuscles(dataSource);

  console.log('✔️ SEED COMPLETADO');
  await app.close();
}

bootstrap();
