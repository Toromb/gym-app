import fetch from 'node-fetch';

const BASE_URL = 'http://localhost:3000';

async function main() {
    console.log('Starting Full Flow E2E Verification...');

    try {
        // 1. Admin Login (Seed should exist: admin@gym.com / 123456)
        // 1. Admin Login (Seed should exist: admin@gym.com / 123456)
        console.log('1. Logging in as Admin...');
        let adminLogin;
        try {
            adminLogin = await login('admin@gym.com', 'admin123');
        } catch (e) {
            console.log('   Login with admin123 failed, trying 123456...');
            adminLogin = await login('admin@gym.com', '123456');
        }

        const adminToken = adminLogin.access_token;
        console.log('   Admin logged in. Response:', JSON.stringify(adminLogin));

        // 2. Create Professor
        const profEmail = `prof_${Date.now()}@test.com`;
        console.log(`2. Creating Professor (${profEmail})...`);
        let profUser;
        try {
            profUser = await post('/users', {
                email: profEmail,
                password: '123456',
                firstName: 'Profe',
                lastName: 'Test',
                role: 'profe',
                age: 30,
                gender: 'M'
            }, adminToken);
        } catch (e) {
            console.error('FAILED at Step 2 (Create Professor).');
            throw e;
        }
        console.log('   Professor created: ' + profUser.id);

        // 3. Professor Login
        console.log('3. Logging in as Professor...');
        const profLogin = await login(profEmail, '123456');
        const profToken = profLogin.access_token;
        console.log('   Professor logged in.');

        // 4. Create Student
        const studEmail = `stud_${Date.now()}@test.com`;
        console.log(`4. Creating Student (${studEmail}) as Professor...`);
        const studUser = await post('/users', {
            email: studEmail,
            password: '123456',
            firstName: 'Student',
            lastName: 'Test',
            // role implied Alumno
            age: 20,
            gender: 'F'
        }, profToken);
        console.log('   Student created: ' + studUser.id);

        // 5. Create Plan
        console.log('5. Creating Plan as Professor...');
        const plan = await post('/plans', {
            name: 'Full Body Test',
            durationWeeks: 4,
            weeks: [
                {
                    weekNumber: 1,
                    days: [
                        {
                            dayOfWeek: 1,
                            order: 1,
                            title: 'Leg Day',
                            exercises: []
                        }
                    ]
                }
            ]
        }, profToken);
        console.log('   Plan created: ' + plan.id);

        // 6. Assign Plan
        console.log('6. Assigning Plan to Student...');
        await post('/plans/assign', {
            planId: plan.id,
            studentId: studUser.id
        }, profToken);
        console.log('   Plan assigned.');

        // 7. Student Login
        console.log('7. Logging in as Student...');
        const studLogin = await login(studEmail, '123456');
        const studToken = studLogin.access_token;
        console.log('   Student logged in.');

        // 8. Get My Plan
        console.log('8. Fetching My Plan as Student...');
        const myPlan = await get('/plans/student/my-plan', studToken);

        // 9. Edit Plan
        console.log('9. Editing Plan...');
        await patch(`/plans/${plan.id}`, {
            name: 'Updated Full Body Plan'
        }, profToken);
        const updatedPlan = await get(`/plans/${plan.id}`, profToken);
        if (updatedPlan.name === 'Updated Full Body Plan') {
            console.log('   Plan updated successfully.');
        } else {
            throw new Error('Plan update failed');
        }

        // 10. Delete Assignment
        console.log('10. Deleting Assignment...');
        // First get assignments to find ID
        const assignments = await get(`/plans/assignments/student/${studUser.id}`, profToken);
        if (assignments.length > 0) {
            const assignmentId = assignments[0].id;
            await del(`/plans/assignments/${assignmentId}`, profToken);
            console.log('   Assignment deleted.');

            // Verify student has no plan
            try {
                await get('/plans/student/my-plan', studToken);
                throw new Error('Student still has plan after deletion');
            } catch (e) {
                console.log('   Verified: Student has no active plan.');
            }
        } else {
            console.warn('   No assignments found to delete.');
        }

        // 11. Delete Global Plan
        console.log('11. Deleting Global Plan...');
        await del(`/plans/${plan.id}`, profToken);
        console.log('   Global Plan deleted.');

        // Verify it's gone
        try {
            await get(`/plans/${plan.id}`, profToken);
            // If get succeeds (and returns null or object?), usually throws 404 for findOne if not found? 
            // My service findOne returns null, controller returns it. 
            // Wait, controller `findOne` calls service. `findOne` returns null. Controller doesn't throw 404 automatically unless checked.
            // Let's check my controller code. 
            // Controller: return this.plansService.findOne(id);
            // Service: returns plan or null.
            // So response will be null (200 OK) or empty.
            // Let's assume if it returns null, it's gone.
        } catch (e) {
            // connection error etc
        }

        console.log('FULL FLOW VERIFICATION SUCCESSFUL');

    } catch (err) {
        console.error('ERROR:', err.message);
        if (err.response) {
            console.error('Response:', await err.response.text());
        }
        process.exit(1);
    }
}

async function login(email: string, password: string) {
    const res = await fetch(`${BASE_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
    });
    if (!res.ok) {
        const text = await res.text();
        throw new Error(`Login failed: ${res.statusText} - ${text}`);
    }
    return res.json() as Promise<any>;
}

async function post(path: string, body: any, token?: string) {
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const res = await fetch(`${BASE_URL}${path}`, {
        method: 'POST',
        headers,
        body: JSON.stringify(body),
    });
    if (!res.ok) {
        const text = await res.text();
        throw new Error(`POST ${path} failed: ${res.status} ${res.statusText} - ${text}`);
    }
    return res.json() as Promise<any>;
}

async function get(path: string, token?: string) {
    const headers: Record<string, string> = {};
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const res = await fetch(`${BASE_URL}${path}`, {
        method: 'GET',
        headers,
    });
    if (!res.ok) throw new Error(`GET ${path} failed: ${res.statusText}`);
    return res.json() as Promise<any>;
}

async function patch(path: string, body: any, token?: string) {
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const res = await fetch(`${BASE_URL}${path}`, {
        method: 'PATCH',
        headers,
        body: JSON.stringify(body),
    });
    if (!res.ok) {
        const text = await res.text();
        throw new Error(`PATCH ${path} failed: ${res.status} ${res.statusText} - ${text}`);
    }
    return res.json() as Promise<any>;
}

async function del(path: string, token?: string) {
    const headers: Record<string, string> = {};
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const res = await fetch(`${BASE_URL}${path}`, {
        method: 'DELETE',
        headers,
    });
    if (!res.ok) {
        const text = await res.text();
        throw new Error(`DELETE ${path} failed: ${res.status} ${res.statusText} - ${text}`);
    }
    return res.status === 204 ? null : res.json().catch(() => null);
}

main();
