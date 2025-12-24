
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { DataSource } from 'typeorm';
import { UsersService } from '../users/users.service';
import { AuthService } from '../auth/auth.service';
import * as bcrypt from 'bcrypt';

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);
    // Explicitly retrieve UsersService using the class reference
    const usersService = app.get(UsersService);
    const authService = app.get(AuthService);

    const email = 'admin@gym.com';
    console.log(`\n--- SIMULATING LOGIN FOR ${email} ---`);

    try {
        // 1. Find User by Email (This triggers payment status calculation)
        const user = await usersService.findOneByEmail(email);
        console.log('1. User lookup complete.');

        if (!user) {
            console.error('❌ User not found via service!');
        } else {
            console.log(`   User found: ${user.id} (Role: ${user.role})`);
            console.log(`   Gym loaded? ${user.gym ? 'YES' : 'NO'}`);

            // 2. Test Payment Status Logic
            console.log('2. checking payment status calculation...');
            if (user.paymentStatus) {
                console.log(`   Payment Status: ${user.paymentStatus}`);
            }

            // 3. Test Gym Status Check (AuthService logic)
            console.log('3. Checking Gym Suspension logic...');
            if (user.gym && user.gym.status === 'suspended') {
                console.log('   Gym is SUSPENDED');
            } else {
                console.log('   Gym status OK');
            }

            // 4. Test Password Compare
            console.log('4. Testing Password Compare...');
            if (user.passwordHash) {
                const isMatch = await bcrypt.compare('admin123', user.passwordHash);
                console.log(`   Password Match: ${isMatch}`);
            }

            // 5. Test Full Login (JWT Signing)
            console.log('5. Testing Full Login (JWT Generation)...');
            try {
                // Mock the user object expected by login (usually the result of validateUser)
                // We can strip passwordHash first
                const { passwordHash, ...result } = user;
                const loginResult = await authService.login(result);
                console.log(`   Token Generated: ${loginResult.access_token ? 'YES' : 'NO'}`);

                // 6. Test Serialization (Crucial for 500 errors)
                console.log('6. Testing JSON Serialization (Circular Ref Check)...');
                try {
                    const json = JSON.stringify(loginResult);
                    console.log('   Serialization OK. Length: ' + json.length);
                } catch (jsonErr) {
                    console.error('❌ SERIALIZATION FAILED (Circular?):', jsonErr.message);
                }

            } catch (jwtError) {
                console.error('❌ JWT GENERATION FAILED:');
                console.error(jwtError);
            }
        }
    } catch (e) {
        console.error('❌ EXCEPTION CAUGHT DURING LOGIN SIMULATION:');
        console.error(e.message);
        console.error(e.stack);
    }

    await app.close();
}

bootstrap();
