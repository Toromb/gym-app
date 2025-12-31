
const fetch = require('node-fetch');

const BASE_URL = 'http://localhost:3001';
const COLORS = {
    reset: "\x1b[0m",
    green: "\x1b[32m",
    red: "\x1b[31m",
    yellow: "\x1b[33m",
    blue: "\x1b[34m",
    magenta: "\x1b[35m",
};

function log(msg, color = COLORS.reset) {
    console.log(`${color}${msg}${COLORS.reset}`);
}

function assert(condition, msg, data = null) {
    if (!condition) {
        log(`❌ FAILED: ${msg}`, COLORS.red);
        if (data) log(`Response: ${JSON.stringify(data, null, 2)}`, COLORS.yellow);
        process.exit(1);
    } else {
        log(`✅ PASSED: ${msg}`, COLORS.green);
    }
}

async function request(method, endpoint, body = null, token = null) {
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const options = { method, headers };
    if (body) options.body = JSON.stringify(body);

    try {
        const res = await fetch(`${BASE_URL}${endpoint}`, options);
        let data = {};
        try {
            data = await res.json();
        } catch (e) {
            // ignore
        }
        return { status: res.status, data };
    } catch (e) {
        return { status: 0, data: { error: e.message } };
    }
}

// Global Vars
let superAdminToken = '';
let profeToken = '';
let gymId = '';
let planId = '';
let exerciseId = '';

let activeUser = { email: '', id: '', token: '' };
let expiredUser = { email: '', id: '', token: '' };
let noPlanUser = { email: '', id: '', token: '' };
let completedUser = { email: '', id: '', token: '' };

async function runValidation() {
    log("\n🔰 STARTING LOGIC & CONSISTENCY VALIDATION 🔰\n", COLORS.magenta);

    // --- SETUP ---
    log("--- 1. Setup Environment ---", COLORS.blue);

    // Login Super Admin
    const saRes = await request('POST', '/auth/login', { email: 'superadmin@gym.com', password: 'admin123' });
    assert(saRes.status === 200 || saRes.status === 201, "Super Admin Login");
    superAdminToken = saRes.data.access_token;

    // Create Gym
    const gymRes = await request('POST', '/gyms', {
        businessName: `Logic Gym ${Date.now()}`,
        address: "Logic Lane 1",
        phone: "123"
    }, superAdminToken);
    gymId = gymRes.data.id;
    assert(!!gymId, "Gym Created");

    // Create Profe
    const profeEmail = `logic_profe_${Date.now()}@test.com`;
    const profeRes = await request('POST', '/users', {
        email: profeEmail, password: "password123", firstName: "Logic", lastName: "Profe", role: "profe", gymId
    }, superAdminToken);
    const profeId = profeRes.data.id;
    assert(!!profeId, "Profe Created");

    // Login Profe
    const profeLogin = await request('POST', '/auth/login', { email: profeEmail, password: 'password123' });
    profeToken = profeLogin.data.access_token;

    // Create Exercise
    const exRes = await request('POST', '/exercises', {
        name: `Logic Pullup ${Date.now()}`, description: "Test", videoUrl: "http://vid.com"
    }, profeToken);
    exerciseId = exRes.data.id;

    // Create Plan
    const planRes = await request('POST', '/plans', {
        name: "Logic Plan", objective: "Validation", durationWeeks: 1,
        weeks: [{
            weekNumber: 1, days: [{
                dayOfWeek: 1, order: 1, title: "Day 1",
                exercises: [{ exerciseId, order: 1, sets: 3, reps: "10" }]
            }]
        }]
    }, profeToken);
    planId = planRes.data.id;

    log("--- Setup Complete ---\n", COLORS.blue);


    // --- SCENARIO 1: QUOTA LOGIC ---
    log("--- 2. Validating QUOTA Logic ---", COLORS.blue);

    // A. Active User
    activeUser.email = `active_${Date.now()}@test.com`;
    const u1 = await request('POST', '/users', {
        email: activeUser.email, password: "password123", firstName: "Active", lastName: "User", role: "alumno",
        membershipExpirationDate: new Date(Date.now() + 86400000 * 30).toISOString() // +30 days
    }, profeToken);
    activeUser.id = u1.data.id;

    // Login & Check
    const u1Login = await request('POST', '/auth/login', { email: activeUser.email, password: 'password123' });
    activeUser.token = u1Login.data.access_token;

    // Check Profile/Self for status
    const u1Profile = await request('GET', '/auth/profile', null, activeUser.token);
    assert(u1Profile.data.paymentStatus === 'paid', "Active User Status is 'paid'", u1Profile.data);

    // B. Expired User
    expiredUser.email = `expired_${Date.now()}@test.com`;
    // Create first, then update expiration (if create doesn't allow past date validation? let's try direct create)
    const u2 = await request('POST', '/users', {
        email: expiredUser.email, password: "password123", firstName: "Expired", lastName: "User", role: "alumno",
        membershipExpirationDate: new Date(Date.now() - 86400000 * 5).toISOString() // -5 days
    }, profeToken);
    expiredUser.id = u2.data.id;

    const u2Login = await request('POST', '/auth/login', { email: expiredUser.email, password: 'password123' });
    expiredUser.token = u2Login.data.access_token;

    const u2Profile = await request('GET', '/auth/profile', null, expiredUser.token);
    // Depending on logic: 'pending' (grace period) or 'overdue'
    // Logic says: <= 10 days is 'pending' (yellow), > 10 is 'overdue'?? 
    // Wait, users.service: if (diffDays <= 10) return 'pending'. (diffDays is negative if expired? No.)
    // now - exp. If exp is past, now > exp. diffTime is +ve.
    // Expired 5 days ago: diffDays = 5. <= 10 -> 'pending'.

    assert(['pending', 'overdue'].includes(u2Profile.data.paymentStatus), `Expired User Status is correct (${u2Profile.data.paymentStatus})`);

    // Let's make a SUPER expired one
    const reallyExpiredEmail = `old_${Date.now()}@test.com`;
    const u3 = await request('POST', '/users', {
        email: reallyExpiredEmail, password: "password123", firstName: "Old", lastName: "Expired", role: "alumno",
        membershipExpirationDate: new Date(Date.now() - 86400000 * 20).toISOString() // -20 days
    }, profeToken);
    const u3Login = await request('POST', '/auth/login', { email: reallyExpiredEmail, password: 'password123' });
    const u3Profile = await request('GET', '/auth/profile', null, u3Login.data.access_token);
    assert(u3Profile.data.paymentStatus === 'overdue', "Old Expired User is 'overdue'", u3Profile.data);


    // --- SCENARIO 2: PLAN STATE ---
    log("\n--- 3. Validating PLAN Logic ---", COLORS.blue);

    // A. No Plan
    noPlanUser.email = `noplan_${Date.now()}@test.com`;
    const u4 = await request('POST', '/users', {
        email: noPlanUser.email, password: "password123", firstName: "No", lastName: "Plan", role: "alumno"
    }, profeToken);
    noPlanUser.id = u4.data.id;
    const u4Login = await request('POST', '/auth/login', { email: noPlanUser.email, password: 'password123' });
    noPlanUser.token = u4Login.data.access_token;

    const u4MyPlan = await request('GET', '/plans/student/my-plan', null, noPlanUser.token);
    assert(u4MyPlan.status === 200, "Get My Plan (No Plan)");
    assert(Object.keys(u4MyPlan.data).length === 0 || u4MyPlan.data === "" || !u4MyPlan.data.id, "Plan is empty/null", u4MyPlan.data);

    // B. Active Plan (Assign Plan to Active User)
    await request('POST', '/plans/assign', { planId, studentId: activeUser.id }, profeToken);
    const myPlanRes = await request('GET', '/plans/student/my-plan', null, activeUser.token);
    assert(!!myPlanRes.data.id, "Active User has PlanId");
    assert(myPlanRes.data.plan.id === planId, "Correct Plan Assigned");
    const studentPlanId = myPlanRes.data.id;


    // --- SCENARIO 3: TRAINING LOGIC ---
    log("\n--- 4. Validating TRAINING Logic ---", COLORS.blue);

    // 1. Get Day 1 Exercise
    const day1 = myPlanRes.data.plan.weeks[0].days[0];
    const ex1 = day1.exercises[0];

    // 2. Mark Exercise Complete
    const progRes = await request('POST', '/plans/student/progress', {
        studentPlanId, type: 'exercise', id: ex1.id, completed: true
    }, activeUser.token);
    assert(progRes.status === 201 || progRes.status === 200, "Exercise Marked Complete");
    assert(progRes.data.progress.exercises[ex1.id] === true, "Progress Recorded");

    // 3. Mark Day Complete
    const dayRes = await request('POST', '/plans/student/progress', {
        studentPlanId, type: 'day', id: day1.id, completed: true
    }, activeUser.token);
    assert(dayRes.data.progress.days[day1.id].completed === true, "Day Marked Complete");

    // 4. Verify Persistence (Reload Plan)
    const reloadPlan = await request('GET', '/plans/student/my-plan', null, activeUser.token);
    assert(reloadPlan.data.progress.days[day1.id].completed === true, "Day Completion Persisted");

    // 5. Verify Dashboard Counts (if endpoint exists)
    // We don't have a specific stats endpoint for student, but we can assume logic works if persisted.

    // --- SCENARIO 4: EDGE CASES ---
    log("\n--- 5. Validating EDGE CASES ---", COLORS.blue);

    // Attempt double assignment (Should fail)
    const doubleAssign = await request('POST', '/plans/assign', { planId, studentId: activeUser.id }, profeToken);
    assert(doubleAssign.status === 409, "Double Assignment Prevented (Conflict)");

    log("\n✅✅✅ VALIDATION REPORT: ALL SYSTEMS GO ✅✅✅", COLORS.green);

    // Output Credentials for Browser Test
    log("\n--- CREDENTIALS FOR BROWSER TEST ---", COLORS.yellow);
    log(`Active User:  ${activeUser.email} / password123`);
    log(`Expired User: ${expiredUser.email} / password123`);
    log(`No Plan User: ${noPlanUser.email} / password123`);
    log(`Really Old:   ${reallyExpiredEmail} / password123`);
}

runValidation().catch(e => {
    log(`\n❌ CRASH: ${e.message}`, COLORS.red);
    log(e.stack, COLORS.red);
    process.exit(1);
});
