const fetch = require('node-fetch'); // Ensure node-fetch is available or use native fetch in Node 18+

// Native fetch in Node 18+ or global fetch
const _fetch = global.fetch || require('node-fetch');

const BASE_URL = 'http://localhost:3001';
const SUPER_ADMIN = {
    email: 'superadmin@gym.com',
    password: 'admin123'
};

const STRESS_GYM = {
    businessName: 'Stress Test Gym ' + Date.now(),
    address: 'Load Test Address',
    email: `stress_${Date.now()}@test.com`,
    maxProfiles: 500
};

const NUM_USERS = 200;
const OUTPUT_FILE = './stress_users.json';
const fs = require('fs');

async function main() {
    console.log('🚀 Starting Stress Test Setup...');

    // 1. Login Super Admin
    console.log('🔑 Logging in as Super Admin...');
    const loginRes = await _fetch(`${BASE_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(SUPER_ADMIN)
    });

    if (!loginRes.ok) {
        throw new Error(`Login Failed: ${loginRes.status} ${loginRes.statusText}`);
    }
    const token = (await loginRes.json()).access_token;
    console.log('✅ Super Admin Logged In.');

    // 2. Create Stress Gym
    console.log('building Gym...');
    const gymRes = await _fetch(`${BASE_URL}/gyms`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(STRESS_GYM)
    });

    if (!gymRes.ok) throw new Error(`Gym Creation Failed: ${await gymRes.text()}`);
    const gym = await gymRes.json();
    console.log(`✅ Stress Gym Created: ${gym.businessName} (ID: ${gym.id})`);

    // 3. Create Users
    console.log(`👥 creating ${NUM_USERS} users...`);
    const users = [];
    const password = 'testpassword123';

    // We can run this in parallel chunks to be faster, but sequential is safer for DB load during setup
    for (let i = 0; i < NUM_USERS; i++) {
        const userPayload = {
            firstName: `StressUser${i}`,
            lastName: `Test`,
            email: `stress_user_${gym.id}_${i}@test.com`,
            password: password,
            gymId: gym.id,
            role: 'alumno',
            paysMembership: true // Mix it up? Let's keep simpler
        };

        const uRes = await _fetch(`${BASE_URL}/users`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify(userPayload)
        });

        if (uRes.ok) {
            const uData = await uRes.json();
            users.push({ email: userPayload.email, password: userPayload.password, id: uData.id });
            if (i % 20 === 0) process.stdout.write('.');
        } else {
            console.error(`Failed to create user ${i}: ${await uRes.text()}`);
        }
    }
    console.log('\n✅ User Creation Complete.');

    // 4. Save Credentials
    fs.writeFileSync(OUTPUT_FILE, JSON.stringify({ gymId: gym.id, users }, null, 2));
    console.log(`💾 Credentials saved to ${OUTPUT_FILE}`);
}

main().catch(console.error);
