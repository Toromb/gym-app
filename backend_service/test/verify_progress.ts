import fetch from 'node-fetch';

const BASE_URL = 'http://localhost:3000';

async function main() {
  console.log('Starting Progress Verification...');

  try {
    // 1. Admin Login
    console.log('1. Logging in as Admin...');
    const adminLogin = await login('admin@gym.com', 'admin123').catch(() =>
      login('admin@gym.com', '123456'),
    );
    const adminToken = adminLogin.access_token;
    console.log('   Admin logged in.');

    // 2. Create Professor
    const profEmail = `profe_verification_${Date.now()}@test.com`;
    console.log(`2. Creating Professor (${profEmail})...`);
    const profPayload = {
      email: profEmail,
      password: '123456',
      firstName: 'Profe',
      lastName: 'Progress',
      role: 'profe',
      age: 30,
      gender: 'M',
    };
    console.log('   Payload:', JSON.stringify(profPayload));
    const profUser = await post('/users', profPayload, adminToken);
    const profLogin = await login(profEmail, '123456');
    const profToken = profLogin.access_token;

    // 3. Ensure Exercise Exists
    console.log('3. Fetching/Creating Exercise...');
    const exercises = await get('/exercises', profToken);
    let exerciseId;
    if (exercises.length > 0) {
      exerciseId = exercises[0].id;
    } else {
      const newEx = await post(
        '/exercises',
        {
          name: 'Progress Test Exercise',
          description: 'Desc',
          muscleGroup: 'Chest',
          videoUrl: 'http://test.com/video.mp4',
        },
        profToken,
      );
      exerciseId = newEx.id;
    }
    console.log('   Using Exercise ID:', exerciseId);

    // 4. Create Plan
    console.log('4. Creating Plan...');
    const plan = await post(
      '/plans',
      {
        name: 'Progress Test Plan',
        durationWeeks: 4,
        weeks: [
          {
            weekNumber: 1,
            days: [
              {
                dayOfWeek: 1,
                order: 1,
                title: 'Day 1',
                exercises: [
                  {
                    exerciseId: exerciseId,
                    sets: 3,
                    reps: '10',
                    order: 1,
                    videoUrl: 'http://youtube.com/test',
                    notes: 'Test notes',
                  },
                ],
              },
            ],
          },
        ],
      },
      profToken,
    );

    // 5. Create Student & Assign
    const studEmail = `stud_prog_${Date.now()}@test.com`;
    console.log(`5. Creating Student (${studEmail}) & Assigning...`);
    const studUser = await post(
      '/users',
      {
        email: studEmail,
        password: '123456',
        firstName: 'Student',
        lastName: 'Progress',
        age: 20,
        gender: 'F',
      },
      profToken,
    ); // Profe creates student

    await post(
      '/plans/assign',
      {
        planId: plan.id,
        studentId: studUser.id,
      },
      profToken,
    );

    // 6. Student Login
    const studLogin = await login(studEmail, '123456');
    const studToken = studLogin.access_token;

    // 7. Get Assignment to get ID
    console.log('7. Fetching Student Assignment...');
    // Student fetches their history/assignments
    const assignments = await get('/plans/student/history', studToken);
    if (assignments.length === 0)
      throw new Error('No assignments found for student');
    const assignmentId = assignments[0].id;
    console.log('   Assignment ID:', assignmentId);

    // 8. Mark Progress
    console.log('8. Marking Progress (Day & Exercise)...');

    // Get Day/Exercise IDs from plan
    const myPlan = await get('/plans/student/my-plan', studToken);
    const dayId = myPlan.weeks[0].days[0].id;
    const exId = myPlan.weeks[0].days[0].exercises[0].id; // PlanExercise ID (UUID)

    // Mark Day
    await patch(
      '/plans/student/progress',
      {
        studentPlanId: assignmentId,
        type: 'day',
        id: dayId,
        completed: true,
        date: '2025-01-01',
      },
      studToken,
    );

    // Mark Exercise
    await patch(
      '/plans/student/progress',
      {
        studentPlanId: assignmentId,
        type: 'exercise',
        id: exId,
        completed: true,
      },
      studToken,
    );

    console.log('   Progress Marked.');

    // 9. Verify
    console.log('9. Verifying Persistence...');
    const assignmentsRefetched = await get('/plans/student/history', studToken);
    const myAssignment = assignmentsRefetched[0];

    if (!myAssignment.progress) throw new Error('Progress object missing');

    // Check Day
    if (
      myAssignment.progress.days &&
      myAssignment.progress.days[dayId] &&
      myAssignment.progress.days[dayId].completed
    ) {
      console.log('   [PASS] Day marked as completed.');
    } else {
      console.error(
        '   [FAIL] Day NOT marked as completed.',
        JSON.stringify(myAssignment.progress),
      );
      throw new Error('Day verification failed');
    }

    // Check Exercise
    if (
      myAssignment.progress.exercises &&
      myAssignment.progress.exercises[exId]
    ) {
      console.log('   [PASS] Exercise marked as completed.');
    } else {
      console.error(
        '   [FAIL] Exercise NOT marked as completed.',
        JSON.stringify(myAssignment.progress),
      );
      throw new Error('Exercise verification failed');
    }

    console.log('PROGRESS VERIFICATION SUCCESSFUL');
  } catch (e) {
    console.error('ERROR:', e.message);
    process.exit(1);
  }
}

async function login(email: string, password: string) {
  const res = await fetch(`${BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  if (!res.ok) throw new Error(`Login failed: ${res.statusText}`);
  return res.json();
}

async function post(path: string, body: any, token?: string) {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };
  if (token) headers['Authorization'] = `Bearer ${token}`;
  const res = await fetch(`${BASE_URL}${path}`, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const txt = await res.text();
    console.error(`POST ${path} failed: ${res.status}`);
    const fs = require('fs');
    fs.writeFileSync('test_error.log', txt);
    throw new Error(`POST ${path} failed: ${res.status} ${txt}`);
  }
  return res.json();
}

async function patch(path: string, body: any, token?: string) {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };
  if (token) headers['Authorization'] = `Bearer ${token}`;
  const res = await fetch(`${BASE_URL}${path}`, {
    method: 'PATCH',
    headers,
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`PATCH ${path} failed: ${res.status} ${txt}`);
  }
  return res.json();
}

async function get(path: string, token?: string) {
  const headers: Record<string, string> = {};
  if (token) headers['Authorization'] = `Bearer ${token}`;
  const res = await fetch(`${BASE_URL}${path}`, {
    method: 'GET',
    headers,
  });
  if (!res.ok) throw new Error(`GET ${path} failed: ${res.statusText}`);
  return res.json();
}

main();
