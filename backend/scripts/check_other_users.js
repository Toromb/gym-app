
const fetch = require('node-fetch');

const BASE_URL = 'http://localhost:3000';

async function checkUsers() {
    // 1. Login as Super Admin to see everything
    const loginRes = await fetch(`${BASE_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: 'superadmin@gym.com', password: 'admin123' })
    });

    if (!loginRes.ok) {
        console.error('Login failed:', loginRes.statusText);
        return;
    }

    const token = (await loginRes.json()).access_token;

    // 2. Fetch All Users
    const usersRes = await fetch(`${BASE_URL}/users`, {
        headers: { 'Authorization': `Bearer ${token}` }
    });

    const users = await usersRes.json();

    // 3. Filter for interesting users
    const targets = ['profe@gym.com', 'alumno@gym.com'];

    console.log('--- Checking User/Gym Relations ---');
    users.forEach(u => {
        if (targets.includes(u.email)) {
            console.log(`User: ${u.email}`);
            console.log(`Role: ${u.role}`);
            console.log(`Gym: ${u.gym ? u.gym.businessName : 'NULL/UNDEFINED'}`);
            console.log('---');
        }
    });
}

checkUsers();
