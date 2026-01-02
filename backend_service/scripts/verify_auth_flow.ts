
// @ts-nocheck
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { AuthService } from '../src/auth/auth.service';
import { UsersService } from '../src/users/users.service';
import { UserRole } from '../src/users/entities/user.entity';

async function verifyAuthFlow() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const authService = app.get(AuthService);
    const usersService = app.get(UsersService);

    console.log('--- Starting Auth Flow Verification ---');

    // 1. Create User (No Password)
    const email = `test_auth_${Date.now()}@test.com`;
    console.log(`Creating user: ${email}`);
    const user = await usersService.create({
        firstName: 'Test',
        lastName: 'Auth',
        email: email,
        role: UserRole.ALUMNO
    });

    if (user.isActive === false && user.passwordHash === null) {
        console.log('✅ User created inactive and without password.');
    } else {
        console.error('❌ User creation failed state check:', user);
    }

    // 2. Generate Activation Token
    console.log('Generating Activation Token...');
    const token = await authService.generateActivationToken(user.id);
    console.log('Token generated:', token);

    const userWithToken = await usersService.findOne(user.id);
    if (userWithToken.activationTokenHash) {
        console.log('✅ Activation token hash saved.');
    } else {
        console.error('❌ Token hash NOT saved.');
    }

    // 3. Activate Account
    console.log('Activating Account...');
    await authService.activateAccount(token, 'newPassword123');

    const activeUser = await usersService.findOne(user.id);
    if (activeUser.isActive === true && activeUser.passwordHash && !activeUser.activationTokenHash) {
        console.log('✅ Account activated, password set, token cleared.');
    } else {
        console.error('❌ Activation state check failed:', activeUser);
    }

    // 4. Login
    console.log('Attempting Login...');
    const loginResult = await authService.validateUser(email, 'newPassword123');
    if (loginResult) {
        console.log('✅ Login successful.');
    } else {
        console.error('❌ Login failed.');
    }

    // 5. Generate Reset Token
    console.log('Generating Reset Token...');
    const resetToken = await authService.generateResetToken(user.id);

    const userWithReset = await usersService.findOne(user.id);
    if (userWithReset.resetTokenHash) {
        console.log('✅ Reset token hash saved.');
    }

    // 6. Reset Password
    console.log('Resetting Password...');
    await authService.resetPassword(resetToken, 'newerPassword456');

    const resetUser = await usersService.findOne(user.id);
    if (resetUser.passwordHash && !resetUser.resetTokenHash) {
        console.log('✅ Password reset, token cleared.');
    } else {
        console.error('❌ Reset state check failed.');
    }

    // 7. Login with New Password
    console.log('Attempting Login with New Password...');
    const loginResult2 = await authService.validateUser(email, 'newerPassword456');
    if (loginResult2) {
        console.log('✅ Login with new password successful.');
    } else {
        console.error('❌ Login with new password failed.');
    }

    console.log('--- Verification Finished ---');
    await app.close();
}

verifyAuthFlow();
