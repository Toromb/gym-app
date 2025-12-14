
const fetch = require('node-fetch');

const BASE_URL = 'http://localhost:3000';

// Global State
let superAdminToken = '';
let profeToken = '';
let studentToken = '';

let createdGymId = '';
let createdProfeId = '';
let createdStudentId = '';
let createdExerciseId = '';
let createdPlanId = '';
let studentPlanId = '';

const COLORS = {
    reset: "\x1b[0m",
    green: "\x1b[32m",
    red: "\x1b[31m",
    yellow: "\x1b[33m",
    blue: "\x1b[34m",
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

async function runTest() {
    log("\n🚀 Starting Advanced Functional Test (E2E Flow)\n", COLORS.blue);

    // 1. Super Admin Login
    log("--- 1. Authentication (Super Admin) ---");
    const loginRes = await request('POST', '/auth/login', { email: 'superadmin@gym.com', password: 'admin123' });
    assert(loginRes.status === 201 || loginRes.status === 200, "Super Admin Login", loginRes.data);
    superAdminToken = loginRes.data.access_token;
    assert(!!superAdminToken, "Token received", loginRes.data);

    // 2. Create Gym
    log("\n--- 2. Gym Management ---");
    const gymRes = await request('POST', '/gyms', {
        businessName: `Test Gym ${Date.now()}`,
        address: "123 Test St",
        phone: "555-0000"
    }, superAdminToken);

    assert(gymRes.status === 201, "Create Gym", gymRes.data);
    createdGymId = gymRes.data && gymRes.data.id;
    assert(!!createdGymId, "Gym ID captured");

    // 3. Create Profe (by Super Admin)
    log("\n--- 3. User Management (Profe) ---");
    const profeEmail = `profe_${Date.now()}@test.com`;
    const profeRes = await request('POST', '/users', {
        email: profeEmail,
        password: "password123",
        firstName: "Profe",
        lastName: "Test",
        role: "profe",
        gymId: createdGymId
    }, superAdminToken);

    assert(profeRes.status === 201, "Create Professor", profeRes.data);
    createdProfeId = profeRes.data && profeRes.data.id;
    assert(!!createdProfeId, "Profe ID captured");

    // 4. Profe Login
    log("\n--- 4. Professor Login ---");
    const profeLoginRes = await request('POST', '/auth/login', { email: profeEmail, password: 'password123' });
    assert(profeLoginRes.status === 200 || profeLoginRes.status === 201, "Professor Login", profeLoginRes.data);
    profeToken = profeLoginRes.data && profeLoginRes.data.access_token;
    assert(!!profeToken, "Profe Token captured", profeLoginRes.data);

    // 5. Create Student (by Profe)
    log("\n--- 5. User Management (Student) ---");
    const studentEmail = `student_${Date.now()}@test.com`;
    const studentRes = await request('POST', '/users', {
        email: studentEmail,
        password: "password123",
        firstName: "Student",
        lastName: "Test",
        role: "alumno"
        // inferred gymId from Profe context
    }, profeToken);

    assert(studentRes.status === 201, "Create Student (as Profe)", studentRes.data);
    createdStudentId = studentRes.data && studentRes.data.id;
    assert(!!createdStudentId, "Student ID captured");

    // 6. Create Exercise (by Profe)
    log("\n--- 6. Exercise Creation ---");
    const exerciseRes = await request('POST', '/exercises', {
        name: `Pushup ${Date.now()}`,
        description: "Standard pushup",
        videoUrl: "http://video.com"
    }, profeToken);

    assert(exerciseRes.status === 201, "Create Exercise", exerciseRes.data);
    createdExerciseId = exerciseRes.data && exerciseRes.data.id;
    assert(!!createdExerciseId, "Exercise ID captured");

    // 7. Create Plan (by Profe)
    log("\n--- 7. Plan Creation ---");
    const planRes = await request('POST', '/plans', {
        name: "Functional Test Plan",
        objective: "Verify System",
        durationWeeks: 4,
        weeks: [
            {
                weekNumber: 1,
                days: [
                    {
                        dayOfWeek: 1,
                        order: 1,
                        title: "Day A",
                        exercises: [
                            {
                                exerciseId: createdExerciseId,
                                order: 1,
                                sets: 3,
                                reps: "10"
                            }
                        ]
                    }
                ]
            }
        ]
    }, profeToken);

    assert(planRes.status === 201, "Create Plan", planRes.data);
    createdPlanId = planRes.data && planRes.data.id;
    assert(!!createdPlanId, "Plan ID captured");

    // 8. Assign Plan
    log("\n--- 8. Plan Assignment ---");
    const assignRes = await request('POST', '/plans/assign', {
        planId: createdPlanId,
        studentId: createdStudentId
    }, profeToken);

    assert(assignRes.status === 201, "Assign Plan to Student", assignRes.data);

    // 9. Student Progress
    log("\n--- 9. Student Progress ---");
    // Login Student
    const studentLoginRes = await request('POST', '/auth/login', { email: studentEmail, password: 'password123' });
    assert(studentLoginRes.status === 200 || studentLoginRes.status === 201, "Student Login", studentLoginRes.data);
    studentToken = studentLoginRes.data && studentLoginRes.data.access_token;
    assert(!!studentToken, "Student Token captured");

    // Get Plan
    const myPlanRes = await request('GET', '/plans/student/my-plan', null, studentToken);
    assert(myPlanRes.status === 200, "Get My Plan", myPlanRes.data);

    const plan = myPlanRes.data && myPlanRes.data.plan;
    assert(!!plan, "Plan Object present in response", myPlanRes.data);
    assert(plan.id === createdPlanId, "Plan ID Match", plan);

    studentPlanId = myPlanRes.data.id;
    assert(!!studentPlanId, "StudentPlan ID captured", myPlanRes.data);

    // Mark Progress
    let planExercise = null;
    if (plan.weeks) {
        for (const week of plan.weeks) {
            if (week.days) {
                for (const day of week.days) {
                    if (day.exercises && day.exercises.length > 0) {
                        planExercise = day.exercises[0];
                        break;
                    }
                }
            }
            if (planExercise) break;
        }
    }

    assert(!!planExercise, "Plan Exercise found for progress", plan);

    const planExerciseId = planExercise.id;
    assert(!!planExerciseId, "PlanExercise ID found");

    const progressRes = await request('POST', '/plans/student/progress', {
        studentPlanId: studentPlanId,
        type: 'exercise',
        id: planExerciseId,
        completed: true,
        date: new Date().toISOString().split('T')[0]
    }, studentToken);

    assert(progressRes.status === 201 || progressRes.status === 200, "Mark Exercise Complete", progressRes.data);

    log("\n✅✅✅ EXCELLENT! ALL FUNCTIONAL TESTS PASSED! ✅✅✅", COLORS.green);
}

runTest().catch(e => {
    log(`\n❌ UNEXPECTED ERROR: ${e.message}`, COLORS.red);
    log(e.stack, COLORS.red);
    process.exit(1);
});
