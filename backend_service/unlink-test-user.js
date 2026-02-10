
const { DataSource } = require('typeorm');
// We need to point to compiled JS files in the container
const { User } = require('./dist/src/users/entities/user.entity');
const { Gym } = require('./dist/src/gyms/entities/gym.entity');

const AppDataSource = new DataSource({
    type: 'postgres',
    host: process.env.DB_HOST || 'gym_app_db_prod',
    port: 5432,
    username: process.env.DB_USERNAME || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    database: process.env.DB_NAME || 'gym_db',
    entities: [User, Gym], // We only need User and Gym to unlink
    synchronize: false,
});

async function unlink() {
    try {
        await AppDataSource.initialize();
        console.log('Database connected.');

        const userRepo = AppDataSource.getRepository(User);
        // Find valid test user logic
        const user = await userRepo.findOne({
            where: { email: 'test.apple@example.com' },
            relations: ['gym']
        });

        if (user) {
            console.log(`Found user: ${user.email} Linked to Gym: ${user.gym ? user.gym.id : 'None'}`);
            user.gym = null;
            await userRepo.save(user);
            console.log('UNLINKED_USER_SUCCESS');
        } else {
            console.log('USER_NOT_FOUND');
        }

    } catch (error) {
        console.error('Error unlinking user:', error);
    } finally {
        if (AppDataSource.isInitialized) {
            await AppDataSource.destroy();
        }
    }
}

unlink();
