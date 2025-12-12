import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { UsersService } from './users/users.service';
import { UserRole } from './users/entities/user.entity';

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const userService = app.get(UsersService);

    console.log('➡️ Ejecutando SEED…');

    const users = [
        {
            firstName: 'Admin',
            lastName: 'User',
            email: 'admin@gym.com',
            password: 'admin123',
            role: UserRole.ADMIN,
        },
        {
            firstName: 'Pedro',
            lastName: 'Alumno',
            email: 'alumno@gym.com',
            password: 'admin123',
            role: UserRole.ALUMNO,
        },
        {
            firstName: 'Juan',
            lastName: 'Profe',
            email: 'profe@gym.com',
            password: 'admin123',
            role: UserRole.PROFE,
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
