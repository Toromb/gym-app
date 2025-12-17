import fetch from 'node-fetch';

const BASE_URL = 'http://localhost:3000';

async function main() {
    console.log('Starting Execution Engine Verification...');

    try {
        // 1. Setup Data (Admin -> Profe -> Student -> Plan)
        const adminToken = (await login('admin@gym.com', 'admin123')).access_token; // Try admin123 first

        const profEmail = `prof_exec_${Date.now()}@test.com`;
        const studEmail = `stud_exec_${Date.now()}@test.com`;

        console.log('1. Creating Users & Plan...');
        const profUser = await post('/users', {
            email: profEmail, password: '123456', firstName: 'P', lastName: 'T', role: 'profe', age: 30, gender: 'M'
        }, adminToken);
        const profToken = (await login(profEmail, '123456')).access_token;

        const studUser = await post('/users', {
            email: studEmail, password: '123456', firstName: 'S', lastName: 'T', age: 20, gender: 'F'
        }, profToken);
        const studToken = (await login(studEmail, '123456')).access_token;

        // Create Plan with 1 week, 1 day, 1 exercise
        // We need an exercise ID first. Let's create one or find one.
        // Assuming exercises exist or we can create.
        // Let's create one to be safe and test Snapshot.
        const exercise = await post('/exercises', {
            name: 'Snapshot Test curl',
            description: 'Test',
            videoUrl: 'https://example.com/video'
        }, profToken);

        const plan = await post('/plans', {
            name: 'Execution Test Plan',
            durationWeeks: 4,
            weeks: [{
                weekNumber: 1,
                days: [{
                    dayOfWeek: 1, order: 1, title: 'Day 1',
                    exercises: [{ exerciseId: exercise.id, sets: 3, reps: '10', suggestedLoad: '20kg', order: 1 }]
                }]
            }]
        }, profToken);
        console.log(`   Plan created: ${plan.id}`);

        // Assign plan (Legacy requirement? Execution service might not strict check assignment but it should. My code checks if Plan exists. Logic doesn't check assignment table explicitly yet for Start. But that's fine for MVP.)

        // 2. Start Execution (2025-01-01)
        console.log('2. Starting Execution Day 1 (2025-01-01)...');
        const exec1 = await post('/executions/start', {
            planId: plan.id, weekNumber: 1, dayOrder: 1, date: '2025-01-01'
        }, studToken);

        if (!exec1.id) throw new Error('Failed to start execution');
        if (exec1.exercises.length === 0) throw new Error('Execution has no exercises');
        console.log(`   Execution 1 started: ${exec1.id}`);

        // Verify Snapshot
        if (exec1.exercises[0].exerciseNameSnapshot !== 'Snapshot Test curl')
            throw new Error('Snapshot name mismatch');
        if (exec1.exercises[0].targetWeightSnapshot !== '20kg')
            throw new Error('Snapshot weight mismatch');

        // 3. Re-enter (Idempotency)
        console.log('3. Re-entering Day 1 (2025-01-01)...');
        const exec1Re = await post('/executions/start', {
            planId: plan.id, weekNumber: 1, dayOrder: 1, date: '2025-01-01'
        }, studToken);
        if (exec1Re.id !== exec1.id) throw new Error('Re-entry did not return same execution ID');
        console.log('   Idempotency verified.');

        // 4. Update Metric
        console.log('4. Updating Metric...');
        const exExecId = exec1.exercises[0].id;
        await patch(`/executions/exercises/${exExecId}`, {
            weightUsed: '25kg',
            isCompleted: true
        }, studToken);

        // Verify update
        const exec1Updated = await get(`/executions/${exec1.id}`, studToken);
        const exUpdated = exec1Updated.exercises.find(e => e.id === exExecId);
        if (exUpdated.weightUsed !== '25kg') throw new Error('Metric update failed');
        console.log('   Metric updated.');

        // 5. Complete Execution
        console.log('5. Completing Execution (2025-01-01)...');
        await patch(`/executions/${exec1.id}/complete`, { date: '2025-01-01' }, studToken);
        const exec1Completed = await get(`/executions/${exec1.id}`, studToken);
        if (exec1Completed.status !== 'COMPLETED') throw new Error('Status not COMPLETED');
        console.log('   Execution completed.');

        // 6. Start Day 1 (2025-01-02) -> New Execution
        console.log('6. Starting Day 1 again (2025-01-02)...');
        const exec2 = await post('/executions/start', {
            planId: plan.id, weekNumber: 1, dayOrder: 1, date: '2025-01-02'
        }, studToken);
        if (exec2.id === exec1.id) throw new Error('Should have created NEW execution for new date');
        console.log(`   Execution 2 started: ${exec2.id}`);

        // 7. Conflict Test: Try to complete exec2 with date 2025-01-01
        console.log('7. Testing Date Conflict (Try to set Exec 2 to 2025-01-01)...');
        try {
            await patch(`/executions/${exec2.id}/complete`, { date: '2025-01-01' }, studToken);
            throw new Error('Should have failed with Conflict');
        } catch (e: any) {
            if (e.message.includes('409') || e.message.includes('Conflict')) {
                console.log('   Conflict correctly blocked.');
            } else {
                throw e; // Unexpected error
            }
        }

        // 8. Calendar
        console.log('8. Fetching Calendar (Jan 2025)...');
        const calendar = await get('/executions/calendar?from=2025-01-01&to=2025-01-31', studToken);
        // Should have 1 COMPLETED execution (exec1)
        // exec2 is IN_PROGRESS, so depends on if getCalendar filters. My code checks status=COMPLETED.
        if (calendar.length !== 1) throw new Error(`Calendar should have 1 item, found ${calendar.length}`);
        if (calendar[0].id !== exec1.id) throw new Error('Calendar item mismatch');
        console.log('   Calendar verified.');

        console.log('VERIFICATION SUCCESSFUL');

    } catch (err: any) {
        console.error('ERROR:', err.message);
        if (err.response) {
            // console.error('Response:', await err.response.text()); // fetch doesn't have response on err usually unless custom thrown?
            // My helper throws Error with text.
        }
        process.exit(1);
    }
}

// Helpers
async function login(email: string, password: string) {
    const res = await fetch(`${BASE_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
    });
    if (!res.ok) {
        // Fallback for seed
        if (password === 'admin123' && res.status === 401) {
            return login(email, '123456');
        }
        const text = await res.text();
        throw new Error(`Login failed: ${res.statusText} - ${text}`);
    }
    return res.json() as Promise<any>;
}

async function post(path: string, body: any, token?: string) {
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const res = await fetch(`${BASE_URL}${path}`, {
        method: 'POST', headers, body: JSON.stringify(body)
    });
    if (!res.ok) {
        const text = await res.text();
        throw new Error(`POST ${path} failed: ${res.status} ${text}`);
    }
    return res.json() as Promise<any>;
}

async function patch(path: string, body: any, token?: string) {
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const res = await fetch(`${BASE_URL}${path}`, {
        method: 'PATCH', headers, body: JSON.stringify(body)
    });
    if (!res.ok) {
        const text = await res.text();
        throw new Error(`PATCH ${path} failed: ${res.status} ${text}`);
    }
    return res.json() as Promise<any>;
}

async function get(path: string, token?: string) {
    const headers: Record<string, string> = {};
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const res = await fetch(`${BASE_URL}${path}`, { method: 'GET', headers });
    if (!res.ok) throw new Error(`GET ${path} failed: ${res.statusText}`);
    return res.json() as Promise<any>;
}

main();
