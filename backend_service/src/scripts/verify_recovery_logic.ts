
import '../polyfill';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { MuscleLoadService } from '../stats/muscle-load.service';
import { getRepositoryToken } from '@nestjs/typeorm';
import { MuscleLoadLedger } from '../stats/entities/muscle-load-ledger.entity';
import { TrainingSession } from '../plans/entities/training-session.entity';
import { UsersService } from '../users/users.service';
import { Muscle } from '../exercises/entities/muscle.entity';

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const muscleLoadService = app.get(MuscleLoadService);
    const usersService = app.get(UsersService);
    const ledgerRepo = app.get(getRepositoryToken(MuscleLoadLedger));
    const muscleRepo = app.get(getRepositoryToken(Muscle));
    const sessionRepo = app.get(getRepositoryToken(TrainingSession));

    console.log('🧪 Starting Recovery Logic Verification...');

    // 1. Get Test Student and Muscle
    // We try to find a student, if 'alumno@gym.com' fails we try 'admin@gym.com' or just the first user.
    let student = await usersService.findOneByEmail('alumno@gym.com');
    if (!student) throw new Error("Student 'alumno@gym.com' not found");

    const muscles = await muscleRepo.find({ take: 1 });
    if (muscles.length === 0) throw new Error('No muscles found in DB');
    const testMuscle = muscles[0];

    console.log(`👤 Student: ${student.email}`);
    console.log(`💪 Muscle: ${testMuscle.name} (ID: ${testMuscle.id})`);

    // 2. Create a Dummy Training Session to avoid FK errors
    // distinct ID not needed if we rely on generated UUID
    const dummyRef = sessionRepo.create({
        student: { id: student.id } as any,
        date: new Date().toISOString().split('T')[0],
        source: 'FREE',
        status: 'COMPLETED' as any // Enum casting
    });
    const dummySession = await sessionRepo.save(dummyRef) as any;
    console.log(`📝 Created Dummy Session: ${dummySession.id}`);

    // 3. Clear previous ledger for this muscle/student to have a clean slate
    await ledgerRepo.delete({
        student: { id: student.id },
        muscle: { id: testMuscle.id }
    });
    console.log(`🧹 Cleared ledger for ${testMuscle.name}`);

    // 4. Insert specific history scenarios
    // Note: We use the SAME session ID for both just to satisfy FK. 
    // In reality, they would be different sessions, but for Load Service logic, 
    // it cares about ledger dates, not session IDs (mostly). 
    // Actually, distinct dates matter most.

    // Scenario A: OLD Workout (14 days ago) - High Load
    const oldDate = new Date();
    oldDate.setDate(oldDate.getDate() - 14);
    const oldDateStr = oldDate.toISOString().split('T')[0];

    const oldEntry = ledgerRepo.create({
        student: { id: student.id } as any,
        muscle: { id: testMuscle.id } as any,
        date: oldDateStr,
        deltaLoad: 80, // High load
        session: { id: dummySession.id } as any
    });
    await ledgerRepo.save(oldEntry);
    console.log(`📅 Inserted OLD workout: Date=${oldDateStr}, Load=80`);


    // Scenario B: RECENT Workout (Today) - Small Load
    const todayStr = new Date().toISOString().split('T')[0];
    const newEntry = ledgerRepo.create({
        student: { id: student.id } as any,
        muscle: { id: testMuscle.id } as any,
        date: todayStr,
        deltaLoad: 15, // Small load
        session: { id: dummySession.id } as any
    });
    await ledgerRepo.save(newEntry);
    console.log(`📅 Inserted NEW workout: Date=${todayStr}, Load=15`);


    // 5. Run Calculation
    console.log('🔄 Running getLoadsForStudent...');
    const results = await muscleLoadService.getLoadsForStudent(student.id) as any[];

    // 6. Verify Results
    const muscleResult = results.find((r: any) => r.muscleId === testMuscle.id);

    console.log('📊 Result for Test Muscle:', muscleResult);

    let success = false;
    // Expectation: 
    // - Old 80 load -> Recovered to 0 over 14 days.
    // - New 15 load -> Added today.
    // - Total = 15.
    if (muscleResult && Math.abs(muscleResult.load - 15) < 0.1) {
        console.log('✅ SUCCESS: Logic correctly recovered old load and kept new load.');
        success = true;
    } else {
        const load = muscleResult ? muscleResult.load : 'undefined';
        console.error(`❌ FAILURE: Expected load 15, got ${load}.`);
        if (typeof load === 'number' && load > 15) {
            console.error('   -> Likely caused by OLD load not being recovered.');
        }
    }

    // Cleanup
    await sessionRepo.remove(dummySession);
    console.log('🧹 Cleanup: Session removed');

    await app.close();

    if (!success) process.exit(1);
}

bootstrap();
