import '../polyfill';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { ExecutionsService } from '../plans/executions.service';
import { MuscleLoadService } from '../stats/muscle-load.service';
import { DataSource } from 'typeorm';
import { User, UserRole } from '../users/entities/user.entity';
import * as crypto from 'crypto';

async function verifyLogic() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const executionsService = app.get(ExecutionsService);
    const muscleLoadService = app.get(MuscleLoadService);
    const dataSource = app.get(DataSource);

    console.log('🚀 Starting Verification...');

    // 1. Get a Student (first one found)
    const student = await dataSource.getRepository(User).findOne({ where: { role: UserRole.ALUMNO } });
    if (!student) {
        console.error('❌ No student found. Please seed users first.');
        return;
    }
    console.log(`👤 Using Student: ${student.email}`);

    // 2. Get State BEFORE
    const initialLoad: any = await muscleLoadService.getLoadsForStudent(student.id);
    console.log('📊 Initial Load Summary:', JSON.stringify(initialLoad.muscles.slice(0, 3))); // Show top 3

    // 3. Simulate Completing an Execution
    console.log('🧪 Testing Calculation Logic directly...');

    // Mock Execution with Exercises
    // Let's find "Banca Plana" and "Sentadilla"
    const exercises = await dataSource.query(`SELECT id, name FROM exercises WHERE name IN ('Banca Plana', 'Sentadilla')`);
    if (exercises.length === 0) {
        console.log('⚠️ Exercises not found. Skipping logic test.');
    } else {
        console.log(`🏋️ Found exercises: ${exercises.map((e: any) => e.name).join(', ')}`);

        // Find a Plan
        const plan = await dataSource.query(`SELECT id FROM plans LIMIT 1`);
        if (plan.length === 0) {
            console.log('⚠️ No Plans found. Skipping Ledger test (FK constraint).');
            await app.close();
            return;
        }
        const planId = plan[0].id;

        // Create Dummy Execution in DB
        const executionId = crypto.randomUUID();
        await dataSource.query(`
        INSERT INTO plan_executions (id, "studentId", "planId", "date", "dayKey", "weekNumber", "dayOrder", "status", "createdAt", "updatedAt")
        VALUES ($1, $2, $3, '2025-01-01', 'TEST', 1, 1, 'COMPLETED', NOW(), NOW())
    `, [executionId, student.id, planId]);

        console.log(`✅ Created Mock Execution: ${executionId}`);

        const mockExecution: any = {
            id: executionId,
            student: { id: student.id },
            date: '2025-01-01',
            status: 'COMPLETED',
            exercises: exercises.map((ex: any) => ({
                id: 'ex-exec-' + ex.id,
                isCompleted: true,
                exercise: { id: ex.id }, // Relation needed
                planExerciseId: 'mock'
            }))
        };

        await muscleLoadService.syncExecutionLoad(mockExecution);
        console.log('✅ Sync executed.');

        // 4. Verify Ledger
        const ledger = await dataSource.query(`SELECT * FROM muscle_load_ledger WHERE "planExecutionId" = '${mockExecution.id}'`);
        console.log(`📒 Ledger Entries Created: ${ledger.length}`);
        if (ledger.length > 0) {
            console.log('Sample Entry:', ledger[0]);
        } else {
            console.error('❌ Expected ledger entries!');
        }

        // 5. Verify State (Recalculate)
        // We set date to 2025-01-02 (day after)
        const afterLoad: any = await muscleLoadService.getLoadsForStudent(student.id, '2025-01-02');
        // We expect some load on Chest/Legs.
        const chest = afterLoad.muscles.find((m: any) => m.name === 'Pectorales'); // Check spelling in seed?
        const quads = afterLoad.muscles.find((m: any) => m.name === 'Cuádriceps');

        console.log('📊 Load After (2025-01-02):');
        console.log('  Chest Load:', chest ? chest.load : 'N/A');
        console.log('  Quads Load:', quads ? quads.load : 'N/A');
    }

    await app.close();
}

verifyLogic();
