
const { Client } = require('pg');

const client = new Client({
    host: '172.19.0.4',
    port: 5432,
    user: 'postgres',
    password: 'postgres',
    database: 'gym_db',
});

async function run() {
    try {
        await client.connect();
        const res = await client.query('SELECT id, "businessName" FROM gyms LIMIT 1');
        if (res.rows.length > 0) {
            console.log('GYM_ID:', res.rows[0].id);
            console.log('GYM_NAME:', res.rows[0].businessName);
        } else {
            console.log('NO_GYMS_FOUND');
        }
    } catch (err) {
        console.error('DB_ERROR:', err);
    } finally {
        await client.end();
    }
}

run();
