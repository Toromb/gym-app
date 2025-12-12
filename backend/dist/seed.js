"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const app_module_1 = require("./app.module");
const users_service_1 = require("./users/users.service");
const user_entity_1 = require("./users/entities/user.entity");
async function bootstrap() {
    const app = await core_1.NestFactory.createApplicationContext(app_module_1.AppModule);
    const userService = app.get(users_service_1.UsersService);
    console.log('➡️ Ejecutando SEED…');
    const users = [
        {
            firstName: 'Admin',
            lastName: 'User',
            email: 'admin@gym.com',
            password: 'admin123',
            role: user_entity_1.UserRole.ADMIN,
        },
        {
            firstName: 'Pedro',
            lastName: 'Alumno',
            email: 'alumno@gym.com',
            password: 'admin123',
            role: user_entity_1.UserRole.ALUMNO,
        },
        {
            firstName: 'Juan',
            lastName: 'Profe',
            email: 'profe@gym.com',
            password: 'admin123',
            role: user_entity_1.UserRole.PROFE,
        },
    ];
    for (const u of users) {
        const exists = await userService.findOneByEmail(u.email);
        if (exists) {
            console.log(`⚠️ El usuario ${u.email} ya existe — se salta.`);
            continue;
        }
        console.log(`➕ Creando usuario: ${u.email}`);
        await userService.create(u);
    }
    console.log('✔️ SEED COMPLETADO');
    await app.close();
}
bootstrap();
//# sourceMappingURL=seed.js.map