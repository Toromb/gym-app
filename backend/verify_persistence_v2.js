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

async function createPlan(token) {
    // 1. Get an exercise ID
    const exResp = await fetch(`${BASE_URL}/exercises`, { headers: { Authorization: `Bearer ${token}` } });
    const exercises = await exResp.json();
    let exerciseId = exercises.length > 0 ? exercises[0].id : null;

    if (!exerciseId) {
        const newEx = await fetch(`${BASE_URL}/exercises`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
            body: JSON.stringify({ name: 'Test Exercise' })
        });
        exerciseId = (await newEx.json()).id;
    }

    console.log(`Using Exercise ID: ${exerciseId}`);

    // 2. Create Plan
    const uniqueName = `Plan with Video ${Date.now()}`;
    const response = await fetch(`${BASE_URL}/plans`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
            name: uniqueName,
            durationWeeks: 4,
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
                                    videoUrl: "https://initial-video.com"
                                }
                            ]
                        }
                    ]
                }
            ]
        }),
    });
    return response.json();
}

async function getPlan(token, id) {
    const response = await fetch(`${BASE_URL}/plans/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
    });
    return response.json();
}

async function main() {
    try {
        console.log('Logging in...');
        const token = await login('profe@gym.com', 'admin123');

        console.log('Creating Plan...');
        const createdPlan = await createPlan(token);

        // Check immediate response
        try {
            const vid1 = createdPlan.weeks[0].days[0].exercises[0].videoUrl;
            console.log(`[Create Response] Video URL: ${vid1}`);
            if (vid1 !== "https://initial-video.com") {
                console.error("FAIL: Post-Create/FindOne response missing videoUrl");
            } else {
                console.log("PASS: Post-Create/FindOne response has videoUrl");
            }
        } catch (e) {
            console.error("FAIL: Parsing Create Response", e);
        }

        const planId = createdPlan.id;
        console.log(`Fetching Plan ID: ${planId}`);

        // Check GET response
        const fetchedPlan = await getPlan(token, planId);
        try {
            const vid2 = fetchedPlan.weeks[0].days[0].exercises[0].videoUrl;
            console.log(`[Get Response] Video URL: ${vid2}`);
            if (vid2 !== "https://initial-video.com") {
                console.error("FAIL: GET /id response missing videoUrl");
            } else {
                console.log("PASS: GET /id response has videoUrl");
            }
        } catch (e) {
            console.error("FAIL: Parsing GET Response", e);
        }

    } catch (e) {
        console.error(e);
    }
}

main();
