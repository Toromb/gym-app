const BASE_URL = 'http://localhost:3000';

async function login(email, password) {
    const response = await fetch(`${BASE_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
    });

    if (!response.ok) throw new Error(`Login failed: ${response.statusText}`);
    const data = await response.json();
    return data.access_token;
}

async function createPlan(token, name) {
    const response = await fetch(`${BASE_URL}/plans`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
            name,
            durationWeeks: 4,
            weeks: [
                {
                    weekNumber: 1,
                    days: [
                        {
                            dayOfWeek: 1,
                            order: 1,
                            exercises: []
                        }
                    ]
                }
            ]
        }),
    });
    return response.json();
}

async function updatePlan(token, planId, exerciseId) {
    const body = {
        name: "Updated Plan Name",
        weeks: [
            {
                weekNumber: 1,
                days: [
                    {
                        dayOfWeek: 1,
                        order: 1,
                        exercises: [
                            {
                                exerciseId: exerciseId,
                                sets: 3,
                                reps: "10",
                                order: 1,
                                videoUrl: "https://www.youtube.com/watch?v=dQw4w9WgXcQ" // The payload
                            }
                        ]
                    }
                ]
            }
        ]
    };

    console.log('Sending Update Payload:', JSON.stringify(body, null, 2));

    const response = await fetch(`${BASE_URL}/plans/${planId}`, {
        method: 'PATCH',
        headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(body),
    });

    return response.json();
}

async function getExerciseId(token) {
    const response = await fetch(`${BASE_URL}/exercises`, {
        headers: { Authorization: `Bearer ${token}` }
    });
    const data = await response.json();
    return data.length > 0 ? data[0].id : null;
}

async function main() {
    try {
        console.log('Logging in...');
        const token = await login('profe@gym.com', 'admin123');

        console.log('Getting Exercise ID...');
        let exerciseId = await getExerciseId(token);
        if (!exerciseId) {
            console.log('Creating generic exercise...');
            const exResp = await fetch(`${BASE_URL}/exercises`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
                body: JSON.stringify({ name: 'Generic Ex' })
            });
            exerciseId = (await exResp.json()).id;
        }

        console.log('Creating Test Plan...');
        const plan = await createPlan(token, 'Test Persistence Plan');
        console.log('Plan Created:', plan.id);

        console.log('Updating Plan with videoUrl...');
        const updatedPlan = await updatePlan(token, plan.id, exerciseId);

        const videoUrl = updatedPlan.weeks[0].days[0].exercises[0].videoUrl;
        console.log('Updated Plan Video URL:', videoUrl);

        if (videoUrl === "https://www.youtube.com/watch?v=dQw4w9WgXcQ") {
            console.log('SUCCESS: Video URL persisted.');
        } else {
            console.error('FAILURE: Video URL NOT persisted.');
        }

    } catch (e) {
        console.error(e);
    }
}

main();
