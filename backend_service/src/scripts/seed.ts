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
  console.log('💪 Verificando Ejercicios...');
  const exercisesService = app.get(ExercisesService);
  const exercises = await exercisesService.findAll();

  if (exercises.length === 0) {
    console.log('➕ Creando Ejercicios Base...');
    const adminUser = await userService.findOneByEmail('admin@gym.com');

    if (!adminUser?.gym) {
      console.error(
        '❌ CRITICAL: Admin user has no Gym! Cannot seed exercises correctly.',
      );
    } else {
      const defaultExercises = [
        { name: 'Sentadilla', description: 'Pierna completa' },
        { name: 'Peso Muerto', description: 'Cadena posterior' },
        { name: 'Banca Plana', description: 'Pecho' },
        { name: 'Dominadas', description: 'Espalda' },
        { name: 'Press Militar', description: 'Hombros' },
        { name: 'Remo con Barra', description: 'Espalda' },
        { name: 'Estocadas', description: 'Piernas' },
        { name: 'Curl de Biceps', description: 'Brazos' },
        { name: 'Triceps en Polea', description: 'Brazos' },
        { name: 'Plancha Abdominal', description: 'Core' },
      ];

      for (const ex of defaultExercises) {
        await exercisesService.create(
          {
            name: ex.name,
            description: ex.description,
            videoUrl: '',
            imageUrl: '',
            // No muscleGroup info here, it will be fixed by step 3
          } as any, // Cast to any to bypass DTO validation if strict
          adminUser,
        );
      }
    }
  } else {
    console.log('✅ Ejercicios ya existen. Verificando integridad...');
    let fixedCount = 0;
    for (const ex of exercises) {
      if (!ex.gym) {
        if (defaultGym) {
          await dataSource
            .getRepository('Exercise')
            .update(ex.id, { gym: defaultGym });
          fixedCount++;
        }
      }
    }
    if (fixedCount > 0) {
      console.log(`🔧 ${fixedCount} ejercicios huérfanos fueron asignados a "Default Gym".`);
    }
  }

  // 3. SEED MAPPINGS
  await seedExerciseMuscles(dataSource);

  console.log('✔️ SEED COMPLETADO');
  await app.close();
}

bootstrap();
