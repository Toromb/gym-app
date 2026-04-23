import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { StudentPlan } from '../plans/entities/student-plan.entity';
import { Repository } from 'typeorm';
import { getRepositoryToken } from '@nestjs/typeorm';

async function bootstrap() {
    const app = await NestFactory.create(AppModule);
    const studentPlanRepo = app.get<Repository<StudentPlan>>(getRepositoryToken(StudentPlan));

    console.log('--- STARTING CONSERVATIVE CLEANUP OF LEGACY ASSIGNMENTS ---');

    const legacyPlans = await studentPlanRepo.find({
        relations: ['student', 'assignedPlan', 'plan']
    });

    console.log(`Found ${legacyPlans.length} total assignments in DB.`);

    const grouped = new Map<string, StudentPlan[]>();

    // Group by student + originalPlanId
    for (const sp of legacyPlans) {
        if (!sp.student) continue;
        const studentId = sp.student.id;
        const originalPlanId = sp.assignedPlan?.originalPlanId || sp.plan?.id;
        if (!originalPlanId) {
            console.log(`[WARN] StudentPlan ${sp.id} has no originalPlanId or plan reference. Ignoring.`);
            continue;
        }

        const key = `${studentId}_${originalPlanId}`;
        if (!grouped.has(key)) {
            grouped.set(key, []);
        }
        grouped.get(key)!.push(sp);
    }

    let deletedCount = 0;
    let ambiguousCount = 0;

    for (const [key, group] of grouped.entries()) {
        if (group.length <= 1) {
            continue; // No duplicates, safe.
        }

        // Sort by assignedAt DESC (newest first)
        group.sort((a, b) => {
            const timeA = new Date(a.assignedAt).getTime() || 0;
            const timeB = new Date(b.assignedAt).getTime() || 0;
            if (timeB !== timeA) return timeB - timeA;
            return b.id > a.id ? 1 : -1; 
        });

        const activePlans = group.filter(sp => sp.isActive);
        
        if (activePlans.length > 1) {
            console.log(`[AMBIGUITY] Group ${key} has ${activePlans.length} ACTIVE assignments! Skipping deletion to avoid data loss.`);
            ambiguousCount++;
            continue;
        }

        // The survivor is the ACTIVE one, or if none are active, the NEWEST pending/reusable one.
        const survivor = activePlans.length === 1 ? activePlans[0] : group[0];
        
        console.log(`\n[GROUP] ${key} has ${group.length} assignments. Keeping survivor ${survivor.id} (isActive: ${survivor.isActive})`);

        for (const sp of group) {
            if (sp.id !== survivor.id) {
                console.log(`   -> [DELETE] Removing duplicate ${sp.id} (isActive: ${sp.isActive}, assignedAt: ${sp.assignedAt}). Safe: completed plans stay intact.`);
                await studentPlanRepo.remove(sp);
                deletedCount++;
            }
        }
    }

    console.log(`\n--- CLEANUP SUMMARY ---`);
    console.log(`Deleted ${deletedCount} duplicate StudentPlan records.`);
    console.log(`Skipped ${ambiguousCount} groups due to ambiguity (multiple active).`);

    await app.close();
}
bootstrap();
