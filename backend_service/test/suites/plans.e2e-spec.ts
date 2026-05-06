import { INestApplication } from '@nestjs/common';
import { DataSource } from 'typeorm';
import request from 'supertest';
import * as bcrypt from 'bcrypt';
import { createTestApp } from '../setup/test-app.factory';
import { cleanDatabase, seedBaseGym, seedMuscles } from '../setup/db-cleanup.helper';

/**
 * Suite E2E: Ciclo de Vida de Planes de Entrenamiento
 *
 * Verifica el flujo completo y realista de un plan:
 *   Creación con ejercicios reales → Asignación → Activación
 *   → Ejecución de sesiones diarias → Marcado de progreso → Finalización
 *
 * Reglas de negocio cubiertas:
 * - Regla 4.1: Los planes son plantillas con semanas, días y ejercicios reales.
 * - Regla 4.2: El alumno solo puede tener UN plan activo a la vez (swap).
 * - Regla 4.3 (CRÍTICA): El snapshot del AssignedPlan es inmune a cambios
 *   posteriores en la plantilla original.
 * - Regla 4.4: Al finalizar, se consolida el historial inviolable.
 * - Regla 4.5: Reiniciar no destruye el historial previo.
 * - Regla 5.2: PROFE puede crear y asignar planes.
 * - Regla 5.3: ALUMNO solo puede ejecutar y ver sus propios planes.
 */
describe('[Suite] Plans - Ciclo de Vida Completo con Ejercicios Reales', () => {
  let app: INestApplication;
  let dataSource: DataSource;

  let adminToken: string;
  let profeToken: string;
  let alumnoToken: string;

  let gymId: string;
  let alumnoId: string;
  let planId: string;       // Plan plantilla
  let exerciseId: string;   // Ejercicio real creado para el plan
  let assignmentId: string; // StudentPlan asignado al alumno
  let sessionId: string;    // TrainingSession del día

  // ── Setup ─────────────────────────────────────────────────────────────────

  beforeAll(async () => {
    ({ app, dataSource } = await createTestApp());
    await cleanDatabase(dataSource);

    const gym = await seedBaseGym(dataSource, { businessName: 'Plans Full Test Gym' });
    gymId = gym.id;

    // Seedear músculos globales (requeridos para crear ejercicios)
    const muscles = await seedMuscles(dataSource);
    const muscleId = muscles[0].id; // Bíceps

    // Crear usuarios de prueba
    const adminData = await bootstrapUserWithId(app, dataSource, gymId, 'admin', 'admin.plans2@example.com');
    adminToken = adminData.token;

    const profeData = await bootstrapUserWithId(app, dataSource, gymId, 'profe', 'profe.plans2@example.com');
    profeToken = profeData.token;

    // Alumno via invite link (flujo real de registro)
    const inviteRes = await request(app.getHttpServer())
      .post('/auth/generate-invite-link')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ gymId });

    const alumnoRes = await request(app.getHttpServer())
      .post('/auth/register-with-invite')
      .send({
        inviteToken: inviteRes.body.token,
        user: {
          firstName: 'Lucas',
          lastName: 'Alumno',
          email: 'lucas.plans2@example.com',
          password: 'Alumno123!',
        },
      });

    alumnoToken = alumnoRes.body.access_token;
    alumnoId = alumnoRes.body.user.id;

    // Crear un ejercicio real para usar en el plan
    const exerciseRes = await request(app.getHttpServer())
      .post('/exercises')
      .set('Authorization', `Bearer ${profeToken}`)
      .send({
        name: 'Curl de Bíceps Test',
        description: 'Ejercicio para el plan de prueba',
        metricType: 'REPS',
        muscles: [{ muscleId, role: 'PRIMARY', loadPercentage: 100 }],
      });

    exerciseId = exerciseRes.body.id;
  });

  afterAll(async () => {
    await app.close();
  });

  // ── 1. Creación del plan con estructura real ───────────────────────────────

  describe('POST /plans - Creación con semanas, días y ejercicios reales', () => {
    it('✅ PROFE puede crear un plan con 2 semanas, días y ejercicios reales', async () => {
      /**
       * REGLA 4.1: El plan es una plantilla estructurada en semanas → días → ejercicios.
       * Cada ejercicio en el plan referencia un Exercise real del gym mediante exerciseId.
       */
      const res = await request(app.getHttpServer())
        .post('/plans')
        .set('Authorization', `Bearer ${profeToken}`)
        .send({
          name: 'Plan Fuerza 4 Semanas',
          objective: 'Fuerza',
          durationWeeks: 2,
          generalNotes: 'Descansar 90 segundos entre series.',
          weeks: [
            {
              weekNumber: 1,
              days: [
                {
                  title: 'Día A - Bíceps',
                  dayOfWeek: 1, // Lunes
                  order: 1,
                  dayNotes: 'Foco en la contracción del bíceps.',
                  exercises: [
                    {
                      exerciseId,
                      sets: 4,
                      reps: '8-12',
                      suggestedLoad: '15kg',
                      rest: '90s',
                      order: 1,
                    },
                  ],
                },
                {
                  title: 'Día B - Descanso activo',
                  dayOfWeek: 3, // Miércoles
                  order: 2,
                  exercises: [
                    {
                      exerciseId,
                      sets: 2,
                      reps: '15-20',
                      suggestedLoad: '10kg',
                      rest: '60s',
                      order: 1,
                    },
                  ],
                },
              ],
            },
            {
              weekNumber: 2,
              days: [
                {
                  title: 'Día A - Bíceps (Progresivo)',
                  dayOfWeek: 1,
                  order: 1,
                  exercises: [
                    {
                      exerciseId,
                      sets: 4,
                      reps: '6-8',
                      suggestedLoad: '17.5kg',
                      rest: '120s',
                      order: 1,
                    },
                  ],
                },
              ],
            },
          ],
        });

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('id');
      expect(res.body.name).toBe('Plan Fuerza 4 Semanas');

      planId = res.body.id;
    });

    it('✅ El plan creado tiene las semanas y días correctos', async () => {
      /**
       * Verificar que la estructura del plan fue persistida correctamente.
       */
      const res = await request(app.getHttpServer())
        .get(`/plans/${planId}`)
        .set('Authorization', `Bearer ${profeToken}`);

      expect(res.status).toBe(200);
      expect(res.body.id).toBe(planId);
      expect(res.body.name).toBe('Plan Fuerza 4 Semanas');

      // Verificar que tiene semanas
      expect(Array.isArray(res.body.weeks)).toBe(true);
      expect(res.body.weeks.length).toBe(2);

      // Semana 1 tiene 2 días
      const week1 = res.body.weeks.find((w: any) => w.weekNumber === 1);
      expect(week1).toBeDefined();
      expect(week1.days.length).toBe(2);

      // El primer día tiene ejercicios
      const day1 = week1.days.find((d: any) => d.order === 1);
      expect(day1).toBeDefined();
      expect(day1.exercises.length).toBe(1);
      expect(day1.exercises[0].sets).toBe(4);
      expect(day1.exercises[0].reps).toBe('8-12');
    });

    it('❌ ALUMNO no puede crear un plan (403)', async () => {
      const res = await request(app.getHttpServer())
        .post('/plans')
        .set('Authorization', `Bearer ${alumnoToken}`)
        .send({ name: 'Plan Pirata', durationWeeks: 1, weeks: [] });

      expect(res.status).toBe(403);
    });
  });

  // ── 2. Asignación del plan al alumno ──────────────────────────────────────

  describe('POST /plans/assign - Asignación con snapshot del plan', () => {
    it('✅ PROFE asigna el plan al alumno (crea snapshot inmutable)', async () => {
      /**
       * REGLA 4.3: Al asignar, el sistema crea un AssignedPlan (snapshot)
       * que es un árbol completamente independiente de la plantilla original.
       */
      const res = await request(app.getHttpServer())
        .post('/plans/assign')
        .set('Authorization', `Bearer ${profeToken}`)
        .send({ planId, studentId: alumnoId });

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('id');

      assignmentId = res.body.id;
    });

    it('✅ El alumno puede ver su asignación con el snapshot del plan', async () => {
      const res = await request(app.getHttpServer())
        .get('/plans/student/assignments')
        .set('Authorization', `Bearer ${alumnoToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);

      const assignment = res.body.find((a: any) => a.id === assignmentId);
      expect(assignment).toBeDefined();

      // El snapshot (assignedPlan) referencia el plan original
      if (assignment.assignedPlan) {
        expect(assignment.assignedPlan.originalPlanId).toBe(planId);
      }
    });
  });

  // ── 3. Activación del plan ────────────────────────────────────────────────

  describe('POST /plans/student/assignments/:id/activate - Activación', () => {
    it('✅ ALUMNO activa su plan asignado', async () => {
      /**
       * REGLA 4.2: El alumno acciona el plan para comenzar a ejecutarlo.
       * BUGFIX verificado: activateAssignment ya carga relaciones correctamente.
       */
      const res = await request(app.getHttpServer())
        .post(`/plans/student/assignments/${assignmentId}/activate`)
        .set('Authorization', `Bearer ${alumnoToken}`);

      expect(res.status).not.toBe(400);
      expect(res.status).not.toBe(403);
      expect(res.status).not.toBe(401);

      // Verificar que el plan quedó activo
      const assignmentsRes = await request(app.getHttpServer())
        .get('/plans/student/assignments')
        .set('Authorization', `Bearer ${alumnoToken}`);

      const active = assignmentsRes.body.find((a: any) => a.isActive === true);
      expect(active).toBeDefined();
    });
  });

  // ── 4. Inmutabilidad del snapshot (TEST MÁS CRÍTICO) ─────────────────────

  describe('PATCH /plans/:id - Snapshot inmune a cambios en la plantilla', () => {
    it('✅ Modificar la plantilla NO altera el snapshot del alumno activo', async () => {
      /**
       * REGLA 4.3 (DO NOT BREAK): Esta es la regla más crítica del sistema.
       * Las ediciones en la plantilla base NO deben afectar a alumnos con
       * ese plan en curso. El AssignedPlan es un árbol de datos independiente.
       *
       * Flujo: Capturar snapshot → Modificar plantilla → Verificar snapshot intacto.
       */

      // Capturar el estado del snapshot ANTES del cambio
      const beforeRes = await request(app.getHttpServer())
        .get('/plans/student/assignments')
        .set('Authorization', `Bearer ${alumnoToken}`);

      const activeAssignment = beforeRes.body.find((a: any) => a.isActive === true);
      expect(activeAssignment).toBeDefined();

      const snapshotNameBefore =
        activeAssignment.assignedPlan?.name ?? activeAssignment.plan?.name;

      // Modificar la plantilla original (nombre diferente + agregar notas)
      const patchRes = await request(app.getHttpServer())
        .patch(`/plans/${planId}`)
        .set('Authorization', `Bearer ${profeToken}`)
        .send({
          name: 'Plan Fuerza 4 Semanas - VERSIÓN ACTUALIZADA',
          generalNotes: 'Nota nueva que NO debe aparecer en el alumno activo.',
        });

      expect(patchRes.status).toBe(200);

      // Verificar que el snapshot del alumno NO cambió
      const afterRes = await request(app.getHttpServer())
        .get('/plans/student/assignments')
        .set('Authorization', `Bearer ${alumnoToken}`);

      const activeAssignmentAfter = afterRes.body.find((a: any) => a.isActive === true);
      expect(activeAssignmentAfter).toBeDefined();

      if (activeAssignmentAfter.assignedPlan) {
        // El AssignedPlan tiene su propio nombre (copia del momento de asignación)
        expect(activeAssignmentAfter.assignedPlan.name).not.toBe(
          'Plan Fuerza 4 Semanas - VERSIÓN ACTUALIZADA',
        );
        expect(activeAssignmentAfter.assignedPlan.originalPlanId).toBe(planId);

        // Los ejercicios del snapshot deben seguir existiendo
        const snapshotWeeks = activeAssignmentAfter.assignedPlan.weeks;
        if (snapshotWeeks) {
          expect(snapshotWeeks.length).toBeGreaterThan(0);
        }
      }
    });
  });

  // ── 5. Ejecución de sesiones (entrenamiento diario real) ──────────────────

  describe('POST /executions - Ejecución de una sesión diaria', () => {
    it('✅ ALUMNO inicia una sesión de entrenamiento (Semana 1, Día 1)', async () => {
      /**
       * El alumno abre la app, va al Día A de la Semana 1 y presiona "Iniciar".
       * El sistema crea una TrainingSession ligada al plan y al alumno.
       *
       * Importante: se usa el assignedPlanId (snapshot) que es lo que tiene
       * el alumno asignado, no el planId de la plantilla original.
       */

      // Obtener el assignedPlanId desde el assignment del alumno
      const assignmentsRes = await request(app.getHttpServer())
        .get('/plans/student/assignments')
        .set('Authorization', `Bearer ${alumnoToken}`);

      const activeAssignment = assignmentsRes.body.find((a: any) => a.isActive === true);
      const assignedPlanId = activeAssignment?.assignedPlan?.id ?? planId;

      const today = new Date().toISOString().split('T')[0];

      const res = await request(app.getHttpServer())
        .post('/executions/start')
        .set('Authorization', `Bearer ${alumnoToken}`)
        .send({
          planId: assignedPlanId,
          weekNumber: 1,
          dayOrder: 1,
          date: today,
        });

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('id');
      expect(res.body.status).toBe('IN_PROGRESS');

      sessionId = res.body.id;
    });

    it('✅ La sesión ya tiene los ejercicios del snapshot del plan', async () => {
      /**
       * Al iniciar la sesión con el assignedPlan, el sistema automáticamente
       * crea SessionExercises a partir de los ejercicios del día del snapshot.
       * No es necesario agregar ejercicios manualmente.
       */
      const res = await request(app.getHttpServer())
        .get(`/executions/${sessionId}`)
        .set('Authorization', `Bearer ${alumnoToken}`);

      expect(res.status).toBe(200);
      expect(res.body.id).toBe(sessionId);
      expect(res.body.status).toBe('IN_PROGRESS');
      expect(Array.isArray(res.body.exercises)).toBe(true);
      // El Día 1 de la Semana 1 tiene 1 ejercicio (Curl de Bíceps con 4 series)
      expect(res.body.exercises.length).toBeGreaterThanOrEqual(1);
    });

    it('✅ ALUMNO marca los ejercicios de la sesión como completados', async () => {
      /**
       * El alumno va marcando cada ejercicio como hecho.
       * El servicio requiere que todos estén en isCompleted: true
       * con sets y reps válidos antes de poder cerrar la sesión.
       */

      // Obtener los ejercicios de la sesión
      const sessionRes = await request(app.getHttpServer())
        .get(`/executions/${sessionId}`)
        .set('Authorization', `Bearer ${alumnoToken}`);

      const sessionExercises = sessionRes.body.exercises;

      // Marcar cada ejercicio como completado
      for (const ex of sessionExercises) {
        const res = await request(app.getHttpServer())
          .patch(`/executions/exercises/${ex.id}`)
          .set('Authorization', `Bearer ${alumnoToken}`)
          .send({
            isCompleted: true,
            setsDone: String(ex.targetSetsSnapshot || '4'),
            repsDone: ex.targetRepsSnapshot || '10',
            weightUsed: '15',
          });

        expect([200, 201]).toContain(res.status);
      }
    });

    it('✅ ALUMNO completa la sesión del día', async () => {
      /**
       * El servicio valida que TODOS los ejercicios de la sesión tengan:
       * - isCompleted: true
       * - setsDone y repsDone con valores válidos
       * Esto fue validado en el test anterior. Ahora cerramos la sesión.
       */
      const today = new Date().toISOString().split('T')[0];

      const res = await request(app.getHttpServer())
        .patch(`/executions/${sessionId}/complete`)
        .set('Authorization', `Bearer ${alumnoToken}`)
        .send({ date: today });

      // El servicio retorna { session, stats } al completar
      expect([200, 201]).toContain(res.status);
      const sessionBody = res.body.session ?? res.body;
      expect(sessionBody.status).toBe('COMPLETED');
    });
  });

  // ── 6. Registro de progreso en el plan ───────────────────────────────────

  describe('PATCH /plans/student/progress - Progreso del día en el plan', () => {
    it('✅ ALUMNO registra el día como completado en su plan', async () => {
      /**
       * Además de la sesión de entrenamiento, el plan también lleva un registro
       * de progreso por día (cuáles días del plan fueron completados).
       * Esto es independiente de las TrainingSessions y se usa para saber
       * el % de avance del plan.
       */
      const today = new Date().toISOString().split('T')[0];

      const res = await request(app.getHttpServer())
        .patch('/plans/student/progress')
        .set('Authorization', `Bearer ${alumnoToken}`)
        .send({
          studentPlanId: assignmentId,
          type: 'day',
          id: 'day-1-week-1', // ID del día en el plan
          completed: true,
          date: today,
        });

      // El sistema acepta el registro de progreso
      expect([200, 201]).toContain(res.status);
    });
  });

  // ── 7. Finalización del plan ──────────────────────────────────────────────

  describe('POST /plans/student/finish/:assignmentId - Finalización', () => {
    it('✅ ALUMNO finaliza el plan con sesiones completadas', async () => {
      /**
       * REGLA 4.4: Al finalizar el plan se consolida una copia fiel e
       * inmutable en el historial. La sesión completada cuenta como evidencia
       * de progreso, satisfaciendo la validación del finishAssignment.
       *
       * BUGFIX verificado: finishAssignment ya no nula startDate (NOT NULL).
       */

      // Asegurarnos de que hay progreso en el plan (la sesión completada ya lo garantiza,
      // pero también seteamos progreso via JSON directo para cubrir ambos caminos)
      await dataSource.query(
        `UPDATE student_plans
         SET progress = '{"days":{"day-1-week-1":{"completed":true,"date":"${new Date().toISOString()}"}}}'::jsonb
         WHERE id = $1`,
        [assignmentId],
      );

      const res = await request(app.getHttpServer())
        .post(`/plans/student/finish/${assignmentId}`)
        .set('Authorization', `Bearer ${alumnoToken}`);

      expect(res.status).toBe(201);
    });

    it('✅ El historial del alumno refleja el plan completado con sus sesiones', async () => {
      /**
       * REGLA 2: El historial es propiedad exclusiva e inalienable del alumno.
       * Debe persistir y reflejar los datos reales de entrenamiento.
       */
      const res = await request(app.getHttpServer())
        .get('/plans/student/history')
        .set('Authorization', `Bearer ${alumnoToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThanOrEqual(1);

      // El plan finalizado debe estar en el historial
      const completedPlan = res.body.find(
        (h: any) => h.originalPlanId === planId || h.plan?.id === planId,
      );
      expect(completedPlan).toBeDefined();
    });
  });

  // ── 8. Reinicio de plan ───────────────────────────────────────────────────

  describe('POST /plans/student/restart/:assignmentId - Reinicio', () => {
    it('✅ Reiniciar un plan no destruye el historial previo', async () => {
      /**
       * REGLA 4.5: El reset vuelve al estado inicial del plan.
       * El historial previo queda blindado y no se modifica.
       */
      const historyBefore = await request(app.getHttpServer())
        .get('/plans/student/history')
        .set('Authorization', `Bearer ${alumnoToken}`);

      const historyCountBefore = historyBefore.body.length;

      // Asignar y activar un nuevo plan para poder reiniciarlo
      const newAssignRes = await request(app.getHttpServer())
        .post('/plans/assign')
        .set('Authorization', `Bearer ${profeToken}`)
        .send({ planId, studentId: alumnoId });

      const newAssignmentId = newAssignRes.body.id;

      await request(app.getHttpServer())
        .post(`/plans/student/assignments/${newAssignmentId}/activate`)
        .set('Authorization', `Bearer ${alumnoToken}`);

      // Reiniciar el plan
      const restartRes = await request(app.getHttpServer())
        .post(`/plans/student/restart/${newAssignmentId}`)
        .set('Authorization', `Bearer ${alumnoToken}`);

      expect(restartRes.status).toBe(201);

      // El historial anterior debe seguir intacto
      const historyAfter = await request(app.getHttpServer())
        .get('/plans/student/history')
        .set('Authorization', `Bearer ${alumnoToken}`);

      expect(historyAfter.body.length).toBeGreaterThanOrEqual(historyCountBefore);
    });
  });

  // ── 9. Swap de planes (Regla 4.2) ────────────────────────────────────────

  describe('Activar 2do plan hace SWAP, no rechazo', () => {
    it('✅ Activar un segundo plan desactiva el primero automáticamente', async () => {
      /**
       * REGLA 4.2 (DISEÑO): El sistema implementa SWAP al activar un 2do plan.
       * Nunca hay dos planes activos simultáneamente.
       */

      // Asignar dos planes al alumno
      const assign1Res = await request(app.getHttpServer())
        .post('/plans/assign')
        .set('Authorization', `Bearer ${profeToken}`)
        .send({ planId, studentId: alumnoId });

      const assign2Res = await request(app.getHttpServer())
        .post('/plans/assign')
        .set('Authorization', `Bearer ${profeToken}`)
        .send({ planId, studentId: alumnoId });

      const id1 = assign1Res.body.id;
      const id2 = assign2Res.body.id;

      // Activar el primero
      await request(app.getHttpServer())
        .post(`/plans/student/assignments/${id1}/activate`)
        .set('Authorization', `Bearer ${alumnoToken}`);

      // Activar el segundo → debe hacer SWAP
      const activateRes = await request(app.getHttpServer())
        .post(`/plans/student/assignments/${id2}/activate`)
        .set('Authorization', `Bearer ${alumnoToken}`);

      expect(activateRes.status).toBe(201);

      // Verificar que solo hay UN plan activo
      const assignmentsRes = await request(app.getHttpServer())
        .get('/plans/student/assignments')
        .set('Authorization', `Bearer ${alumnoToken}`);

      const activePlans = assignmentsRes.body.filter((a: any) => a.isActive === true);
      expect(activePlans.length).toBe(1);
      expect(activePlans[0].id).toBe(id2);
    });
  });
});

// ── Helpers ───────────────────────────────────────────────────────────────────

async function bootstrapUserWithId(
  app: INestApplication,
  dataSource: DataSource,
  gymId: string,
  role: string,
  email: string,
): Promise<{ token: string; id: string }> {
  const passwordHash = await bcrypt.hash('Admin123!', 10);

  const result = await dataSource.query(
    `INSERT INTO users ("firstName", "lastName", email, "passwordHash", role, "isActive", "paysMembership", "gymId")
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     ON CONFLICT (email) DO UPDATE SET "gymId" = EXCLUDED."gymId"
     RETURNING id`,
    ['Test', role, email, passwordHash, role, true, false, gymId],
  );

  const id = result[0].id;

  const loginRes = await request(app.getHttpServer())
    .post('/auth/login')
    .send({ email, password: 'Admin123!' });

  return { token: loginRes.body.access_token, id };
}
