"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
require("../polyfill");
const core_1 = require("@nestjs/core");
const app_module_1 = require("../app.module");
const users_service_1 = require("../users/users.service");
const gyms_service_1 = require("../gyms/gyms.service");
const exercises_service_1 = require("../exercises/exercises.service");
const user_entity_1 = require("../users/entities/user.entity");
const typeorm_1 = require("typeorm");
const seed_muscles_1 = require("./seed-muscles");
const seed_exercise_muscles_1 = require("./seed-exercise-muscles");
const base_exercises_1 = require("../exercises/constants/base-exercises");
async function bootstrap() {
    const app = await core_1.NestFactory.createApplicationContext(app_module_1.AppModule);
    const dataSource = app.get(typeorm_1.DataSource);
    await dataSource.query('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"');
    const userService = app.get(users_service_1.UsersService);
    const gymsService = app.get(gyms_service_1.GymsService);
    console.log('➡️ Ejecutando SEED MASTER (Safe Mode)…');
    await (0, seed_muscles_1.seedMuscles)(dataSource);
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
    }
    else {
        console.log('✅ Default Gym ya existe');
    }
    const users = [
        {
            firstName: 'Super',
            lastName: 'Admin',
            email: 'superadmin@gym.com',
            password: 'admin123',
            role: user_entity_1.UserRole.SUPER_ADMIN,
        },
        {
            firstName: 'Admin',
            lastName: 'User',
            email: 'admin@gym.com',
            password: 'admin123',
            role: user_entity_1.UserRole.ADMIN,
            gymId: defaultGym.id,
        },
        {
            firstName: 'Pedro',
            lastName: 'Alumno',
            email: 'alumno@gym.com',
            password: 'admin123',
            role: user_entity_1.UserRole.ALUMNO,
            gymId: defaultGym.id,
        },
        {
            firstName: 'Juan',
            lastName: 'Profe',
            email: 'profe@gym.com',
            password: 'admin123',
            role: user_entity_1.UserRole.PROFE,
            gymId: defaultGym.id,
        },
    ];
    for (const u of users) {
        const exists = await userService.findOneByEmail(u.email);
        if (exists) {
            continue;
        }
        console.log(`➕ Creando usuario: ${u.email}`);
        await userService.create(u);
    }
    console.log('💪 Verificando Ejercicios (Ahora gestionados per-Gym)...');
    const exercisesService = app.get(exercises_service_1.ExercisesService);
    const exercises = await exercisesService.findAll();
    if (exercises.length === 0) {
        console.log('ℹ️ No existen ejercicios globales. Esto es correcto ahora.');
        const gymExercises = await exercisesService.findAll(defaultGym.id);
        if (gymExercises.length === 0) {
            console.log('⚠️ Alerta: Default Gym no tiene ejercicios. Forzando población...');
            for (const baseEx of base_exercises_1.BASE_EXERCISES) {
                await exercisesService.createForGym({
                    name: baseEx.name,
                    description: baseEx.description,
                    muscles: baseEx.muscles.map(m => ({
                        muscleId: m.name,
                        role: m.role,
                        loadPercentage: m.loadPercentage
                    })),
                    videoUrl: '',
                    imageUrl: '',
                }, defaultGym);
            }
            console.log('✅ Ejercicios base inyectados a Default Gym.');
        }
        else {
            console.log(`✅ Default Gym ya tiene ${gymExercises.length} ejercicios propios.`);
        }
    }
    else {
        console.log(`✅ Sistema tiene ${exercises.length} ejercicios en total.`);
    }
    await (0, seed_exercise_muscles_1.seedExerciseMuscles)(dataSource);
    console.log('✔️ SEED COMPLETADO');
    await app.close();
}
bootstrap();
//# sourceMappingURL=seed.js.map