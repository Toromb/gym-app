const { DataSource } = require('typeorm');
const dotenv = require('dotenv');
dotenv.config({ path: '/app/.env.prod' });
const AppDataSource = new DataSource({
    type: "postgres", host: process.env.DB_HOST, port: parseInt(process.env.DB_PORT, 10),
    username: process.env.DB_USER, password: process.env.DB_PASSWORD, database: process.env.DB_NAME, synchronize: false,
});
AppDataSource.initialize().then(async () => {
    const rows = await AppDataSource.query(`SELECT id, email, role, "gymId", "isActive" FROM "users" WHERE email LIKE '%alumno10%'`);
    console.log(JSON.stringify(rows, null, 2));
    process.exit(0);
});
