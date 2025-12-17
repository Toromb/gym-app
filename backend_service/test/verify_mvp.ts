
import axios from 'axios';

const BASE_URL = 'http://localhost:3000';
let teacherToken: string;
let studentToken: string;
let teacherId: string;
let studentId: string;
let planId: string;
let studentPlanId: string;

async function run() {
    console.log('🚀 Starting MVP Happy Path Verification...');

    try {
        // 1. Teacher Login
        console.log('\n🔐 1. Admin/Teacher Login...');
        const loginRes = await axios.post(`${BASE_URL}/auth/login`, {
            email: 'admin@gym.com',
            password: 'admin123'
        });
        teacherToken = loginRes.data.access_token;
        teacherId = loginRes.data.user.id;
        const gymId = loginRes.data.user.gym?.id;
        console.log(`✅ Teacher Logged In (ID: ${teacherId}, Gym: ${gymId || 'None'})`);

        // 2. Create Student
        console.log('\n👤 2. Create Student...');
        const uniqueSuffix = Date.now().toString().slice(-4);
        const createStudentRes = await axios.post(`${BASE_URL}/users`, {
            email: `student_mvp_${uniqueSuffix}@test.com`,
            password: 'password123',
            firstName: 'Happy',
            lastName: 'Student',
            role: 'alumno',
            // gymId: gymId // Don't send this if user is not Super Admin (or backend ignores it)
            // If backend auto-assigns based on creator, we rely on that.
        }, { headers: { Authorization: `Bearer ${teacherToken}` } });
        studentId = createStudentRes.data.id;
        console.log(`✅ Student Created: ${studentId}`);

        // 2b. Fetch Exercises to get valid IDs
        console.log('\n🏋️ 2b. Fetch Exercises...');
        const exercisesRes = await axios.get(`${BASE_URL}/exercises`, {
            headers: { Authorization: `Bearer ${teacherToken}` }
        });
        const fetchedExercises = exercisesRes.data;
        if (fetchedExercises.length < 2) throw new Error('Not enough exercises in DB to run test');
        const ex1Id = fetchedExercises[0].id;
        const ex2Id = fetchedExercises[1].id;
        console.log(`✅ Exercises Found: ${ex1Id}, ${ex2Id}`);

        // 3. Create Plan
        console.log('\n📝 3. Create Plan...');
        const createPlanRes = await axios.post(`${BASE_URL}/plans`, {
            name: `MVP Plan ${uniqueSuffix}`,
            objective: 'Verification',
            durationWeeks: 4,
            weeks: [
                {
                    weekNumber: 1,
                    days: [
                        {
                            title: 'Day A',
                            dayOfWeek: 1,
                            order: 1,
                            exercises: [
                                {
                                    exerciseId: ex1Id,
                                    sets: 3,
                                    reps: '10',
                                    suggestedLoad: '20kg',
                                    order: 1
                                },
                                {
                                    exerciseId: ex2Id,
                                    sets: 3,
                                    reps: '12',
                                    order: 2
                                }
                            ]
                        }
                    ]
                }
            ]
        }, { headers: { Authorization: `Bearer ${teacherToken}` } });
        planId = createPlanRes.data.id;
        console.log(`✅ Plan Created: ${planId}`);

        // 4. Assign Plan
        console.log('\nmb 4. Assign Plan...');
        const assignRes = await axios.post(`${BASE_URL}/plans/assign`, {
            planId: planId,
            studentId: studentId
        }, { headers: { Authorization: `Bearer ${teacherToken}` } });
        studentPlanId = assignRes.data.id;
        console.log(`✅ Plan Assigned: ${studentPlanId}`);

        // 5. Student Login
        console.log('\n🔐 5. Student Login...');
        const studentLoginRes = await axios.post(`${BASE_URL}/auth/login`, {
            email: `student_mvp_${uniqueSuffix}@test.com`,
            password: 'password123'
        });
        studentToken = studentLoginRes.data.access_token;
        console.log('✅ Student Logged In');

        // 6. Get My Plan
        console.log('\n📄 6. Student Gets Plan...');
        const myPlanRes = await axios.get(`${BASE_URL}/plans/student/my-plan`, {
            headers: { Authorization: `Bearer ${studentToken}` }
        });
        if (myPlanRes.data.id !== planId) throw new Error('Plan ID mismatch');
        console.log('✅ Student sees the correct plan');

        // 7. Start Execution (Day 1)
        console.log('\n▶️ 7. Start Execution...');
        const today = new Date().toISOString().split('T')[0];
        const startRes = await axios.post(`${BASE_URL}/executions/start`, {
            planId: planId,
            weekNumber: 1,
            dayOrder: 1,
            date: today
        }, { headers: { Authorization: `Bearer ${studentToken}` } });
        const executionId = startRes.data.id;
        const exercises = startRes.data.exercises;
        console.log(`✅ Execution Started: ${executionId} with ${exercises.length} exercises`);

        // 8. Complete Exercises
        console.log('\n💪 8. Complete Exercises...');
        for (const ex of exercises) {
            await axios.patch(`${BASE_URL}/executions/exercises/${ex.id}`, {
                isCompleted: true,
                setsDone: '3',
                repsDone: '10'
            }, { headers: { Authorization: `Bearer ${studentToken}` } });
        }
        console.log('✅ All exercises marked completed');

        // 9. Finish Workout
        console.log('\n🏁 9. Finish Workout...');
        await axios.patch(`${BASE_URL}/executions/${executionId}/complete`, {
            date: today
        }, { headers: { Authorization: `Bearer ${studentToken}` } });
        console.log('✅ Workout Finished');

        // 10. Verify Legacy Sync (Student Assignment Progress)
        console.log('\n🔄 10. Verify Legacy Sync...');
        const assignmentsRes = await axios.get(`${BASE_URL}/plans/student/history`, {
            headers: { Authorization: `Bearer ${studentToken}` }
        });
        const assignment = assignmentsRes.data.find((a: any) => a.id === studentPlanId);
        // We need to find the day ID from the plan structure to check the key
        const dayId = createPlanRes.data.weeks[0].days[0].id;

        if (assignment.progress.days[dayId]?.completed === true) {
            console.log('✅ Legacy Progress Sync Verified (Day marked as completed)');
        } else {
            console.error('❌ Legacy Progress Sync FAILED', JSON.stringify(assignment.progress, null, 2));
            throw new Error('Legacy Sync Failed');
        }

        console.log('\n✨✨ HAPPY PATH SUCCESSFUL ✨✨');

    } catch (e: any) {
        console.error('\n❌ VERIFICATION FAILED');
        if (e.response) {
            console.error(`Status: ${e.response.status}`);
            console.error('Data:', JSON.stringify(e.response.data, null, 2));
        } else {
            console.error(e); // Print full error
        }
        process.exit(1);
    }
}

run();
