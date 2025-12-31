// @ts-nocheck
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { UsersService } from '../src/users/users.service';
import { AuthService } from '../src/auth/auth.service';
import { UserRole } from '../src/users/entities/user.entity';
import { DataSource } from 'typeorm';

async function verifyHttp() {
    // 1. Setup User via direct service access
    const app = await NestFactory.createApplicationContext(AppModule);
    const usersService = app.get(UsersService);
    const authService = app.get(AuthService);
    const dataSource = app.get(DataSource);

    // Revert to creation to ensure valid user exists
    const email = `http_valid_${Date.now()}@test.com`;
    const password = 'CorrectPassword123';

    // Get a Gym
    const gym = await dataSource.getRepository('Gym').findOne({ where: {} });
    if (!gym) throw new Error('No gym found');

    console.log(`Setting up user: ${email} with Gym ${gym.id}`);
    const passwordHash = await (await import('bcrypt')).hash(password, 10);

    const user = await usersService.create({
        firstName: 'Http',
        lastName: 'Valid',
        email,
        role: UserRole.ADMIN,
        password, // Service will hash this, but we want to be sure it matches
        isActive: true,
        gymId: gym.id
    });

    // Ensure password is set correctly (Service create handles it if we pass password)
    // usersService.create logic: if (password) passwordHash = bcrypt... isActive = true

    await app.close();

    console.log(`Attempting HTTP Login for ${email} with CORRECT password...`);
    // Actually, createApplicationContext might keep process alive. 
    // But we want to call the URL.

    console.log('User created. Attempting HTTP Login...');

    const fetch = (await import('node-fetch')).default;

    try {
        console.log('Fetching http://127.0.0.1:3000/auth/login ...');
        const response = await fetch('http://127.0.0.1:3000/auth/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password })
        });

        console.log(`Response Status: ${response.status}`);
        const text = await response.text();
        console.log(`Response Body: ${text}`);
    } catch (e) {
        console.error('HTTP Request Failed:', e);
    }
}

verifyHttp();
