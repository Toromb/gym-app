
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

    console.log('🔧 Fixing Other Users Gym Relation...');

    // 1. Find Default Gym
    const gyms = await gymsService.findAll();
    const defaultGym = gyms.find(g => g.businessName === 'Default Gym');

    if (!defaultGym) {
        console.error('❌ Default Gym not found!');
        await app.close();
        return;
    }
    console.log(`✅ Default Gym found: ${defaultGym.id}`);

    // 2. Fix Profe
    const profe = await userService.findOneByEmail('profe@gym.com');
    if (profe) {
        const fullProfe = await userService.findOne(profe.id);
        if (fullProfe && !fullProfe.gym) {
            console.log(`📝 Updating Profe ${fullProfe.email} to Gym: ${defaultGym.businessName}`);
            fullProfe.gym = defaultGym;
            await userRepository.save(fullProfe);
        } else {
            console.log(`ℹ️ Profe already has gym or not found`);
        }
    }

    // 3. Fix Alumno
    const alumno = await userService.findOneByEmail('alumno@gym.com');
    if (alumno) {
        const fullAlumno = await userService.findOne(alumno.id);
        if (fullAlumno && !fullAlumno.gym) {
            console.log(`📝 Updating Alumno ${fullAlumno.email} to Gym: ${defaultGym.businessName}`);
            fullAlumno.gym = defaultGym;
            await userRepository.save(fullAlumno);
        } else {
            console.log(`ℹ️ Alumno already has gym or not found`);
        }
    }

    console.log('✅ Changes saved.');
    await app.close();
}

bootstrap();
