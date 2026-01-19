import '../polyfill';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { DataSource } from 'typeorm';
import { MuscleLoadState } from '../stats/entities/muscle-load-state.entity';
import { MuscleLoadLedger } from '../stats/entities/muscle-load-ledger.entity';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const dataSource = app.get(DataSource);

  console.log('⏳ Simulating Time Travel (Backdating MuscleLoadState AND Ledger)...');

  const statsRepo = dataSource.getRepository(MuscleLoadState);
  const ledgerRepo = dataSource.getRepository(MuscleLoadLedger);

  // 1. Update State (Snapshot of "past" knowledge)
  const resultState = await statsRepo.query(`
    UPDATE muscle_load_state 
    SET "lastComputedDate" = "lastComputedDate" - INTERVAL '5 days'
  `);
  console.log('✅ Updated muscle_load_state records:', resultState);

  // 2. Update Ledger (Actual workout dates)
  // We must move the workouts back too, otherwise the "new" workout (today's) will look like 
  // a FRESH workout that happened 5 days *after* the snapshot (which we just moved back).
  const resultLedger = await ledgerRepo.query(`
    UPDATE muscle_load_ledger
    SET "date" = "date" - INTERVAL '5 days'
  `);
  console.log('✅ Updated muscle_load_ledger records:', resultLedger);

  console.log('🕒 You can now refresh the app to verify recovery.');

  await app.close();
}

bootstrap();
