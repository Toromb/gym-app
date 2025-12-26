const fs = require('fs');
// Native fetch via global or require
const _fetch = global.fetch || require('node-fetch');

const BASE_URL = 'http://localhost:3001';
const DATA_FILE = './stress_users.json';

// Configuration
const CONFIG = {
    RAMP_STEPS: [10, 50, 100, 200], // Concurrent users per step
    STEP_DURATION_MS: 30000, // 30 seconds per step
    MIN_THINK_TIME: 1000,
    MAX_THINK_TIME: 3000
};

// State
let usersList = [];
let gymId = '';
const metrics = {
    totalRequests: 0,
    errors: 0,
    latencies: [],
    stepResults: []
};

// Utils
const sleep = (ms) => new Promise(r => setTimeout(r, ms));
const randomInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

async function runRequest(name, fn) {
    const start = Date.now();
    try {
        const res = await fn();
        if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
        // await res.json(); // Consume body
        const duration = Date.now() - start;
        metrics.latencies.push(duration);
        metrics.totalRequests++;
        return true;
    } catch (e) {
        metrics.errors++;
        // console.error(`[${name}] Error: ${e.message}`);
        return false;
    }
}

async function userScenario(user) {
    // 1. Login
    let token = '';
    const start = Date.now();

    // Login
    await runRequest('Login', async () => {
        const r = await _fetch(`${BASE_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: user.email, password: user.password })
        });
        if (r.ok) {
            const data = await r.json();
            token = data.access_token;
        }
        return r;
    });

    if (!token) return; // Cannot proceed

    // Loop actions until externally stopped or just one pass?
    // "Real users" keep doing things. Let's do a loop for the duration of the step.
    // But here we are launching N users. The step controller manages concurrency.
    // We will make this function "run strictly one cycle of actions".
    // The "Runner" will spawn N of these concurrently in a loop.

    // Actually, distinct users should stay logged in.
    // Better pattern: User Agent Class that maintains session.
}

class VirtualUser {
    constructor(credentials) {
        this.creds = credentials;
        this.token = null;
        this.active = false;
        this.failures = 0;
    }

    async login() {
        if (this.token) return true;
        return runRequest('Login', async () => {
            const r = await _fetch(`${BASE_URL}/auth/login`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email: this.creds.email, password: this.creds.password })
            });
            if (r.ok) {
                const data = await r.json();
                this.token = data.access_token;
            }
            return r;
        });
    }

    async doRandomAction() {
        if (!this.token) {
            if (!await this.login()) return;
        }

        const actions = [
            // Profile
            { name: 'GetProfile', url: `${BASE_URL}/users/profile` },
            // Gym Stats/Info
            { name: 'GetGym', url: `${BASE_URL}/gyms/${gymId}` },
            // Plans
            { name: 'GetPlans', url: `${BASE_URL}/plans` },
            // Exercises (Heavier)
            { name: 'GetExercises', url: `${BASE_URL}/exercises` }
        ];

        const action = actions[randomInt(0, actions.length - 1)];

        await runRequest(action.name, () => _fetch(action.url, {
            headers: { 'Authorization': `Bearer ${this.token}` }
        }));

        await sleep(randomInt(CONFIG.MIN_THINK_TIME, CONFIG.MAX_THINK_TIME));
    }

    async runLoop(untilTimestamp) {
        this.active = true;
        while (Date.now() < untilTimestamp && this.active) {
            await this.doRandomAction();
        }
    }

    stop() {
        this.active = false;
    }
}

async function main() {
    console.log('🚀 Starting Stress Runner');

    // Load Data
    const data = JSON.parse(fs.readFileSync(DATA_FILE));
    usersList = data.users;
    gymId = data.gymId;

    console.log(`Loaded ${usersList.length} users.`);

    // Preparation: Instantiate VUs
    const vus = usersList.map(u => new VirtualUser(u));

    // Execution Steps
    for (const userCount of CONFIG.RAMP_STEPS) {
        console.log(`\n--- STEP: ${userCount} Concurrent Users ---`);
        const endTime = Date.now() + CONFIG.STEP_DURATION_MS;

        // Reset metrics for this step
        metrics.latencies = [];
        metrics.totalRequests = 0;
        metrics.errors = 0;
        const startStep = Date.now();

        // Activate N users
        // We pick the first N users from the list
        const activeGroup = vus.slice(0, userCount);

        // Start their loops
        const promises = activeGroup.map(vu => vu.runLoop(endTime));

        // Wait for time
        await Promise.all(promises);

        // Calculate Stats
        const validLatencies = metrics.latencies.sort((a, b) => a - b);
        const p95 = validLatencies[Math.floor(validLatencies.length * 0.95)] || 0;
        const avg = validLatencies.reduce((a, b) => a + b, 0) / (validLatencies.length || 1);
        const rps = metrics.totalRequests / (CONFIG.STEP_DURATION_MS / 1000);

        const result = {
            concurrency: userCount,
            rps: rps.toFixed(2),
            avgLatency: avg.toFixed(2) + 'ms',
            p95Latency: p95 + 'ms',
            errors: metrics.errors,
            errorRate: ((metrics.errors / metrics.totalRequests) * 100).toFixed(2) + '%'
        };

        metrics.stepResults.push(result);
        console.table([result]);
    }

    // Report
    console.log('\n\n--- FINAL REPORT ---');
    console.table(metrics.stepResults);

    fs.writeFileSync('stress_results.json', JSON.stringify(metrics.stepResults, null, 2));
}

main().catch(console.error);
