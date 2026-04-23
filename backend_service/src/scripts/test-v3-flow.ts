import * as dotenv from 'dotenv';
dotenv.config();
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { PlansService } from '../plans/plans.service';
import { UsersService } from '../users/users.service';
import { GymsService } from '../gyms/gyms.service';
import { ExercisesService } from '../exercises/exercises.service';
import { UserRole } from '../users/entities/user.entity';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  
  const plansService = app.get(PlansService);
  const usersService = app.get(UsersService);
  const gymsService = app.get(GymsService);
  const exercisesService = app.get(ExercisesService);

  console.log('--- INICIANDO PRUEBA DE VISIBILIDAD V3 ---');

  try {
    const allExs = await exercisesService.findAll();
    const exercise = allExs[0];
    const allGyms = await gymsService.findAll();
    const gym = allGyms[0];
    
    // Create users
    const student = await usersService.create({
      email: `test_v3_${Date.now()}@test.com`,
      password: 'password123',
      firstName: 'Student',
      lastName: 'V3',
      role: UserRole.ALUMNO,
      gymId: gym.id
    });
    
    const admin = await usersService.create({
      email: `admin_v3_${Date.now()}@test.com`,
      password: 'password123',
      firstName: 'Admin',
      lastName: 'V3',
      role: UserRole.ADMIN,
      gymId: gym.id
    });

    // Create plan
    const createPlanDto: any = {
      name: 'Plan de Prueba V3',
      description: 'Prueba de validacion',
      objective: 'Testing',
      durationWeeks: 1,
      weeks: [{ weekNumber: 1, days: [{ title: 'Dia 1', dayOfWeek: 1, order: 1, exercises: [] }] }]
    };
    const plan = await plansService.create(createPlanDto, admin);

    console.log('--- PRUEBA 1: ASIGNACIÓN INICIAL ---');
    const assign1 = await plansService.assignPlan(plan.id, student.id, admin);
    console.log(`Asignado. ID: ${assign1.id}, isActive: ${assign1.isActive}, originalPlanId: ${assign1.assignedPlan.originalPlanId}`);

    // Update progress
    await plansService.updateProgress(assign1.id, student.id, { type: 'day', id: 'some-day-id', completed: true });
    
    const updatedAssign1 = await plansService.findStudentAssignments(student.id);
    console.log(`Progreso guardado. Días Completados: ${Object.keys(updatedAssign1[0].progress?.days || {}).length}`);

    console.log('\n--- PRUEBA 2: RE-ASIGNACIÓN (Profesor) ---');
    const assign2 = await plansService.assignPlan(plan.id, student.id, admin);
    console.log(`Reasignado. Retorno ID: ${assign2.id}, isActive: ${assign2.isActive}`);
    
    const studentListAfterReassign = await plansService.findStudentAssignments(student.id);
    console.log(`El estudiante tiene ${studentListAfterReassign.length} asignaciones luego de reasignar.`);
    if (studentListAfterReassign.length > 1) {
        throw new Error('DUPLICATE ENCOUNTERED!');
    }
    console.log(`Progreso conservado? Días Completados: ${Object.keys(studentListAfterReassign[0].progress?.days || {}).length}`);

    console.log('\n--- PRUEBA 3: FINALIZACIÓN DE CICLO ---');
    
    // Simulate a session so finishAssignment works
    const trainingSessionsService = app.get('TrainingSessionsService');
    const session = await trainingSessionsService.startSession(student.id, assign2.assignedPlan.id, 1, 1, new Date().toISOString());
    console.log(`Sesion iniciada ${session.id}`);
    
    await trainingSessionsService.completeSession(session.id, student.id, new Date().toISOString());
    console.log(`Sesion completada ${session.id}`);

    await plansService.finishAssignment(assign2.id, student.id);
    const studentListAfterFinish = await plansService.findStudentAssignments(student.id);
    console.log(`El estudiante tiene ${studentListAfterFinish.length} asignaciones.`);
    console.log(`Asignación isActive: ${studentListAfterFinish[0].isActive}`);
    const history = await plansService.getHistoricalPlans(student.id);
    console.log(`Historial tiene ${history.length} elementos.`);
    
    console.log('\n--- PRUEBA 4: REINICIO DE CICLO (Alumno) ---');
    // First let's set it to active again as if the student selected it.
    await plansService.activateAssignment(assign2.id, student.id);
    
    // Create another session so restart has something to wrap
    const session2 = await trainingSessionsService.startSession(student.id, assign2.assignedPlan.id, 1, 2, new Date().toISOString());
    await trainingSessionsService.completeSession(session2.id, student.id, new Date().toISOString());
    
    const restarted = await plansService.restartAssignment(assign2.id, student.id);
    console.log(`Restarted. isActive: ${restarted.isActive}`);
    console.log(`Progress reseteado? Días Completados: ${Object.keys(restarted.progress?.days || {}).length}`);

    console.log('\nSUCCESS: Todo funciona como se estructuró en la V3!');

  } catch (err) {
    console.error('❌ ERROR GRAVE EN VALIDACIÓN:', err);
  } finally {
    await app.close();
  }
}

bootstrap();
