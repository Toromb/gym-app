
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { UsersService } from '../src/users/users.service';
import { GymsService } from '../src/gyms/gyms.service';
import { PlansService } from '../src/plans/plans.service';
import { ExecutionsService } from '../src/plans/executions.service';
import { UserRole } from '../src/users/entities/user.entity';
import { getRepositoryToken } from '@nestjs/typeorm';
import { StudentPlan } from '../src/plans/entities/student-plan.entity';
import { Gym } from '../src/gyms/entities/gym.entity';

async function bootstrap() {
    const app = await NestFactory.create(AppModule);
    await app.init();

    const usersService = app.get(UsersService);
    const gymsService = app.get(GymsService);
    const plansService = app.get(PlansService);
    const executionsService = app.get(ExecutionsService);
    const studentPlanRepo = app.get(getRepositoryToken(StudentPlan));
    const gymRepo = app.get(getRepositoryToken(Gym));

    console.log('--- STARTING LEGACY SYNC VERIFICATION ---');

    // 1. Setup Data with Unique ID
    const uniqueId = Date.now().toString() + Math.floor(Math.random() * 100000);

    // Find existing gym or create
    let gym = await gymRepo.findOne({ where: {} });
    if (!gym) {
        gym = await gymsService.create({ name: `Gym ${uniqueId}` });
    } else {
        console.log(`Using existing gym: ${gym.id}`);
    }

    const student = await usersService.create({
        email: `student_${uniqueId}@test.com`,
        password: 'password',
        firstName: 'Student',
        lastName: 'Test',
        role: UserRole.ALUMNO,
        gymId: gym.id
    });

    const plan = await plansService.create({
        name: `Plan ${uniqueId}`,
        gymId: gym.id,
        creatorId: student.id,
        weeks: [
            {
                name: 'Week 1',
                weekNumber: 1,
                days: [
                    {
                        dayOfWeek: 1,
                        order: 1,
                        title: 'Day 1',
                        exercises: []
                    }
                ]
            }
        ]
    });

    if (!plan.weeks || !plan.weeks[0] || !plan.weeks[0].days || !plan.weeks[0].days[0]) {
        console.error('Plan structure invalid');
        process.exit(1);
    }

    const dayId = plan.weeks[0].days[0].id;
    console.log(`Plan Created. Day 1 ID: ${dayId}`);

    // 2. Assign Plan
    await plansService.assignPlan(plan.id, student.id);
    console.log('Plan Assigned');

    // 3. Start Execution
    const date = '2025-01-01';
    const execution = await executionsService.startExecution(
        student.id,
        plan.id,
        1, // Week 1
        1, // Day 1
        date
    );
    console.log('Execution Started');

    // 4. Complete Execution
    console.log('Completing Execution...');
    await executionsService.completeExecution(execution.id, student.id, date);
    console.log('Execution Completed');

    // 5. Verify StudentPlan Progress
    const studentPlan = await studentPlanRepo.findOne({
        where: {
            student: { id: student.id },
            plan: { id: plan.id }
        }
    });

    if (!studentPlan) {
        console.error('FAILED: StudentPlan not found');
        process.exit(1);
    }

    console.log('Checking Progress JSON:', JSON.stringify(studentPlan.progress, null, 2));

    const progress = studentPlan.progress;
    if (progress && progress.days && progress.days[dayId] && progress.days[dayId].completed === true) {
        console.log('SUCCESS: Progress synced correctly to legacy field.');
    } else {
        console.error('FAIL: Progress NOT synced to legacy field.');
        console.error(`Expected key [${dayId}] to exist and have completed: true`);
        process.exit(1);
    }

    await app.close();
    process.exit(0);
}

bootstrap().catch(err => {
    console.error(err);
    process.exit(1);
});
