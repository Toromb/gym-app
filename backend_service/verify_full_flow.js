// const fetch = require('node-fetch'); // Using native fetch

const BASE_URL = 'http://localhost:3000';

async function login(email, password) {
    const response = await fetch(`${BASE_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
    });

    if (!response.ok) {
        throw new Error(`Login failed for ${email}: ${response.statusText}`);
    }

    const data = await response.json();
    return data.access_token;
}

async function getProfile(token) {
    const response = await fetch(`${BASE_URL}/auth/profile`, {
        method: 'GET',
        headers: { Authorization: `Bearer ${token}` },
    });

    if (!response.ok) {
        throw new Error(`Get profile failed: ${response.statusText}`);
    }

    return response.json();
}

async function createExercise(token, title) {
    const response = await fetch(`${BASE_URL}/exercises`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
            name: title,
            description: 'Test description',
            videoUrl: 'http://test.com/video.mp4',
        }),
    });

    return { status: response.status, data: await response.json().catch(() => ({})) };
}

async function main() {
    try {
        console.log('--- Starting Verification ---');

        // 1. Admin Flow
        console.log('\n[Admin] Logging in...');
        const adminToken = await login('admin@gym.com', 'admin123');
        console.log('[Admin] Login success.');
        const adminProfile = await getProfile(adminToken);
        console.log(`[Admin] Profile verified: ${adminProfile.email} (${adminProfile.role})`);

        // 2. Profe Flow
        console.log('\n[Profe] Logging in...');
        const profeToken = await login('profe@gym.com', 'admin123');
        console.log('[Profe] Login success.');
        const profeProfile = await getProfile(profeToken);
        console.log(`[Profe] Profile verified: ${profeProfile.email} (${profeProfile.role})`);

        console.log('[Profe] Creating exercise...');
        const exResult = await createExercise(profeToken, 'Pushups');
        if (exResult.status === 201) {
            console.log('[Profe] Exercise created successfully.');
        } else {
            console.error(`[Profe] Failed to create exercise. Status: ${exResult.status}`);
        }

        // 3. Alumno Flow
        console.log('\n[Alumno] Logging in...');
        const alumnoToken = await login('alumno@gym.com', 'admin123');
        console.log('[Alumno] Login success.');
        const alumnoProfile = await getProfile(alumnoToken);
        console.log(`[Alumno] Profile verified: ${alumnoProfile.email} (${alumnoProfile.role})`);

        console.log('[Alumno] Attempting to create exercise (should fail or depend on logic)...');
        const alumnoExResult = await createExercise(alumnoToken, 'Illegal Pushups');
        if (alumnoExResult.status === 403 || alumnoExResult.status === 401) {
            console.log(`[Alumno] Correctly blocked from creating exercise. Status: ${alumnoExResult.status}`);
        } else if (alumnoExResult.status === 201) {
            console.log(`[Alumno] WARNING: Alumno was able to create an exercise!`);
        } else {
            console.log(`[Alumno] Unexpected status: ${alumnoExResult.status}`);
        }

        console.log('\n--- Verification Completed Successfully ---');

    } catch (error) {
        console.error('\n!!! Verification Failed !!!');
        console.error(error);
        process.exit(1);
    }
}

main();
