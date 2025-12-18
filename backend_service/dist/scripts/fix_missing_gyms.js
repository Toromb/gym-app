"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const app_module_1 = require("../app.module");
const users_service_1 = require("../users/users.service");
const gyms_service_1 = require("../gyms/gyms.service");
const user_entity_1 = require("../users/entities/user.entity");
async function bootstrap() {
    const app = await core_1.NestFactory.createApplicationContext(app_module_1.AppModule);
    const userService = app.get(users_service_1.UsersService);
    const gymsService = app.get(gyms_service_1.GymsService);
    const { getRepositoryToken } = require('@nestjs/typeorm');
    const { User } = require('./users/entities/user.entity');
    const userRepository = app.get(getRepositoryToken(User));
    console.log('🔧 Running Global Gym Fix...');
    const gyms = await gymsService.findAll();
    const defaultGym = gyms.find(g => g.businessName === 'Default Gym');
    if (!defaultGym) {
        console.error('❌ Default Gym not found! Cannot proceed.');
        await app.close();
        return;
    }
    console.log(`✅ Default Gym found: ${defaultGym.businessName}`);
    const allUsers = await userRepository.find({ relations: ['gym'] });
    console.log(`🔍 Scanning ${allUsers.length} users...`);
    let fixedCount = 0;
    for (const user of allUsers) {
        if (user.role === user_entity_1.UserRole.SUPER_ADMIN) {
            continue;
        }
        if (!user.gym) {
            console.log(`⚠️ User [${user.role}] ${user.email} has NO GYM. Fixing...`);
            user.gym = defaultGym;
            await userRepository.save(user);
            fixedCount++;
        }
    }
    console.log('--------------------------------------------------');
    console.log(`✅ Scan Complete. Fixed ${fixedCount} users.`);
    await app.close();
}
bootstrap();
//# sourceMappingURL=fix_missing_gyms.js.map