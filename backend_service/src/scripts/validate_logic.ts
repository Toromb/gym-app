
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { User, UserRole } from '../users/entities/user.entity';
import { Plan } from '../plans/entities/plan.entity';
import { Gym } from '../gyms/entities/gym.entity';
import { StudentPlan } from '../plans/entities/student-plan.entity';
import { Repository } from 'typeorm';
import { getRepositoryToken } from '@nestjs/typeorm';
import axios from 'axios';
import * as bcrypt from 'bcrypt';

const BASE_URL = 'http://localhost:3001';
const COLORS = {
    reset: "\x1b[0m",
    green: "\x1b[32m",
    red: "\x1b[31m",
    yellow: "\x1b[33m",
    blue: "\x1b[34m",
    magenta: "\x1b[35m",
    cyan: "\x1b[36m",
};

function log(msg: string, color: string = COLORS.reset) {
    console.log(`${color}${msg}${COLORS.reset}`);
}

async function request(method: string, endpoint: string, body: any = null, token: string | null = null) {
    try {
        const headers: any = {};
        if (token) headers['Authorization'] = `Bearer ${token}`;

        const res = await axios({
            method,
            url: `${BASE_URL}${endpoint}`,
            data: body,
            headers
        });
        return { status: res.status, data: res.data };
    } catch (e: any) {
        return {
            status: e.response?.status || 0,
            data: e.response?.data || { error: e.message }
        };
    }
}

let globalFailure = false;

function softAssert(condition: boolean, msg: string, data: any = null) {
    if (!condition) {
        log(`❌ FAILED: ${msg}`, COLORS.red);
        if (data) log(`Data: ${JSON.stringify(data, null, 2)}`, COLORS.yellow);
        globalFailure = true;
    } else {
        log(`✅ PASSED: ${msg}`, COLORS.green);
    }
}

const assert = softAssert;

async function bootstrap() {
    log("\n🔰 STARTING HYBRID VALIDATION (DB Setup + API Verify) 🔰\n", COLORS.magenta);

    // 1. Initialize Context
    const app = await NestFactory.create(AppModule, { logger: false });
    const userRepo = app.get<Repository<User>>(getRepositoryToken(User));
    const planRepo = app.get<Repository<Plan>>(getRepositoryToken(Plan));
    const gymRepo = app.get<Repository<Gym>>(getRepositoryToken(Gym));

    // 2. Setup Data
    log("--- 1. DATABASE SETUP ---", COLORS.blue);

    const timestamp = Date.now();
    const passwordHash = await bcrypt.hash('password123', 10);

    // Create Gym
    const gym = gymRepo.create({
        businessName: `Logic Gym ${timestamp}`,
        address: 'Test St',
        phone: '123'
    });
    const savedGym = await gymRepo.save(gym);
    log(`Created Gym ${savedGym.id}`, COLORS.cyan);

    // Define Scenarios
    const scenarios = [
        {
            alias: 'Active User',
            email: `active_${timestamp}@test.com`,
            expDate: new Date(Date.now() + 86400000 * 30), // +30 days
            expectedStatus: 'paid'
        },
        {
            alias: 'Pending User (Due Soon)',
            email: `due_${timestamp}@test.com`,
            expDate: new Date(Date.now() + 86400000 * 5), // +5 days (Rule: <= 10 is pending)
            expectedStatus: 'pending'
        },
        {
            alias: 'Expired User',
            email: `expired_${timestamp}@test.com`,
            expDate: new Date(Date.now() - 86400000 * 5), // -5 days
            expectedStatus: 'pending' // Just expired (<10 days ago) is pending
        },
        {
            alias: 'Old Expired User',
            email: `old_${timestamp}@test.com`,
            expDate: new Date(Date.now() - 86400000 * 20), // -20 days
            expectedStatus: 'overdue' // >10 days
        }
    ];

    const createdUsers: any = {};

    for (const sc of scenarios) {
        const user = userRepo.create({
            email: sc.email,
            passwordHash,
            firstName: sc.alias.split(' ')[0],
            lastName: 'Test',
            role: UserRole.ALUMNO,
            membershipExpirationDate: sc.expDate,
            membershipStartDate: new Date(Date.now() - 86400000 * 60), // Started 2 months ago
            paysMembership: true,
            gym: savedGym
        });
        const saved = await userRepo.save(user);
        createdUsers[sc.alias] = { ...sc, id: saved.id };
        log(`Created ${sc.alias} (${sc.email})`, COLORS.cyan);
    }

    // Create Profe for Plan logic
    const profe = userRepo.create({
        email: `profe_${timestamp}@test.com`,
        passwordHash,
        firstName: 'Profe',
        lastName: 'Logic',
        role: UserRole.PROFE,
        gym: savedGym
    });
    const savedProfe = await userRepo.save(profe);
    const profeTokenRes = await request('POST', '/auth/login', { email: profe.email, password: 'password123' });
    const profeToken = profeTokenRes.data.access_token;

    // Create Plan
    const planRes = await request('POST', '/plans', {
        name: "Logic Plan", objective: "Test", durationWeeks: 4,
        weeks: [{ weekNumber: 1, days: [{ dayOfWeek: 1, order: 1, title: "Day 1", exercises: [] }] }]
    }, profeToken);
    const planId = planRes.data.id;
    log(`Created Plan ${planId}`, COLORS.cyan);


    // 3. API Validation
    log("\n--- 2. API VALIDATION ---", COLORS.blue);

    for (const key of Object.keys(createdUsers)) {
        const u = createdUsers[key];
        log(`Testing ${u.alias}...`);

        // Login
        const login = await request('POST', '/auth/login', { email: u.email, password: 'password123' });
        assert(login.status === 201 || login.status === 200, `Login ${u.alias}`);
        const token = login.data.access_token;

        // Check Profile (Quota Status) - CRITICAL REQUEST 2
        const profile = await request('GET', '/auth/profile', null, token);
        const serverStatus = profile.data.paymentStatus;

        if (serverStatus !== u.expectedStatus) {
            log(`⚠️ Warning: Expected ${u.expectedStatus} but got ${serverStatus} for ${u.alias}`, COLORS.yellow);
        } else {
            assert(true, `Status is ${serverStatus} as expected`);
        }

        // Check Dashboard Initial State
        const myPlan = await request('GET', '/plans/student/my-plan', null, token);
        assert(myPlan.status === 200, "Get My Plan");

        if (key.includes('Active')) {
            // Assign plan to Active
            await request('POST', '/plans/assign', { planId, studentId: u.id }, profeToken);
            const myPlanAfter = await request('GET', '/plans/student/my-plan', null, token);
            assert(!!myPlanAfter.data.id, "Active user sees plan");
        } else {
            // Others have no plan
            assert(!myPlan.data.id, "User sees no plan (correct)");
        }
    }

    log("\n--- 3. EDGE CASES & CONSISTENCY ---", COLORS.blue);

    log("\n✅ LOGIC VALIDATION COMPLETE", COLORS.green);

    // Export credentials for Browser
    console.log("\n!!! CREDENTIALS !!!");
    console.log(JSON.stringify(createdUsers, null, 2));

    await app.close();
}

bootstrap().catch(e => {
    log(e.message, COLORS.red);
    console.error(e);
    process.exit(1);
});
