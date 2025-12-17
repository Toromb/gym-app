"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const app_module_1 = require("../app.module");
const users_service_1 = require("../users/users.service");
const gyms_service_1 = require("../gyms/gyms.service");
async function bootstrap() {
    const app = await core_1.NestFactory.createApplicationContext(app_module_1.AppModule);
    const userService = app.get(users_service_1.UsersService);
    const gymsService = app.get(gyms_service_1.GymsService);
    console.log('🔧 Fixing Admin Gym Relation...');
    const gyms = await gymsService.findAll();
    const defaultGym = gyms.find(g => g.businessName === 'Default Gym');
    if (!defaultGym) {
        console.error('❌ Default Gym not found!');
        await app.close();
        return;
    }
    console.log(`✅ Default Gym found: ${defaultGym.id}`);
    const adminUser = await userService.findOneByEmail('admin@gym.com');
    if (!adminUser) {
        console.error('❌ User admin@gym.com not found!');
        await app.close();
        return;
    }
    const fullAdmin = await userService.findOne(adminUser.id);
    if (fullAdmin?.gym) {
        console.log(`ℹ️ Admin already belongs to gym: ${fullAdmin.gym.businessName}`);
    }
    if (!fullAdmin) {
        await app.close();
        return;
    }
    console.log(`📝 Updating admin ${fullAdmin.email} to Gym: ${defaultGym.businessName}`);
    const { getRepositoryToken } = require('@nestjs/typeorm');
    const { User } = require('../users/entities/user.entity');
    const userRepository = app.get(getRepositoryToken(User));
    fullAdmin.gym = defaultGym;
    await userRepository.save(fullAdmin);
    console.log('✅ Update saved.');
    await app.close();
}
bootstrap();
//# sourceMappingURL=fix_admin_gym.js.map