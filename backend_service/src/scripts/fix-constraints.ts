
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { DataSource } from 'typeorm';

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const dataSource = app.get(DataSource);
    const queryRunner = dataSource.createQueryRunner();
    await queryRunner.connect();

    console.log('--- FIXING FOREIGN KEY CONSTRAINTS ---');

    // List of tables and columns that NEED Cascade/SetNull
    // Structure: [tableName, columnName, referencedTable, onDeleteAction]
    const tasks = [
        ['muscle_load_state', 'studentId', 'users', 'CASCADE'],
        ['muscle_load_state', 'muscleId', 'muscles', 'CASCADE'], // Optional
        ['muscle_load_ledger', 'studentId', 'users', 'CASCADE'],
        ['muscle_load_ledger', 'planExecutionId', 'plan_executions', 'CASCADE'],
        ['plan_executions', 'studentId', 'users', 'CASCADE'],
        ['plan_executions', 'planId', 'plans', 'CASCADE'],
        ['student_plans', 'studentId', 'users', 'CASCADE'],
        ['student_plans', 'planId', 'plans', 'CASCADE'],
        ['plan_exercises', 'exerciseId', 'exercises', 'CASCADE'],
        ['exercise_muscles', 'exerciseId', 'exercises', 'CASCADE'],
        ['exercise_executions', 'exerciseId', 'exercises', 'SET NULL'],
        ['exercise_executions', 'executionId', 'plan_executions', 'CASCADE'],

        // Ownership / Creator fields (SET NULL to preserve content)
        ['plans', 'teacherId', 'users', 'SET NULL'],
        ['exercises', 'createdById', 'users', 'SET NULL'],
        ['users', 'professorId', 'users', 'SET NULL'],
    ];

    for (const [table, column, refTable, action] of tasks) {
        console.log(`Checking ${table}.${column} -> ${refTable} (${action})...`);

        // Find the constraint name
        // Postgres query to find FK name
        const sql = `
        SELECT kcu.constraint_name
        FROM information_schema.key_column_usage kcu
        JOIN information_schema.referential_constraints rc 
             ON kcu.constraint_name = rc.constraint_name
        WHERE kcu.table_name = '${table}' 
          AND kcu.column_name = '${column}'
          AND kcu.table_schema = 'public';
    `;

        const result = await queryRunner.query(sql);

        if (result.length === 0) {
            console.log(`  [WARN] No constraint found for ${table}.${column}`);
            continue;
        }

        const constraintName = result[0].constraint_name;
        console.log(`  Found constraint: ${constraintName}`);

        // Drop and Recreate
        // We assume standard naming/refs logic matches current schema state
        try {
            await queryRunner.query(`ALTER TABLE "${table}" DROP CONSTRAINT "${constraintName}"`);
            console.log(`  Dropped ${constraintName}`);

            let addSql = `ALTER TABLE "${table}" ADD CONSTRAINT "${constraintName}" FOREIGN KEY ("${column}") REFERENCES "${refTable}"("id") ON DELETE ${action}`;
            await queryRunner.query(addSql);
            console.log(`  Recreated ${constraintName} with ON DELETE ${action}`);
        } catch (e) {
            console.error(`  [ERROR] Failed to fix ${constraintName}: ${e.message}`);
        }
    }

    await queryRunner.release();
    await app.close();
}

bootstrap();
