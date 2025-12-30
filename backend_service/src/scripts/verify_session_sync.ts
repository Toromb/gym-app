
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { getRepositoryToken } from '@nestjs/typeorm';
import { User, UserRole } from '../users/entities/user.entity';
import { Gym } from '../gyms/entities/gym.entity';
import { Plan, TrainingIntent, PlanDay, PlanExercise } from '../plans/entities/plan.entity';
import { Exercise } from '../exercises/entities/exercise.entity';
import { PlanWeek } from '../plans/entities/plan-week.entity';
import { StudentPlan } from '../plans/entities/student-plan.entity';
import { PlansService } from '../plans/plans.service';
import { TrainingSessionsService } from '../plans/training-sessions.service';
import { TrainingSession } from '../plans/entities/training-session.entity';
import * as bcrypt from 'bcrypt';

const TIMESTAMP = Date.now();
const log = (msg: string, type: 'INFO' | 'SUCCESS' | 'ERROR' = 'INFO') => {
    const icon = type === 'SUCCESS' ? '✅' : type === 'ERROR' ? '❌' : 'ℹ️';
    console.log(`${icon} [${type}] ${msg}`);
};

async function runTest() {
    log('Starting Session Sync Verification...');
    const app = await NestFactory.createApplicationContext(AppModule);

    try {
        const plansService = app.get(PlansService);
        const sessionService = app.get(TrainingSessionsService);
        const gymRepo = app.get(getRepositoryToken(Gym));
        const userRepo = app.get(getRepositoryToken(User));
        const planRepo = app.get(getRepositoryToken(Plan));
        const studentPlanRepo = app.get(getRepositoryToken(StudentPlan));
        const exerciseRepo = app.get(getRepositoryToken(Exercise));

        // 1. Setup Data
        const gym = await gymRepo.save(gymRepo.create({ name: `Sync Gym ${TIMESTAMP}`, businessName: `Sync Inc ${TIMESTAMP}`, address: 'A' }));
        const prof = await userRepo.save(userRepo.create({ email: `profSync_${TIMESTAMP}@t.com`, passwordHash: 'hash', role: UserRole.PROFE, gym, firstName: 'P', lastName: 'T' }));
        const std = await userRepo.save(userRepo.create({ email: `stdSync_${TIMESTAMP}@t.com`, passwordHash: 'hash', role: UserRole.ALUMNO, gym, professor: prof, firstName: 'S', lastName: 'T' }));
        const exercise = await exerciseRepo.save({ name: `Sync Ex ${TIMESTAMP}`, muscleGroup: 'Chest' });

        // 2. Create Initial Plan (3 Sets)
        // Manually build entity structure
        const pe = new PlanExercise();
        pe.sets = 3;
        pe.reps = '10';
        pe.order = 1;
        pe.exercise = exercise;

        const pd = new PlanDay();
        pd.dayOfWeek = 1;
        pd.order = 1;
        pd.exercises = [pe];

        const pw = new PlanWeek();
        pw.weekNumber = 1;
        pw.days = [pd];

        const plan = new Plan();
        plan.name = 'Original Plan';
        plan.weeks = [pw];
        plan.teacher = prof;
        plan.durationWeeks = 4;

        const savedPlan = await planRepo.save(plan);
        // Reload to get IDs
        const originalPlan = await plansService.findOne(savedPlan.id);
        if (!originalPlan) throw new Error('Plan not saved');

        const weekId = originalPlan.weeks[0].id;
        const dayId = originalPlan.weeks[0].days[0].id;
        const exDetailId = originalPlan.weeks[0].days[0].exercises[0].id;

        // ASSIGN PLAN
        await plansService.assignPlan(plan.id, std.id, prof.id);

        // 3. Start Session (Creates Snapshot with 3 Sets)
        // SIMULATE PROFESSOR PREVIEW (Student = Prof)
        const session = await sessionService.startSession(prof.id, plan.id, 1, 1);
        log(`Session Started for PROFESSOR. Snapshot Sets: ${session.exercises[0].targetSetsSnapshot}`, 'INFO');

        if (session.exercises[0].targetSetsSnapshot !== 3) throw new Error('Initial snapshot failed');

        // 4. Update Plan (Change Sets to 5, Keep IDs)
        const updateDto: any = {
            name: 'Updated Plan',
            weeks: [{
                id: weekId,
                weekNumber: 1,
                days: [{
                    id: dayId,
                    dayOfWeek: 1,
                    order: 1,
                    exercises: [{
                        id: exDetailId, // PRESERVE ID
                        exerciseId: exercise.id,
                        sets: 5, // CHANGED VALUE
                        reps: '10',
                        order: 1
                    }]
                }]
            }]
        };

        log('Updating Plan to 5 Sets...', 'INFO');
        await plansService.update(plan.id, updateDto, prof);

        // 5. Reload Session (Should Trigger Sync)
        log('Reloading Session to Trigger Sync...', 'INFO');
        // We use findOne or startSession. sessionService.findOne calls _syncSnapshots
        const resultSession = await sessionService.findOne(session.id);
        if (!resultSession) throw new Error('Session not found');

        const newSets = resultSession.exercises[0].targetSetsSnapshot;
        log(`Reloaded Session Snapshot Sets: ${newSets}`, 'INFO');

        const planReload = await plansService.findOne(plan.id);
        if (!planReload) throw new Error('Reloaded plan not found');
        log(`Plan Sets in DB (findOne): ${planReload.weeks[0]?.days[0]?.exercises[0]?.sets}`, 'INFO');

        if (newSets === 5) {
            log('Session Sync SUCCESS! Snapshot updated to 5. ✅', 'SUCCESS');
        } else {
            throw new Error(`Session Sync FAILED. Expected 5, got ${newSets}`);
        }

        // 6. Test Structural Sync (Add Exercise)
        log('--- Testing Structural Sync (Add Exercise) ---', 'INFO');

        // Add new exercise to plan
        const newExercise = await exerciseRepo.save(exerciseRepo.create({
            name: 'New Added Exercise',
            description: 'Test Structural Sync',
            muscles: [],
            equipments: [],
            videoUrl: 'http://test.com',
            difficultyLevel: 'Beginner',
            movementPattern: 'Test',
        }));

        const reloadedPlanForAdd = await plansService.findOne(plan.id);
        if (!reloadedPlanForAdd) throw new Error('Plan not found for add');

        // Construct DTO
        const updateDtoForAdd: any = {
            name: reloadedPlanForAdd.name,
            weeks: reloadedPlanForAdd.weeks.map(w => ({
                id: w.id,
                weekNumber: w.weekNumber,
                days: w.days.map(d => ({
                    id: d.id,
                    dayOfWeek: d.dayOfWeek,
                    order: d.order,
                    exercises: d.exercises.map(e => ({
                        id: e.id,
                        exerciseId: e.exercise.id,
                        sets: e.sets,
                        reps: e.reps,
                        suggestedLoad: e.suggestedLoad,
                        order: e.order
                    }))
                }))
            }))
        };

        // Add new exercise to DTO
        // Make sure to convert sets to number and have all fields
        updateDtoForAdd.weeks[0].days[0].exercises.push({
            exerciseId: newExercise.id,
            sets: 4,
            reps: '10',
            suggestedLoad: '10kg',
            order: 2
        });

        await plansService.update(plan.id, updateDtoForAdd, prof);
        log('Plan Updated with NEW Exercise.', 'INFO');

        // Sync Session
        const sessionAfterAdd = await sessionService.startSession(prof.id, plan.id, 1, 1);

        log(`Session Reloaded after Add. Exercise Count: ${sessionAfterAdd.exercises.length}`, 'INFO');
        sessionAfterAdd.exercises.forEach(e => log(` - Found: ${e.exerciseNameSnapshot} (ID: ${e.id})`, 'INFO'));

        const addedEx = sessionAfterAdd.exercises.find(e => e.exerciseNameSnapshot === 'New Added Exercise');

        if (addedEx) {
            log('Structural Sync SUCCESS! New Exercise found in session. ✅', 'SUCCESS');
        } else {
            throw new Error('Structural Sync FAILED. New Exercise NOT found in session.');
        }

    } catch (e) {
        log(e.message, 'ERROR');
        console.error(e);
        process.exit(1);
    } finally {
        await app.close();
    }
}

runTest();
