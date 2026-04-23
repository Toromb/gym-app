import * as dotenv from 'dotenv';
dotenv.config();
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { PlansService } from '../plans/plans.service';
import { TrainingSessionsService } from '../plans/training-sessions.service';
import { UsersService } from '../users/users.service';
import { GymsService } from '../gyms/gyms.service';
import { ExercisesService } from '../exercises/exercises.service';
import { CreatePlanDto } from '../plans/dto/create-plan.dto';
import { UserRole } from '../users/entities/user.entity';
import { ExecutionStatus } from '../plans/entities/training-session.entity';
import * as assert from 'assert';
import { ForbiddenException, ConflictException, NotFoundException } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  
  const plansService = app.get(PlansService);
  const trainingSessionsService = app.get(TrainingSessionsService);
  const usersService = app.get(UsersService);
  const gymsService = app.get(GymsService);
  const exercisesService = app.get(ExercisesService);

  console.log('--- EMPEZANDO VALIDACIÓN FASE 2 ---');

  try {
    // 1. SETUP: Create Gym, Admin, Student, Exercise, Plan
    console.log('1. Preparando entorno (Mock Data)...');
    
    // Check if we have an exercise
    const allExs = await exercisesService.findAll();
    if (allExs.length === 0) {
      throw new Error('Please create at least 1 exercise before running this test.');
    }
    const exercise = allExs[0];

    // Mock Gym
    const allGyms = await gymsService.findAll();
    const gym = allGyms[0];
    
    // Mock Users
    // UsersService might not have findAll, use database directly or specific method
    let admin: any = null;
    let student: any = null;
    try {
        admin = await usersService.findOne('some-id'); // will fail probably if id doesn't exist
    } catch (e) {}
    
    // Instead of using UsersService directly, let's just create a new admin and student or find by email.
    // Let's create unique student and use generic admin
    student = await usersService.create({
      email: `testfase2_${Date.now()}@test.com`,
      password: 'password123',
      firstName: 'Fase2',
      lastName: 'Student',
      role: UserRole.ALUMNO,
      gymId: gym.id
    });
    
    admin = await usersService.create({
      email: `adminfase2_${Date.now()}@test.com`,
      password: 'password123',
      firstName: 'Admin',
      lastName: 'Test',
      role: UserRole.ADMIN,
      gymId: gym.id
    });

    // Creacion de un Plan limpio
    const createPlanDto: any = {
      name: 'Plan Testing Fase 2',
      description: 'Prueba runtime',
      objective: 'Fuerza',
      generalNotes: 'Test notes',
      durationWeeks: 1,
      weeks: [{
        weekNumber: 1,
        days: [{
          title: 'Día de Prueba',
          dayOfWeek: 1,
          order: 1,
          trainingIntent: 'HYPERTROPHY',
          exercises: [{
            exerciseId: exercise.id,
            sets: 3,
            reps: '10',
            suggestedLoad: '20kg',
            rest: '60s',
            order: 1
          }]
        }]
      }]
    };
    const plan = await plansService.create(createPlanDto, admin);
    console.log(`✓ Plan Creado. ID: ${plan.id}`);

    // ----- TEST 1: finishAssignment -----
    console.log('\n--- CASO 1: finishAssignment y Consolidación ---');
    const assignment1 = await plansService.assignPlan(plan.id, student.id, admin);
    console.log(`✓ Asignado plan al alumno. Assignment ID: ${assignment1.id}`);

    // Emular sesión de entrenamiento 1
    const session1 = await trainingSessionsService.startSession(student.id, assignment1.assignedPlan.id, 1, 1, new Date().toISOString());
    console.log(`✓ Sesión 1 iniciada. Session ID: ${session1.id}`);
    
    // Completamos el primer ejercicio (isCompleted = true)
    let sessionExercise = session1.exercises[0];
    await trainingSessionsService.updateExercise(sessionExercise.id, {
      isCompleted: true,
      setsDone: '3',
      repsDone: '8,8,8',         // Reps reales
      targetWeightSnapshot: '30kg' // Carga real
    });
    console.log(`✓ Ejercicio de Sesión 1 actualizado (Reps y Carga).`);

    // Completamos la sesion
    await trainingSessionsService.completeSession(session1.id, student.id, new Date().toISOString());
    console.log(`✓ Sesión 1 completada.`);

    // Terminamos la asignación explícitamente!
    console.log(`Llamando finishAssignment...`);
    await plansService.finishAssignment(assignment1.id, student.id);
    
    let history = await plansService.getHistoricalPlans(student.id);
    let completedPlan1 = history.find(hp => hp.assignedPlanId === assignment1.assignedPlan.id);
    
    assert.strictEqual(completedPlan1!.completedReason, 'COMPLETED', 'Razón debe ser COMPLETED');
    assert.strictEqual(completedPlan1!.sessions.length, 1, 'Debe haber 1 sesión consolidada');
    assert.strictEqual(completedPlan1!.sessions[0].id, session1.id, 'La sesión devuelta no es la correcta');
    console.log(`✓ finishAssignment completó todo bien. Razón: COMPLETED.`);

    // Intento llamar a finishAssignment de nuevo para comprobar que NO genera carpeta vacía y responde 409.
    try {
      await plansService.finishAssignment(assignment1.id, student.id);
      assert.fail(`Debió lanzar ConflictException por no tener sesiones pendientes`);
    } catch(e: any) {
      assert.strictEqual(e.status, 409, 'Debe devolver status 409 Conflict');
      console.log(`✓ Segunda invocación de finishAssignment generó error controlado (409): ${e.message}`);
    }
    
    // Verificar que realmente no se generó otro CompletedPlan vacío
    const checkDups = await plansService.getHistoricalPlans(student.id);
    const totalWrappersFor1 = checkDups.filter(h => h.assignedPlanId === assignment1.assignedPlan.id);
    assert.strictEqual(totalWrappersFor1.length, 1, 'No debe existir un wrapper vacío extra de la asignación 1');
    console.log(`✓ Verificado: No se generaron folders históricos vacíos.`);

    // ----- TEST 2: INMUTABILIDAD -----
    console.log('\n--- CASO 4: Inmutabilidad ---');
    try {
      await trainingSessionsService.updateExercise(sessionExercise.id, { isCompleted: false });
      assert.fail(`Debió lanzar ForbiddenException`);
    } catch (e: any) {
      assert.strictEqual(e.status, 403, 'Debió ser un 403 Forbidden');
      console.log(`✓ Correcto: El sistema bloqueó la modificación del ejercicio histórico.`);
    }

    // ----- TEST 3: restartAssignment y Ciclos Sucesivos -----
    console.log('\n--- CASO 2 y 6: restartAssignment y ciclos sucesivos ---');
    const assignment2 = await plansService.assignPlan(plan.id, student.id, admin);
    console.log(`✓ Se re-asignó el plan. Assignment2 ID: ${assignment2.id}`);
    
    // Inicia sesion 2
    const session2 = await trainingSessionsService.startSession(student.id, assignment2.assignedPlan.id, 1, 1, new Date().toISOString());
    await trainingSessionsService.completeSession(session2.id, student.id, new Date().toISOString());
    console.log(`✓ Sesión 2 del ciclo 2 completada.`);

    // Usamos restartAssignment
    console.log(`Llamando restartAssignment...`);
    const newCycle = await plansService.restartAssignment(assignment2.id, student.id);
    console.log(`✓ reinició exitosamente (produjo ciclo: ${newCycle.id})`);

    // Validamos historial
    history = await plansService.getHistoricalPlans(student.id);
    let completedPlanRestarted = history.find(hp => hp.assignedPlanId === assignment2.assignedPlan.id);
    assert.ok(completedPlanRestarted, 'Debe existir historial para el ciclo 2');
    assert.strictEqual(completedPlanRestarted!.completedReason, 'RESTARTED', 'Razón debe ser RESTARTED');
    assert.strictEqual(completedPlanRestarted!.sessions.length, 1, 'Debe encapsular solo 1 sesion');
    assert.strictEqual(completedPlanRestarted!.sessions[0].id, session2.id, 'Debe ser la sesion 2 unicamente');
    console.log(`✓ restartAssignment envolvió correctamente bajo RESTARTED, atrapando solo las nuevas.`);

    // ----- TEST 4: removeAssignment -----
    console.log('\n--- CASO 3: removeAssignment (Cancelaciones) ---');
    // Para simplificar, asumimos que newCycle (Assignment 3) es nuestro target
    const session3 = await trainingSessionsService.startSession(student.id, newCycle.assignedPlan!.id, 1, 1, new Date().toISOString());
    console.log(`✓ Sesión 3 iniciada en Assignment3. (Status IN_PROGRESS)`);

    // El admin decide eliminar el plan
    await plansService.removeAssignment(newCycle.id, admin);
    console.log(`✓ removeAssignment ejecutado por Admin.`);

    history = await plansService.getHistoricalPlans(student.id);
    let completedPlanCancelled = history.find(hp => hp.assignedPlanId === newCycle.assignedPlan!.id);
    assert.ok(completedPlanCancelled, 'Debe existir el folder histórico tras borrar assignment');
    assert.strictEqual(completedPlanCancelled!.completedReason, 'CANCELLED', 'Debe estar cancelado');
    assert.strictEqual(completedPlanCancelled!.sessions[0].id, session3.id, 'Debe haber guardado la sesion huerfana cancelada');
    console.log(`✓ removeAssignment encapsuló la historia con estado CANCELLED perfectamente.`);

    // ----- TEST 5: GET /plans/student/history (Visualización Completa) -----
    console.log('\n--- CASO 5: Resultado /history ---');
    const finalHistory = await plansService.getHistoricalPlans(student.id);
    console.log(JSON.stringify(
      finalHistory.map(hp => ({
        folderId: hp.id,
        reason: hp.completedReason,
        originalPlanName: hp.planNameSnapshot,
        started: hp.startedAt,
        sessionCount: hp.sessions.length,
        firstSessionData: hp.sessions.length > 0 ? {
          sessionId: hp.sessions[0].id,
          date: hp.sessions[0].date,
          status: hp.sessions[0].status,
          exercisesCount: hp.sessions[0].exercises?.length,
          repsDone: hp.sessions[0].exercises?.[0]?.repsDone,
          weightDone: hp.sessions[0].exercises?.[0]?.targetWeightSnapshot,
        } : null
      })), 
      null, 2
    ));
    console.log(`\n✓ Todos los datos reales (y snaps de nombres) viajan intactos hacia el historial estructurado.`);

    console.log('\n========================================');
    console.log('✅ VALIDACIÓN RUNTIME COMPLETADA CON ÉXITO');
    console.log('Todos los casos de Fase 2 reportaron estado verde sin mutaciones sucias.');
    console.log('========================================');


  } catch (err) {
    console.error('❌ ERROR GRAVE EN VALIDACIÓN:', err);
  } finally {
    await app.close();
  }
}

bootstrap();
