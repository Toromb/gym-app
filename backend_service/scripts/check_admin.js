
const fetch = require('node-fetch');

const BASE_URL = 'http://localhost:3000';

async function checkAdmin() {
    // 1. Login as Super Admin
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

    // 2. Fetch Users (Super Admin sees all)
    // Filter by role=admin
    const usersRes = await fetch(`${BASE_URL}/users?role=admin`, {
        headers: { 'Authorization': `Bearer ${token}` }
    });

    const users = await usersRes.json();

    // 3. Find admin@gym.com
    const targetUser = users.find(u => u.email === 'admin@gym.com');

    if (targetUser) {
        console.log('--- Admin User Found ---');
        console.log('ID:', targetUser.id);
        console.log('Email:', targetUser.email);
        console.log('Gym:', targetUser.gym ? targetUser.gym : 'NULL/UNDEFINED');
    } else {
        console.log('User admin@gym.com NOT FOUND');
    }
}

checkAdmin();
