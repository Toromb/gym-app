const { DataSource } = require('typeorm');
const dotenv = require('dotenv');
const { join } = require('path');

dotenv.config({ path: join(__dirname, '.env.prod') });

const User = require('./dist/src/users/entities/user.entity').User;
const RefreshToken = require('./dist/src/auth/entities/refresh-token.entity').RefreshToken;

const AppDataSource = new DataSource({
    type: "postgres",
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT, 10),
    username: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    entities: [join(__dirname, 'dist', 'src', '**', '*.entity.js')],
    synchronize: false,
});

AppDataSource.initialize()
    .then(async () => {
        console.log("Data Source has been initialized!");
        await AppDataSource.synchronize(false);
        console.log("Database synchronized.");
        process.exit(0);
    })
    .catch((err) => {
        console.error("Error during Data Source initialization", err);
        process.exit(1);
    });
