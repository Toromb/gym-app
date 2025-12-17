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
    const { getRepositoryToken } = require('@nestjs/typeorm');
    const { User } = require('./users/entities/user.entity');
    const userRepository = app.get(getRepositoryToken(User));
    console.log('🔧 Fixing Other Users Gym Relation...');
    const gyms = await gymsService.findAll();
    const defaultGym = gyms.find(g => g.businessName === 'Default Gym');
    if (!defaultGym) {
        console.error('❌ Default Gym not found!');
        await app.close();
        return;
    }
    console.log(`✅ Default Gym found: ${defaultGym.id}`);
    const profe = await userService.findOneByEmail('profe@gym.com');
    if (profe) {
        const fullProfe = await userService.findOne(profe.id);
        if (fullProfe && !fullProfe.gym) {
            console.log(`📝 Updating Profe ${fullProfe.email} to Gym: ${defaultGym.businessName}`);
            fullProfe.gym = defaultGym;
            await userRepository.save(fullProfe);
        }
        else {
            console.log(`ℹ️ Profe already has gym or not found`);
        }
    }
    const alumno = await userService.findOneByEmail('alumno@gym.com');
    if (alumno) {
        const fullAlumno = await userService.findOne(alumno.id);
        if (fullAlumno && !fullAlumno.gym) {
            console.log(`📝 Updating Alumno ${fullAlumno.email} to Gym: ${defaultGym.businessName}`);
            fullAlumno.gym = defaultGym;
            await userRepository.save(fullAlumno);
        }
        else {
            console.log(`ℹ️ Alumno already has gym or not found`);
        }
    }
    console.log('✅ Changes saved.');
    await app.close();
}
bootstrap();
//# sourceMappingURL=fix_other_users_gym.js.map