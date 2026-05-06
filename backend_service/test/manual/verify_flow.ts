async function verify() {
  const baseUrl = 'http://localhost:3000';

  console.log('Starting Verification...');

  // Helper for requests
  const request = async (
    method: string,
    path: string,
    body?: any,
    token?: string,
  ) => {
    const headers: any = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;

    try {
      const response = await fetch(`${baseUrl}${path}`, {
        method,
        headers,
        body: body ? JSON.stringify(body) : undefined,
      });

      const data = await response.json();
      if (!response.ok) {
        console.error(`${method} ${path} Failed:`, JSON.stringify(data));
        throw new Error(`Request failed: ${response.statusText}`);
      }
      return data;
    } catch (e) {
      console.error(`Request Error ${method} ${path}:`, e);
      throw e;
    }
  };

  try {
    // 1. Login as Professor
    console.log('Logging in as Professor...');
    const loginRes = await request('POST', '/auth/login', {
      email: 'profe@gym.com',
      password: 'admin123',
    });
    const teacherToken = loginRes.access_token;
    console.log('Professor Logged In');

    // 2. Create Student
    console.log('Creating Student...');
    const studentEmail = `student_${Date.now()}@test.com`;
    const studentRes = await request(
      'POST',
      '/users',
      {
        firstName: 'Test',
        lastName: 'Student',
        email: studentEmail,
        password: 'password123',
        role: 'alumno',
        age: 25,
        gender: 'M',
        notes: 'Test student',
      },
      teacherToken,
    );
    const studentId = studentRes.id;
    console.log(`Student Created: ${studentEmail} (${studentId})`);

    // 3. Create Plan
    console.log('Creating Plan...');
    const planRes = await request(
      'POST',
      '/plans',
      {
        name: 'Hypertrophy Phase 1',
        objective: 'Gain Muscle',
        durationWeeks: 4,
        generalNotes: 'Focus on form',
        weeks: [
          {
            weekNumber: 1,
            days: [
              {
                title: 'Chest Day',
                dayOfWeek: 1,
                order: 1,
                dayNotes: 'Heavy lifting',
                exercises: [],
              },
            ],
          },
        ],
      },
      teacherToken,
    );
    const planId = planRes.id;
    console.log(`Plan Created: ${planRes.name} (${planId})`);

    // 4. Assign Plan
    console.log('Assigning Plan to Student...');
    await request(
      'POST',
      `/plans/${planId}/assign`,
      {
        studentId: studentId,
      },
      teacherToken,
    );
    console.log('Plan Assigned');

    // 5. Login as Student
    console.log('Logging in as Student...');
    const studentLoginRes = await request('POST', '/auth/login', {
      email: studentEmail,
      password: 'password123',
    });
    const studentToken = studentLoginRes.access_token;
    console.log('Student Logged In');

    // 6. Get My Plan
    console.log('Fetching My Plan...');
    const myPlan = await request(
      'GET',
      '/plans/student/my-plan',
      undefined,
      studentToken,
    );

    console.log('Retrieved Plan:', JSON.stringify(myPlan));

    if (myPlan && myPlan.id === planId) {
      console.log('Verification SUCCESS: Student retrieved the correct plan.');
    } else {
      console.error(
        `Verification FAILED: Plan ID mismatch. Expected ${planId}, got ${myPlan?.id}`,
      );
    }
  } catch (error) {
    console.error('Verification Failed with Error:', error);
  }
}

verify();
