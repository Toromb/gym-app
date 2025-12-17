
const fetch = require('node-fetch');
const { performance } = require('perf_hooks');

// --- Configuration ---
const BASE_URL = 'http://localhost:3000';
const STAGE_DURATION_MS = 5000; // 5 seconds per stage
const RAMP_UP_STAGES = [10, 25, 50, 75, 100]; // Concurrency levels
const THINK_TIME_MAX_MS = 100;

// Test Data (Seed Users)
const USERS = [
    { email: 'superadmin@gym.com', password: 'admin123' },
    { email: 'admin@gym.com', password: 'admin123' },
    { email: 'alumno@gym.com', password: 'admin123' },
    { email: 'profe@gym.com', password: 'admin123' },
];

const ENDPOINTS = [
    '/users',
    '/gyms',
    '/plans', // Assuming this exists and is accessible
];

// Global State
let isRunning = true;
const results = []; // Array of { duration, status, endpoint, timestamp }

// --- Helper Functions ---

const sleep = (ms) => new Promise(r => setTimeout(r, ms));

async function login(user) {
    try {
        const res = await fetch(`${BASE_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(user)
        });
        if (!res.ok) return null;
        const data = await res.json();
        return data.access_token;
    } catch (e) {
        return null;
    }
}

async function virtualUser(id, userCredentials) {
    // 1. Login
    const token = await login(userCredentials);
    if (!token) {
        // console.error(`VU #${id} failed to login.`);
        return; // Exit if login fails
    }

    // 2. Load Loop
    while (isRunning) {
        const endpoint = ENDPOINTS[Math.floor(Math.random() * ENDPOINTS.length)];
        const start = performance.now();
        let status = 0;

        try {
            const res = await fetch(`${BASE_URL}${endpoint}`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            status = res.status;
            // await res.text(); // Consume body
        } catch (e) {
            status = 0; // Network error
        }

        const duration = performance.now() - start;
        results.push({ duration, status, endpoint, timestamp: Date.now() });

        // Think time
        await sleep(Math.random() * THINK_TIME_MAX_MS);
    }
}

function calculateStats(samples) {
    if (samples.length === 0) return { avg: 0, p95: 0, successRate: 0, rps: 0 };

    const sorted = samples.map(s => s.duration).sort((a, b) => a - b);
    const avg = sorted.reduce((a, b) => a + b, 0) / sorted.length;
    const p95 = sorted[Math.floor(sorted.length * 0.95)];
    const successes = samples.filter(s => s.status >= 200 && s.status < 300).length;

    return {
        count: samples.length,
        avg: avg.toFixed(2),
        p95: p95.toFixed(2),
        successRate: ((successes / samples.length) * 100).toFixed(1),
        successes,
        errors: samples.length - successes
    };
}

// --- Main Runner ---

async function runTest() {
    console.log('🚀 Starting Advanced Load Test');
    console.log(`Targets: ${ENDPOINTS.join(', ')}`);
    console.log(`Stages (Concurrency): ${RAMP_UP_STAGES.join(' -> ')}`);
    console.log('--------------------------------------------------');

    const vus = [];
    let currentConcurrency = 0;

    for (const targetConcurrency of RAMP_UP_STAGES) {
        console.log(`\n📈 Ramping up to ${targetConcurrency} users...`);

        // Add new VUs needed
        const newVusCount = targetConcurrency - currentConcurrency;
        for (let i = 0; i < newVusCount; i++) {
            const userCreds = USERS[i % USERS.length]; // Rotate users
            vus.push(virtualUser(currentConcurrency + i, userCreds));
        }
        currentConcurrency = targetConcurrency;

        // Measure for STAGE_DURATION
        const stageStart = Date.now();
        const startSampleIdx = results.length;

        await sleep(STAGE_DURATION_MS);

        const stageSamples = results.slice(startSampleIdx);
        const durationSec = (Date.now() - stageStart) / 1000;
        const stats = calculateStats(stageSamples);
        const rps = (stats.count / durationSec).toFixed(1);

        console.log(`   [Results] RPS: ${rps} | Avg: ${stats.avg}ms | P95: ${stats.p95}ms | Errors: ${stats.errors}`);

        if (stats.successRate < 95) {
            console.warn('   ⚠️ High error rate detected!');
        }
    }

    // Stop
    isRunning = false;
    await Promise.all(vus);
    console.log('\n🛑 Test Finished.');
}

runTest();
