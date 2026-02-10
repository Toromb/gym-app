
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
        await client.query("DELETE FROM users WHERE email = 'test.apple@example.com'");
        console.log('CLEANED_USER');
    } catch (err) {
        console.error('DB_ERROR:', err);
    } finally {
        await client.end();
    }
}

run();
