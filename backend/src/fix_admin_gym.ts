
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { UsersService } from './users/users.service';
import { GymsService } from './gyms/gyms.service';
import { UserRole } from './users/entities/user.entity';

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const userService = app.get(UsersService);
    const gymsService = app.get(GymsService);

    console.log('🔧 Fixing Admin Gym Relation...');

    // 1. Find Default Gym
    const gyms = await gymsService.findAll();
    const defaultGym = gyms.find(g => g.businessName === 'Default Gym');

    if (!defaultGym) {
        console.error('❌ Default Gym not found!');
        await app.close();
        return;
    }
    console.log(`✅ Default Gym found: ${defaultGym.id}`);

    // 2. Find Admin User
    const adminUser = await userService.findOneByEmail('admin@gym.com');
    if (!adminUser) {
        console.error('❌ User admin@gym.com not found!');
        await app.close();
        return;
    }

    // Check if relation already exists?
    // findOneByEmail doesn't load relations eagerly by default in some services, but usersService.findOne does.
    // Let's refetch with ID to be sure involving relations
    const fullAdmin = await userService.findOne(adminUser.id);

    if (fullAdmin?.gym) {
        console.log(`ℹ️ Admin already belongs to gym: ${fullAdmin.gym.businessName}`);
        // Force update anyway? 
        // If it was null previously per script check, fullAdmin.gym should be null.
    }

    if (!fullAdmin) { await app.close(); return; }


    console.log(`📝 Updating admin ${fullAdmin.email} to Gym: ${defaultGym.businessName}`);

    // Directly accessing Repository would be cleaner but Service update method handles password checks.
    // However, UpdateUserDto works with simple props.
    // Assigning object relation needs direct save or special handling not in `update`.
    // Let's use internal repository if possible? No, we don't have access here easily without hacking.
    // BUT we can use Object.assign hack again manually? 
    // Wait, usersService.update uses updateDto.

    // BETTER approach: Use repository from Service? Service doesn't expose repository public.
    // But `UsersService` is injected.
    // I can add a method or just do:
    // adminUser.gym = defaultGym;
    // await usersService.usersRepository.save(adminUser); -- Property 'usersRepository' is private.

    // Workaround: 
    // Use the `update` method but pass `gymId`? NO, updateDto doesn't handle it.

    // We can use generic TypeORM repository via module? 
    // Accessing `getRepository(User)` if we import `getConnection`? Deprecated.

    // Simplest: 
    // Modify `UsersService` temporarily? No.
    // Use `usersService.create` logic? No.

    // Wait, I can inject the Repository if I use `app.get(getRepositoryToken(User))`?
    // Yes!

    const { getRepositoryToken } = require('@nestjs/typeorm');
    const { User } = require('./users/entities/user.entity');
    const userRepository = app.get(getRepositoryToken(User));

    fullAdmin.gym = defaultGym;
    await userRepository.save(fullAdmin);

    console.log('✅ Update saved.');

    await app.close();
}

bootstrap();
