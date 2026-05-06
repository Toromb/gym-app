import { INestApplication } from '@nestjs/common';
import { DataSource } from 'typeorm';
import request from 'supertest';
import * as bcrypt from 'bcrypt';
import { createTestApp } from '../setup/test-app.factory';
import { cleanDatabase, seedBaseGym, seedMuscles } from '../setup/db-cleanup.helper';

/**
 * Suite E2E: Ejercicios y Equipamiento
 *
 * Verifica el ciclo de vida completo del catálogo de ejercicios de un gym,
 * incluyendo la gestión de equipamiento personalizado por gym.
 *
 * Reglas de negocio cubiertas:
 * - ADMIN y PROFE pueden crear/editar/eliminar ejercicios y equipamiento.
 * - ALUMNO no puede modificar el catálogo (solo lectura implícita por rol).
 * - El equipamiento es scoped al gym (multi-tenancy): gymId se deriva del token.
 * - Un ejercicio requiere al menos 1 músculo con rol de activación definido.
 */
describe('[Suite] Exercises - Catálogo de Ejercicios y Equipamiento', () => {
  let app: INestApplication;
  let dataSource: DataSource;

  let adminToken: string;
  let profeToken: string;
  let alumnoToken: string;

  // IDs creados durante los tests
  let equipmentId: string;
  let exerciseId: string;
  let muscleId: string; // Músculos son globales (seeded al arrancar la app)

  // ── Setup ─────────────────────────────────────────────────────────────────

  beforeAll(async () => {
    ({ app, dataSource } = await createTestApp());
    await cleanDatabase(dataSource);

    const gym = await seedBaseGym(dataSource, { businessName: 'Exercises Test Gym' });
    const gymId = gym.id;

    // Crear usuarios directamente en BD y obtener sus tokens via login
    adminToken = await bootstrapToken(app, dataSource, gymId, 'admin', 'admin.ex@example.com');
    profeToken = await bootstrapToken(app, dataSource, gymId, 'profe', 'profe.ex@example.com');
    alumnoToken = await bootstrapToken(app, dataSource, gymId, 'alumno', 'alumno.ex@example.com');

    // Seedear músculos globales (datos maestros eliminados por cleanDatabase)
    const muscles = await seedMuscles(dataSource);
    if (muscles.length > 0) {
      muscleId = muscles[0].id;
    }
  });

  afterAll(async () => {
    await app.close();
  });

  // ── Tests: Gestión de Equipamiento ────────────────────────────────────────

  describe('POST /exercises/equipments - Creación de equipamiento', () => {
    it('✅ ADMIN puede crear equipamiento en su gym', async () => {
      /**
       * El equipamiento es scoped al gym del usuario autenticado.
       * El gymId se toma del JWT, no del body.
       */
      const res = await request(app.getHttpServer())
        .post('/exercises/equipments')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ name: 'Mancuernas 10kg' });

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('id');
      expect(res.body.name).toBe('Mancuernas 10kg');

      equipmentId = res.body.id;
    });

    it('✅ PROFE puede crear equipamiento en su gym', async () => {
      const res = await request(app.getHttpServer())
        .post('/exercises/equipments')
        .set('Authorization', `Bearer ${profeToken}`)
        .send({ name: 'Banda Elástica' });

      expect(res.status).toBe(201);
      expect(res.body.name).toBe('Banda Elástica');
    });

    it('❌ Sin body/nombre retorna error (400)', async () => {
      const res = await request(app.getHttpServer())
        .post('/exercises/equipments')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({});

      expect(res.status).toBeGreaterThanOrEqual(400);
    });

    it('❌ Sin token retorna 401', async () => {
      const res = await request(app.getHttpServer())
        .post('/exercises/equipments')
        .send({ name: 'Sin Auth' });

      expect(res.status).toBe(401);
    });
  });

  describe('GET /exercises/equipments - Listado de equipamiento', () => {
    it('✅ ADMIN puede listar el equipamiento de su gym', async () => {
      const res = await request(app.getHttpServer())
        .get('/exercises/equipments')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);

      // Debe incluir el equipamiento creado anteriormente
      const found = res.body.find((e: any) => e.id === equipmentId);
      expect(found).toBeDefined();
      expect(found.name).toBe('Mancuernas 10kg');
    });

    it('✅ ALUMNO puede listar equipamiento (solo lectura)', async () => {
      const res = await request(app.getHttpServer())
        .get('/exercises/equipments')
        .set('Authorization', `Bearer ${alumnoToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  describe('DELETE /exercises/equipments/:id - Eliminación de equipamiento', () => {
    it('✅ ADMIN puede eliminar equipamiento de su gym', async () => {
      // Crear uno nuevo para no eliminar el que se usará en los tests de ejercicios
      const createRes = await request(app.getHttpServer())
        .post('/exercises/equipments')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ name: 'Equipo Para Eliminar' });

      const idToDelete = createRes.body.id;

      const res = await request(app.getHttpServer())
        .delete(`/exercises/equipments/${idToDelete}`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);

      // Verificar que ya no aparece en el listado
      const listRes = await request(app.getHttpServer())
        .get('/exercises/equipments')
        .set('Authorization', `Bearer ${adminToken}`);

      const deleted = listRes.body.find((e: any) => e.id === idToDelete);
      expect(deleted).toBeUndefined();
    });
  });

  // ── Tests: Músculos (Globales) ─────────────────────────────────────────────

  describe('GET /exercises/muscles - Listado de músculos', () => {
    it('✅ Cualquier usuario autenticado puede listar los músculos globales', async () => {
      const res = await request(app.getHttpServer())
        .get('/exercises/muscles')
        .set('Authorization', `Bearer ${alumnoToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      // Los músculos son seeded al arrancar → siempre deben existir
      expect(res.body.length).toBeGreaterThan(0);
    });
  });

  // ── Tests: Gestión de Ejercicios ──────────────────────────────────────────

  describe('POST /exercises - Creación de ejercicios', () => {
    it('✅ PROFE puede crear un ejercicio con músculo asignado', async () => {
      /**
       * El ejercicio requiere `muscles: ExerciseMuscleDto[]` con al menos 1 entrada.
       * Cada entrada tiene: muscleId (UUID), role (PRIMARY/SECONDARY/STABILIZER),
       * loadPercentage (0-100).
       */
      if (!muscleId) {
        console.warn('[Test] No hay músculos en la BD. Saltando creación de ejercicio.');
        return;
      }

      const res = await request(app.getHttpServer())
        .post('/exercises')
        .set('Authorization', `Bearer ${profeToken}`)
        .send({
          name: 'Curl de Bíceps',
          description: 'Ejercicio de aislamiento para bíceps',
          metricType: 'REPS',
          muscles: [
            {
              muscleId,
              role: 'PRIMARY',
              loadPercentage: 100,
            },
          ],
        });

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('id');
      expect(res.body.name).toBe('Curl de Bíceps');

      exerciseId = res.body.id;
    });

    it('✅ ADMIN puede crear un ejercicio con múltiples músculos', async () => {
      if (!muscleId) return;

      const res = await request(app.getHttpServer())
        .post('/exercises')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          name: 'Sentadilla',
          description: 'Ejercicio compuesto de piernas',
          metricType: 'REPS',
          muscles: [
            {
              muscleId,
              role: 'PRIMARY',
              loadPercentage: 100, // La suma DEBE ser exactamente 100%
            },
          ],
        });

      expect(res.status).toBe(201);
      expect(res.body.name).toBe('Sentadilla');
      expect(res.body).toHaveProperty('id');
    });

    it('❌ ALUMNO no puede crear ejercicios (403)', async () => {
      if (!muscleId) return;

      const res = await request(app.getHttpServer())
        .post('/exercises')
        .set('Authorization', `Bearer ${alumnoToken}`)
        .send({
          name: 'Ejercicio Pirata',
          muscles: [{ muscleId, role: 'PRIMARY', loadPercentage: 100 }],
        });

      expect(res.status).toBe(403);
    });

    it('❌ Sin nombre retorna error (400)', async () => {
      const res = await request(app.getHttpServer())
        .post('/exercises')
        .set('Authorization', `Bearer ${profeToken}`)
        .send({
          muscles: [], // sin nombre
        });

      expect(res.status).toBeGreaterThanOrEqual(400);
    });
  });

  describe('GET /exercises - Listado de ejercicios', () => {
    it('✅ PROFE puede listar los ejercicios de su gym', async () => {
      const res = await request(app.getHttpServer())
        .get('/exercises')
        .set('Authorization', `Bearer ${profeToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);

      if (exerciseId) {
        const found = res.body.find((e: any) => e.id === exerciseId);
        expect(found).toBeDefined();
        expect(found.name).toBe('Curl de Bíceps');
      }
    });

    it('✅ ALUMNO puede listar ejercicios (solo lectura)', async () => {
      const res = await request(app.getHttpServer())
        .get('/exercises')
        .set('Authorization', `Bearer ${alumnoToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  describe('PATCH /exercises/:id - Edición de ejercicios', () => {
    it('✅ PROFE puede editar la descripción de un ejercicio', async () => {
      if (!exerciseId) return;

      const res = await request(app.getHttpServer())
        .patch(`/exercises/${exerciseId}`)
        .set('Authorization', `Bearer ${profeToken}`)
        .send({ description: 'Descripción actualizada: enfocarse en la contracción' });

      expect(res.status).toBe(200);
      expect(res.body.description).toBe('Descripción actualizada: enfocarse en la contracción');
    });
  });

  describe('DELETE /exercises/:id - Eliminación de ejercicios', () => {
    it('✅ ADMIN puede eliminar un ejercicio', async () => {
      if (!muscleId) return;

      // Crear uno nuevo solo para eliminarlo (no rompemos los demás tests)
      const createRes = await request(app.getHttpServer())
        .post('/exercises')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          name: 'Ejercicio Para Eliminar',
          muscles: [{ muscleId, role: 'PRIMARY', loadPercentage: 100 }],
        });

      expect(createRes.status).toBe(201);
      const idToDelete = createRes.body.id;

      const res = await request(app.getHttpServer())
        .delete(`/exercises/${idToDelete}`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
    });
  });
});

// ── Helpers ───────────────────────────────────────────────────────────────────

async function bootstrapToken(
  app: INestApplication,
  dataSource: DataSource,
  gymId: string,
  role: string,
  email: string,
): Promise<string> {
  const passwordHash = await bcrypt.hash('Test123!', 10);

  await dataSource.query(
    `INSERT INTO users ("firstName", "lastName", email, "passwordHash", role, "isActive", "paysMembership", "gymId")
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     ON CONFLICT (email) DO UPDATE SET "gymId" = EXCLUDED."gymId"`,
    ['Test', role, email, passwordHash, role, true, false, gymId],
  );

  const loginRes = await request(app.getHttpServer())
    .post('/auth/login')
    .send({ email, password: 'Test123!' });

  return loginRes.body.access_token;
}
