"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const app_module_1 = require("../app.module");
const user_entity_1 = require("../users/entities/user.entity");
async function bootstrap() {
    const app = await core_1.NestFactory.createApplicationContext(app_module_1.AppModule);
    const { getRepositoryToken } = require('@nestjs/typeorm');
    const { User } = require('../users/entities/user.entity');
    const userRepository = app.get(getRepositoryToken(User));
    console.log('🌱 Seeding Payment Statuses...');
    const users = await userRepository.find({
        where: [
            { role: user_entity_1.UserRole.ALUMNO },
            { role: user_entity_1.UserRole.PROFE }
        ]
    });
    console.log(`Found ${users.length} users to update.`);
    const now = new Date();
    let updatedCount = 0;
    for (let i = 0; i < users.length; i++) {
        const user = users[i];
        const scenario = i % 3;
        let newExpiration = new Date();
        let statusLabel = '';
        if (scenario === 0) {
            newExpiration.setDate(now.getDate() + 15);
            statusLabel = 'PAID (Green)';
        }
        else if (scenario === 1) {
            newExpiration.setDate(now.getDate() - 5);
            statusLabel = 'PENDING (Yellow)';
        }
        else {
            newExpiration.setDate(now.getDate() - 20);
            statusLabel = 'OVERDUE (Red)';
        }
        user.membershipExpirationDate = newExpiration;
        if (!user.membershipStartDate) {
            const start = new Date(newExpiration);
            start.setMonth(start.getMonth() - 1);
            user.membershipStartDate = start;
        }
        await userRepository.save(user);
        console.log(`User ${user.email} -> ${statusLabel} | Exp: ${newExpiration.toISOString().split('T')[0]}`);
        updatedCount++;
    }
    console.log(`✅ Updated ${updatedCount} users.`);
    await app.close();
}
bootstrap();
//# sourceMappingURL=seed_payment_statuses.js.map