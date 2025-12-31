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
async function bootstrap() {
    const app = await core_1.NestFactory.createApplicationContext(app_module_1.AppModule);
    const dataSource = app.get(typeorm_1.DataSource);
    await dataSource.synchronize();
    const userService = app.get(users_service_1.UsersService);
    const gymsService = app.get(gyms_service_1.GymsService);
    console.log('➡️ Ejecutando SEED…');
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
            console.log(`⚠️ El usuario ${u.email} ya existe — se salta.`);
            if (u.role !== user_entity_1.UserRole.SUPER_ADMIN && !exists.gym) {
                console.log(`   ↪ Asignando a Default Gym...`);
            }
            continue;
        }
        console.log(`➕ Creando usuario: ${u.email}`);
        await userService.create(u);
    }
    console.log('💪 Verificando Ejercicios...');
    const exercisesService = app.get(exercises_service_1.ExercisesService);
    const exercises = await exercisesService.findAll();
    if (exercises.length === 0) {
        console.log('➕ Creando Ejercicios Base...');
        const adminUser = await userService.findOneByEmail('admin@gym.com');
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
    else {
        console.log('✅ Ejercicios ya existen');
    }
    console.log('✔️ SEED COMPLETADO');
    await app.close();
}
bootstrap();
//# sourceMappingURL=seed.js.map