import '../polyfill';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { DataSource } from 'typeorm';

async function verify() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const dataSource = app.get(DataSource);

  const stats = {
    assignedPlans: await dataSource.query('SELECT COUNT(*) FROM assigned_plans'),
    weeks: await dataSource.query('SELECT COUNT(*) FROM assigned_plan_weeks'),
    days: await dataSource.query('SELECT COUNT(*) FROM assigned_plan_days'),
    exercises: await dataSource.query('SELECT COUNT(*) FROM assigned_plan_exercises'),
  };

  console.log('--- TABLES COUNT ---');
  console.log(stats);

  const sp = await dataSource.query(`
    SELECT "studentId", "assignedPlanId", "planId" 
    FROM student_plans 
    WHERE "assignedPlanId" IS NOT NULL LIMIT 5
  `);
  console.log('--- STUDENT PLANS SAMPLE ---');
  console.log(sp);

  const ap = await dataSource.query(`
    SELECT id, name, "originalPlanId" 
    FROM assigned_plans LIMIT 5
  `);
  console.log('--- ASSIGNED PLANS SAMPLE ---');
  console.log(ap);

  await app.close();
}

verify();
