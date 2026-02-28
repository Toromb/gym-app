const { DataSource } = require('typeorm');
const dotenv = require('dotenv');
dotenv.config({ path: '/app/.env.prod' });

const AppDataSource = new DataSource({
    type: "postgres",
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT, 10),
    username: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    synchronize: false,
});

AppDataSource.initialize()
    .then(async () => {
        // Find one alumno
        const rows = await AppDataSource.query(`SELECT id, email, role, "paysMembership", "membershipExpirationDate" FROM "users" WHERE role = 'ALUMNO' LIMIT 1`);
        if (rows.length === 0) {
            console.log("NO ALUMNO FOUND!");
            process.exit(1);
        }
        const user = rows[0];
        console.log("Current user:", user);

        // Update to 3 days from now
        await AppDataSource.query(`UPDATE "users" SET "paysMembership" = true, "membershipExpirationDate" = NOW() + INTERVAL '3 days' WHERE id = $1`, [user.id]);

        const updated = await AppDataSource.query(`SELECT id, email, role, "paysMembership", "membershipExpirationDate" FROM "users" WHERE id = $1`, [user.id]);
        console.log("Updated to ORANGE (3 days):", updated[0]);

        process.exit(0);
    })
    .catch((err) => {
        console.error("Error during Data Source initialization", err);
        process.exit(1);
    });
