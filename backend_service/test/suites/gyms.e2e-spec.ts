import { INestApplication } from '@nestjs/common';
import { DataSource } from 'typeorm';
import request from 'supertest';
import * as bcrypt from 'bcrypt';
import { createTestApp } from '../setup/test-app.factory';
import { cleanDatabase, seedBaseGym } from '../setup/db-cleanup.helper';

/**
 * Suite E2E: Gimnasios
 *
 * Cubre la creación y gestión de gimnasios, y verifica el aislamiento
 * de datos entre gimnasios distintos (multi-tenancy).
 *
 * Reglas de negocio cubiertas:
 * - Regla 1: Todo acceso debe estar asociado a un gimnasio activo.
 * - Regla 3 (Multi-Gym / Aislamiento): Toda la información operativa debe
 *   estar estrictamente segregada por gimnasio. No debe existir cruce de datos
 *   entre clientes comerciales distintos.
 * - Regla 5.1 (ADMIN): Solo SUPER_ADMIN puede crear gimnasios.
 * - Regla 10 (DO NOT BREAK): Ningún update debe romper el silo de cliente.
 */
describe('[Suite] Gyms - Creación y Aislamiento de Gimnasios', () => {
  let app: INestApplication;
  let dataSource: DataSource;

  // Tokens de acceso por rol
  let superAdminToken: string;
  let adminGymAToken: string;
  let adminGymBToken: string;

  // IDs de los gimnasios creados
  let gymAId: string;
  let gymBId: string;

  // ── Setup ─────────────────────────────────────────────────────────────────

  beforeAll(async () => {
    ({ app, dataSource } = await createTestApp());
    await cleanDatabase(dataSource);

    // Bootstrapping: crear SA y dos gyms para probar el aislamiento
    superAdminToken = await bootstrapSuperAdmin(app, dataSource);

    // Gym A: creado via API por el SA
    const gymARes = await request(app.getHttpServer())
      .post('/gyms')
      .set('Authorization', `Bearer ${superAdminToken}`)
      .send({ businessName: 'Gym Alpha', address: 'Calle Alpha 100' });

    expect(gymARes.status).toBe(201);
    gymAId = gymARes.body.id;

    // Gym B: segundo gimnasio para probar el aislamiento
    const gymBRes = await request(app.getHttpServer())
      .post('/gyms')
      .set('Authorization', `Bearer ${superAdminToken}`)
      .send({ businessName: 'Gym Beta', address: 'Calle Beta 200' });

    expect(gymBRes.status).toBe(201);
    gymBId = gymBRes.body.id;

    // Crear un ADMIN para Gym A y otro para Gym B
    adminGymAToken = await bootstrapAdmin(app, dataSource, gymAId, 'admin.alpha@example.com');
    adminGymBToken = await bootstrapAdmin(app, dataSource, gymBId, 'admin.beta@example.com');
  });

  afterAll(async () => {
    await app.close();
  });

  // ── Tests: Creación de Gym ────────────────────────────────────────────────

  describe('POST /gyms', () => {
    it('✅ SUPER_ADMIN puede crear un gimnasio', async () => {
      /**
       * REGLA 5.1: Solo el SUPER_ADMIN tiene autoridad para crear gimnasios.
       * Los ADMIN solo administran su propio local, no pueden crear otros.
       */
      const res = await request(app.getHttpServer())
        .post('/gyms')
        .set('Authorization', `Bearer ${superAdminToken}`)
        .send({ businessName: 'Gym Gamma', address: 'Calle Gamma 300' });

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('id');
      expect(res.body.businessName).toBe('Gym Gamma');
      expect(res.body.status).toBe('active');
    });

    it('❌ ADMIN no puede crear un gimnasio (403)', async () => {
      /**
       * REGLA 5.1: El ADMIN tiene autoridad dentro de su gimnasio, pero
       * no puede crear nuevos recintos en el sistema.
       */
      const res = await request(app.getHttpServer())
        .post('/gyms')
        .set('Authorization', `Bearer ${adminGymAToken}`)
        .send({ businessName: 'Gym Pirata', address: 'Calle Pirata 999' });

      expect(res.status).toBe(403);
    });

    it('❌ Request sin autenticación es rechazado (401)', async () => {
      const res = await request(app.getHttpServer())
        .post('/gyms')
        .send({ businessName: 'Gym Anonimo', address: 'Calle Anon 1' });

      expect(res.status).toBe(401);
    });
  });

  // ── Tests: Consulta de Gym ────────────────────────────────────────────────

  describe('GET /gyms/:id', () => {
    it('✅ ADMIN puede ver SU propio gimnasio', async () => {
      /**
       * REGLA 3: Cada administrador tiene acceso de lectura total
       * dentro de su propio dominio.
       */
      const res = await request(app.getHttpServer())
        .get(`/gyms/${gymAId}`)
        .set('Authorization', `Bearer ${adminGymAToken}`);

      expect(res.status).toBe(200);
      expect(res.body.id).toBe(gymAId);
      expect(res.body.businessName).toBe('Gym Alpha');
    });

    it('❌ ADMIN de Gym A NO puede ver datos de Gym B (403 - Multi-Tenant Isolation)', async () => {
      /**
       * REGLA 3 (CRÍTICA): El aislamiento de datos es una regla inquebrantable.
       * El Admin de Gym A no debe poder ver, editar ni acceder a datos de Gym B.
       * Esta es la prueba más importante de toda la suite de Gyms.
       */
      const res = await request(app.getHttpServer())
        .get(`/gyms/${gymBId}`)
        .set('Authorization', `Bearer ${adminGymAToken}`);

      expect(res.status).toBe(403);
    });

    it('✅ SUPER_ADMIN puede ver cualquier gimnasio', async () => {
      const res = await request(app.getHttpServer())
        .get(`/gyms/${gymBId}`)
        .set('Authorization', `Bearer ${superAdminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.id).toBe(gymBId);
    });
  });

  // ── Tests: Listado de Gyms ────────────────────────────────────────────────

  describe('GET /gyms', () => {
    it('✅ SUPER_ADMIN puede listar todos los gimnasios', async () => {
      const res = await request(app.getHttpServer())
        .get('/gyms')
        .set('Authorization', `Bearer ${superAdminToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThanOrEqual(2); // Alpha, Beta + posiblemente Gamma
    });

    it('❌ ADMIN no puede listar todos los gimnasios (403)', async () => {
      /**
       * REGLA 3: El ADMIN no tiene visibilidad sobre otros recintos.
       * Solo el SA tiene una vista global del sistema.
       */
      const res = await request(app.getHttpServer())
        .get('/gyms')
        .set('Authorization', `Bearer ${adminGymAToken}`);

      expect(res.status).toBe(403);
    });
  });

  // ── Tests: Actualización de Gym ───────────────────────────────────────────

  describe('PATCH /gyms/:id', () => {
    it('✅ ADMIN puede actualizar SU propio gimnasio', async () => {
      const res = await request(app.getHttpServer())
        .patch(`/gyms/${gymAId}`)
        .set('Authorization', `Bearer ${adminGymAToken}`)
        .send({ welcomeMessage: 'Bienvenido a Gym Alpha!' });

      expect(res.status).toBe(200);
      expect(res.body.welcomeMessage).toBe('Bienvenido a Gym Alpha!');
    });

    it('❌ ADMIN de Gym A NO puede actualizar Gym B (403 - Multi-Tenant Isolation)', async () => {
      /**
       * REGLA 3 (CRÍTICA): La mutación de datos de un gimnasio ajeno debe
       * ser absolutamente bloqueada. Un Admin de Gym A nunca puede
       * alterar la configuración, datos o estado de Gym B.
       */
      const res = await request(app.getHttpServer())
        .patch(`/gyms/${gymBId}`)
        .set('Authorization', `Bearer ${adminGymAToken}`)
        .send({ welcomeMessage: 'Hack desde Gym A!' });

      expect(res.status).toBe(403);
    });
  });

  // ── Tests: Generación de Invite Link ─────────────────────────────────────

  describe('POST /auth/generate-invite-link', () => {
    it('✅ SUPER_ADMIN puede generar invite link para cualquier gym', async () => {
      /**
       * REGLA 7 / REGLA 9: El invite link es el mecanismo de onboarding oficial.
       * Solo roles con permisos administrativos pueden generarlo.
       */
      const res = await request(app.getHttpServer())
        .post('/auth/generate-invite-link')
        .set('Authorization', `Bearer ${superAdminToken}`)
        .send({ gymId: gymAId });

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('token');
      expect(typeof res.body.token).toBe('string');
      expect(res.body.token.length).toBeGreaterThan(10);
    });
  });
});

// ── Helpers ───────────────────────────────────────────────────────────────────

async function bootstrapSuperAdmin(
  app: INestApplication,
  dataSource: DataSource,
): Promise<string> {
  const passwordHash = await bcrypt.hash('SuperAdmin123!', 10);

  // Crear SA sin gym (los SA no pertenecen a un gym específico)
  await dataSource.query(
    `INSERT INTO users ("firstName", "lastName", email, "passwordHash", role, "isActive", "paysMembership")
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     ON CONFLICT (email) DO NOTHING`,
    ['Super', 'Admin', 'sa.gyms@example.com', passwordHash, 'super_admin', true, false],
  );

  const loginRes = await request(app.getHttpServer())
    .post('/auth/login')
    .send({ email: 'sa.gyms@example.com', password: 'SuperAdmin123!' });

  return loginRes.body.access_token;
}

async function bootstrapAdmin(
  app: INestApplication,
  dataSource: DataSource,
  gymId: string,
  email: string,
): Promise<string> {
  const passwordHash = await bcrypt.hash('Admin123!', 10);

  await dataSource.query(
    `INSERT INTO users ("firstName", "lastName", email, "passwordHash", role, "isActive", "paysMembership", "gymId")
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     ON CONFLICT (email) DO NOTHING`,
    ['Admin', 'Gym', email, passwordHash, 'admin', true, false, gymId],
  );

  const loginRes = await request(app.getHttpServer())
    .post('/auth/login')
    .send({ email, password: 'Admin123!' });

  return loginRes.body.access_token;
}
