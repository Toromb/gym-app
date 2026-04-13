import '../polyfill';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { DataSource } from 'typeorm';
import { Plan } from '../plans/entities/plan.entity';
import { StudentPlan } from '../plans/entities/student-plan.entity';
import { AssignedPlan } from '../plans/entities/assigned-plan.entity';
import { AssignedPlanWeek } from '../plans/entities/assigned-plan-week.entity';
import { AssignedPlanDay } from '../plans/entities/assigned-plan-day.entity';
import { AssignedPlanExercise } from '../plans/entities/assigned-plan-exercise.entity';

async function migrate() {
  console.log('🚀 Starting Phase 1 Migration: Assigned Plans Deep Cloning...');

  const app = await NestFactory.createApplicationContext(AppModule);
  const dataSource = app.get(DataSource);

  const studentPlanRepo = dataSource.getRepository(StudentPlan);
  const planRepo = dataSource.getRepository(Plan);

  console.log('🔍 Identifying assignments pending migration...');

  // 1. Fetch only assignments without an assignedPlanId
  // Because TypeOrm sync might not have populated it, explicitly filter WHERE assignedPlanId IS NULL.
  // Note: we can use a raw inner check or just find with relations.
  const assignmentsQuery = await studentPlanRepo
    .createQueryBuilder('sp')
    .leftJoinAndSelect('sp.plan', 'plan')
    .leftJoinAndSelect('sp.student', 'student')
    .where('sp."assignedPlanId" IS NULL') // Use raw column name for safety
    .getMany();

  console.log(`📦 Found ${assignmentsQuery.length} assignments needing deep cloning.`);

  let successCount = 0;
  let skippedCount = 0;
  let errorCount = 0;

  for (const sp of assignmentsQuery) {
    if (!sp.plan) {
      console.log(`⚠️ Skipped Assignment ${sp.id} (No legacy plan reference found)`);
      skippedCount++;
      continue;
    }

    try {
      await dataSource.transaction(async (transactionalEntityManager) => {
        // Double check idempotency in transaction
        const currentSp = await transactionalEntityManager.findOne(StudentPlan, {
          where: { id: sp.id },
          relations: ['assignedPlan'],
        });

        if (!currentSp) return;

        if (currentSp.assignedPlan) {
          console.log(`⏩ Skipped Assignment ${sp.id} (Already has assignedPlan)`);
          skippedCount++;
          return;
        }

        console.log(`🔄 Migrating Plan '${sp.plan.name}' for Student ${sp.student?.id}...`);

        // Load full plan structure
        const fullPlan = await transactionalEntityManager.findOne(Plan, {
          where: { id: sp.plan.id },
          relations: [
            'weeks',
            'weeks.days',
            'weeks.days.exercises',
            'weeks.days.exercises.exercise',
            'weeks.days.exercises.equipments',
            'teacher'
          ],
        });

        if (!fullPlan) {
           throw new Error(`Legacy Plan ${sp.plan.id} not found in DB`);
        }

        // Build AssignedPlan Deep Clone
        const assignedPlan = new AssignedPlan();
        assignedPlan.originalPlanId = fullPlan.id;
        assignedPlan.originalPlanName = fullPlan.name;
        assignedPlan.assignedAt = new Date(sp.assignedAt || new Date().toISOString());
        assignedPlan.assignedByUserId = fullPlan.teacher?.id || null;
        assignedPlan.name = fullPlan.name;
        assignedPlan.description = fullPlan.description;
        assignedPlan.objective = fullPlan.objective;
        assignedPlan.generalNotes = fullPlan.generalNotes;
        assignedPlan.durationWeeks = fullPlan.durationWeeks;

        assignedPlan.weeks = (fullPlan.weeks || []).map(w => {
          const assignedWeek = new AssignedPlanWeek();
          assignedWeek.weekNumber = w.weekNumber;
          assignedWeek.days = (w.days || []).map(d => {
            const assignedDay = new AssignedPlanDay();
            assignedDay.title = d.title;
            assignedDay.dayOfWeek = d.dayOfWeek;
            assignedDay.order = d.order;
            assignedDay.trainingIntent = d.trainingIntent;
            assignedDay.dayNotes = d.dayNotes;
            assignedDay.exercises = (d.exercises || []).map(e => {
              const assignedEx = new AssignedPlanExercise();
              assignedEx.exercise = e.exercise;
              assignedEx.sets = e.sets;
              assignedEx.reps = e.reps;
              assignedEx.suggestedLoad = e.suggestedLoad;
              assignedEx.rest = e.rest;
              assignedEx.notes = e.notes;
              assignedEx.videoUrl = e.videoUrl;
              assignedEx.targetTime = e.targetTime;
              assignedEx.targetDistance = e.targetDistance;
              assignedEx.order = e.order;
              assignedEx.equipments = e.equipments || [];
              return assignedEx;
            });
            return assignedDay;
          });
          return assignedWeek;
        });

        const savedAssignedPlan = await transactionalEntityManager.save(AssignedPlan, assignedPlan);
        
        // Link to existing Student Plan
        currentSp.assignedPlan = savedAssignedPlan;
        await transactionalEntityManager.save(StudentPlan, currentSp);

        successCount++;
      });
    } catch (err) {
      console.error(`❌ Error migrating assignment ${sp.id}:`, err.message);
      errorCount++;
    }
  }

  console.log('✅ Phase 1 Migration Script Completed.');
  console.log(`📊 SUCCESS: ${successCount} | SKIPPED: ${skippedCount} | ERRORS: ${errorCount}`);

  await app.close();
}

migrate();
