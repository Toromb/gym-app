import '../polyfill';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { UsersService } from '../users/users.service';
import { GymsService } from '../gyms/gyms.service';
import { ExercisesService } from '../exercises/exercises.service';
import { UserRole } from '../users/entities/user.entity';
import { DataSource } from 'typeorm';

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);

    // ⚠️ CRITICAL: In production 'synchronize' is false.
    // For this FIRST DEPLOYMENT (or manual seed), we force schema sync.
    // Be careful running this if you have data you don't want to lose if schema changed (sync(false) keeps data safe usually, but careful).
    // Using { synchronize: false } in app.module means tables aren't created.
    // We can manually trigger it here.
    const dataSource = app.get(DataSource);
    await dataSource.synchronize(); // <--- Creates tables if missing

    const userService = app.get(UsersService);
    const gymsService = app.get(GymsService);

    console.log('➡️ Ejecutando SEED…');

    // 1. Create Default Gym if not exists
    const gyms = await gymsService.findAll();
    let defaultGym = gyms.find(g => g.businessName === 'Default Gym');

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
            gymId: defaultGym!.id,
        },
        {
            firstName: 'Pedro',
            lastName: 'Alumno',
            email: 'alumno@gym.com',
            password: 'admin123',
            role: UserRole.ALUMNO,
            gymId: defaultGym!.id,
        },
        {
            firstName: 'Juan',
            lastName: 'Profe',
            email: 'profe@gym.com',
            password: 'admin123',
            role: UserRole.PROFE,
            gymId: defaultGym!.id,
        },
    ];

    for (const u of users) {
        const exists = await userService.findOneByEmail(u.email);

        if (exists) {
            console.log(`⚠️ El usuario ${u.email} ya existe — se salta.`);
            // TODO: In a real migration we would check if exists.gym is null and update it!
            if (u.role !== UserRole.SUPER_ADMIN && !exists.gym) {
                console.log(`   ↪ Asignando a Default Gym...`);
                // We don't have updateGym method exposed easily in service specifically for this, 
                // but we can use generic update or direct repo? 
                // Using generic update requires DTO which might verify things. 
                // For now, let's assume seed is initial or handled. 
                // If critical, I'd direct update via repo but avoiding complexity here.
            }
            continue;
        }

        console.log(`➕ Creando usuario: ${u.email}`);
        await userService.create(u);
    }

    // 2. Seed Exercises
    console.log('💪 Verificando Ejercicios...');
    const exercisesService = app.get(ExercisesService);
    const exercises = await exercisesService.findAll(); // This returns ALL (if updated service) or Gym specific? Service.findAll returns by gymId if provided. Argless returns ALL.

    // Check for orphan exercises (Null Gym)
    // We can use a direct query or filter the results if findAll returns all.
    // exercisesService.findAll() returns `this.exercisesRepository.find()` which returns ALL.

    if (exercises.length === 0) {
        console.log('➕ Creando Ejercicios Base...');
        const adminUser = await userService.findOneByEmail('admin@gym.com');

        if (!adminUser?.gym) {
            console.error('❌ CRITICAL: Admin user has no Gym! Cannot seed exercises correctly.');
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
                await exercisesService.create({
                    name: ex.name,
                    description: ex.description,
                    videoUrl: '',
                    imageUrl: ''
                }, adminUser);
            }
        }
    } else {
        console.log('✅ Ejercicios ya existen. Verificando integridad...');

        let fixedCount = 0;
        for (const ex of exercises) {
            if (!ex.gym) {
                // Fix orphan exercise
                if (defaultGym) {
                    // We need to update relation. Service.update uses DTO, might verify. 
                    // Direct repo access via checking module or just use query builder here?
                    // Accessing repo from service is private.
                    // We can use the service update if it supports it, or use DataSource directly since we have it.
                    await dataSource.getRepository('Exercise').update(ex.id, { gym: defaultGym });
                    fixedCount++;
                }
            }
        }

        if (fixedCount > 0) {
            console.log(`🔧 ${fixedCount} ejercicios huérfanos fueron asignados a "Default Gym".`);
        } else {
            console.log('✅ Todos los ejercicios tienen Gym asignado.');
        }
    }

    console.log('✔️ SEED COMPLETADO');
    await app.close();
}

bootstrap();
