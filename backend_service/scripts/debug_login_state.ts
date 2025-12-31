// @ts-nocheck
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { UsersService } from '../src/users/users.service';
import { DataSource } from 'typeorm';

async function debugLoginState() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const usersService = app.get(UsersService);
    const dataSource = app.get(DataSource);

    console.log('--- Inspecting Admins ---');

    // 1. Get List of Admins
    const admins = await dataSource.getRepository('User').find({ where: { role: 'admin' } });

    console.log(`Found ${admins.length} admins.`);

    for (const admin of admins) {
        console.log(`Checking Admin: ${admin.email} (${admin.id})`);
        try {
            // CALL THE METHOD THAT IS SUSPECTED
            const user = await usersService.findOneByEmail(admin.email);
            console.log('findOneByEmail RESULT:', user);

            if (!user) {
                console.log('User not found by findOneByEmail??');
            } else {
                console.log('PasswordHash present?', !!user.passwordHash);
                console.log('PaymentStatus calculated:', user.paymentStatus);
            }

        } catch (e) {
            console.error('CRASH in findOneByEmail for', admin.email);
            console.error(e);
        }
        console.log('---------------------------');
    }

    await app.close();
}

debugLoginState();
