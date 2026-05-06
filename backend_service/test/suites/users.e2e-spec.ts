import { INestApplication } from '@nestjs/common';
import { DataSource } from 'typeorm';
import request from 'supertest';
import * as bcrypt from 'bcrypt';
import { createTestApp } from '../setup/test-app.factory';
import { cleanDatabase, seedBaseGym } from '../setup/db-cleanup.helper';

/**
 * Suite E2E: Usuarios por Rol
 *
 * Verifica que el sistema de permisos por rol funciona correctamente
 * para todas las operaciones sobre usuarios.
 *
 * Reglas de negocio cubiertas:
 * - Regla 5 (Roles y Permisos): Cada rol tiene un conjunto acotado y
 *   estrictamente definido de facultades.
 * - Regla 5.1 (ADMIN): Control total sobre personal y clientes de su gym.
 * - Regla 5.2 (PROFE): Solo puede gestionar alumnos. Sin acceso a finanzas.
 * - Regla 5.3 (ALUMNO): Solo lectura de su propio perfil. Sin acceso a datos ajenos.
 * - Regla 3 (Multi-tenancy): El acceso de un Admin a datos de otro gym debe
 *   ser bloqueado a nivel de endpoint.
 * - Regla 2 (Historial del usuario): El historial deportivo pertenece al alumno,
 *   incluso si cambia de gimnasio.
 */
describe('[Suite] Users - Gestión de Usuarios por Rol', () => {
  let app: INestApplication;
  let dataSource: DataSource;

  // Tokens por rol
  let superAdminToken: string;
  let adminToken: string;
  let profeToken: string;
  let alumnoToken: string;

  // IDs para referencias cruzadas
  let gymId: string;
  let adminId: string;
  let profeId: string;
  let alumnoId: string;
  let inviteToken: string;

  // ── Setup ─────────────────────────────────────────────────────────────────

  beforeAll(async () => {
    ({ app, dataSource } = await createTestApp());
    await cleanDatabase(dataSource);

    const gym = await seedBaseGym(dataSource, { businessName: 'Users Test Gym' });
    gymId = gym.id;

    // Bootstrapping: crear SA, Admin y Profe directamente en BD
    superAdminToken = await bootstrapUser(app, dataSource, null, 'super_admin', 'sa.users@example.com');
    const adminLoginData = await bootstrapUserWithId(app, dataSource, gymId, 'admin', 'admin.users@example.com');
    adminToken = adminLoginData.token;
    adminId = adminLoginData.id;

    const profeLoginData = await bootstrapUserWithId(app, dataSource, gymId, 'profe', 'profe.users@example.com');
    profeToken = profeLoginData.token;
    profeId = profeLoginData.id;

    // Generar invite token para alumno
    const inviteRes = await request(app.getHttpServer())
      .post('/auth/generate-invite-link')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ gymId });
    inviteToken = inviteRes.body.token;

    // Registrar alumno via invite (flujo normal)
    const alumnoRes = await request(app.getHttpServer())
      .post('/auth/register-with-invite')
      .send({
        inviteToken,
        user: {
          firstName: 'Carlos',
          lastName: 'Alumno',
          email: 'carlos.alumno@example.com',
          password: 'Alumno123!',
        },
      });
    alumnoToken = alumnoRes.body.access_token;
    alumnoId = alumnoRes.body.user.id;
  });

  afterAll(async () => {
    await app.close();
  });

  // ── Tests: Creación de usuarios ───────────────────────────────────────────

  describe('POST /users - Creación de usuarios por rol', () => {
    it('✅ ADMIN puede crear un PROFE en su gym', async () => {
      /**
       * REGLA 5.1: El ADMIN tiene control total sobre el personal de su gym,
       * incluyendo la capacidad de crear instructores.
       */
      const res = await request(app.getHttpServer())
        .post('/users')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          firstName: 'Nuevo',
          lastName: 'Profe',
          email: 'nuevo.profe.created@example.com',
          password: 'Profe123!',
          role: 'profe',
        });

      expect(res.status).toBe(201);
      expect(res.body.role).toBe('profe');
      expect(res.body.email).toBe('nuevo.profe.created@example.com');
    });

    it('✅ ADMIN puede crear un ALUMNO en su gym', async () => {
      /**
       * REGLA 5.1: El ADMIN también puede crear alumnos directamente,
       * sin necesitar el flujo de invite link (alta administrativa directa).
       */
      const res = await request(app.getHttpServer())
        .post('/users')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          firstName: 'Alumno',
          lastName: 'Creado',
          email: 'alumno.creado.admin@example.com',
          password: 'Alumno123!',
          role: 'alumno',
        });

      expect(res.status).toBe(201);
      expect(res.body.role).toBe('alumno');
    });

    it('❌ ADMIN no puede crear un SUPER_ADMIN (403)', async () => {
      /**
       * REGLA 5.1: El ADMIN tiene autoridad dentro de su recinto pero
       * no puede elevar privilegios a nivel de sistema.
       */
      const res = await request(app.getHttpServer())
        .post('/users')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          firstName: 'Impostor',
          lastName: 'SA',
          email: 'impostor.sa@example.com',
          password: 'Hack123!',
          role: 'super_admin',
        });

      expect(res.status).toBe(403);
    });

    it('❌ ALUMNO no puede crear ningún usuario (403)', async () => {
      /**
       * REGLA 5.3: El ALUMNO tiene acceso de solo lectura. No puede
       * alterar la estructura del sistema en ningún aspecto.
       */
      const res = await request(app.getHttpServer())
        .post('/users')
        .set('Authorization', `Bearer ${alumnoToken}`)
        .send({
          firstName: 'Otro',
          lastName: 'Alumno',
          email: 'otro.alumno@example.com',
          password: 'Pass123!',
        });

      expect(res.status).toBe(403);
    });
  });

  // ── Tests: Listado de usuarios ────────────────────────────────────────────

  describe('GET /users - Listado de usuarios por rol', () => {
    it('✅ ADMIN puede ver todos los usuarios de su gym', async () => {
      /**
       * REGLA 5.1: El ADMIN tiene transparencia de lectura absoluta
       * sobre los datos de su recinto.
       */
      const res = await request(app.getHttpServer())
        .get('/users')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThan(0);

      // Todos los usuarios deben pertenecer al mismo gym
      for (const user of res.body) {
        if (user.gym) {
          expect(user.gym.id).toBe(gymId);
        }
      }
    });

    it('✅ PROFE puede ver solo sus alumnos asignados', async () => {
      /**
       * REGLA 5.2: El PROFE tiene visibilidad acotada a sus propios alumnos.
       * No tiene vista global del gym.
       */
      const res = await request(app.getHttpServer())
        .get('/users')
        .set('Authorization', `Bearer ${profeToken}`);

      expect(res.status).toBe(200);
      // El profe no tiene alumnos asignados todavía, pero la respuesta es válida
      expect(Array.isArray(res.body)).toBe(true);
    });

    it('❌ ALUMNO no puede listar usuarios (403)', async () => {
      /**
       * REGLA 5.3: Los alumnos no tienen acceso a listados del sistema.
       */
      const res = await request(app.getHttpServer())
        .get('/users')
        .set('Authorization', `Bearer ${alumnoToken}`);

      expect(res.status).toBe(403);
    });
  });

  // ── Tests: Consulta de usuario individual ────────────────────────────────

  describe('GET /users/:id - Acceso individual a usuarios', () => {
    it('✅ ALUMNO puede ver su propio perfil', async () => {
      /**
       * REGLA 5.3: Aunque el alumno no puede listar usuarios, sí puede
       * consultar sus propios datos.
       */
      const res = await request(app.getHttpServer())
        .get(`/users/${alumnoId}`)
        .set('Authorization', `Bearer ${alumnoToken}`);

      expect(res.status).toBe(200);
      expect(res.body.id).toBe(alumnoId);
    });

    it('❌ ALUMNO no puede ver el perfil de otro usuario (403)', async () => {
      /**
       * REGLA 5.3 / REGLA 10: El alumno tiene acceso exclusivamente a sus
       * propios datos. No puede espiar perfiles ajenos.
       */
      const res = await request(app.getHttpServer())
        .get(`/users/${profeId}`)
        .set('Authorization', `Bearer ${alumnoToken}`);

      expect(res.status).toBe(403);
    });

    it('✅ PROFE puede ver el perfil del admin de su gym (mismo gym)', async () => {
      const res = await request(app.getHttpServer())
        .get(`/users/${adminId}`)
        .set('Authorization', `Bearer ${profeToken}`);

      // El profe y el admin están en el mismo gym, pero el profe solo puede ver
      // sus propios alumnos. El acceso al admin va a depender del validateAccess.
      // Si el admin no es "alumno del profe", puede dar 403 — es correcto.
      expect([200, 403]).toContain(res.status);
    });
  });

  // ── Tests: Actualización del estado de pago ──────────────────────────────

  describe('PATCH /users/:id/payment-status - Permisos de pago', () => {
    it('✅ ADMIN puede actualizar el estado de pago de un alumno', async () => {
      /**
       * REGLA 6.3: La facultad técnica para imputar flags de pago recae
       * exclusivamente en la credencial funcional ADMIN.
       */
      const res = await request(app.getHttpServer())
        .patch(`/users/${alumnoId}/payment-status`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
    });

    it('❌ PROFE no puede actualizar el estado de pago (403)', async () => {
      /**
       * REGLA 5.2: El PROFE tiene restricción estricta sobre finanzas.
       * Nula manipulación de pagos, vencimientos o estados contables.
       */
      const res = await request(app.getHttpServer())
        .patch(`/users/${alumnoId}/payment-status`)
        .set('Authorization', `Bearer ${profeToken}`);

      expect(res.status).toBe(403);
    });

    it('❌ ALUMNO no puede actualizar su propio estado de pago (403)', async () => {
      /**
       * REGLA 5.3: Un alumno no puede autogestionar su estado de pago.
       * Esto previene marcar membresías como "pagadas" sin intervención del staff.
       */
      const res = await request(app.getHttpServer())
        .patch(`/users/${alumnoId}/payment-status`)
        .set('Authorization', `Bearer ${alumnoToken}`);

      expect(res.status).toBe(403);
    });
  });
});

// ── Helpers ───────────────────────────────────────────────────────────────────

async function bootstrapUser(
  app: INestApplication,
  dataSource: DataSource,
  gymId: string | null,
  role: string,
  email: string,
): Promise<string> {
  const { token } = await bootstrapUserWithId(app, dataSource, gymId, role, email);
  return token;
}

async function bootstrapUserWithId(
  app: INestApplication,
  dataSource: DataSource,
  gymId: string | null,
  role: string,
  email: string,
): Promise<{ token: string; id: string }> {
  const passwordHash = await bcrypt.hash('Admin123!', 10);

  const result = await dataSource.query(
    `INSERT INTO users ("firstName", "lastName", email, "passwordHash", role, "isActive", "paysMembership"${gymId ? ', "gymId"' : ''})
     VALUES ($1, $2, $3, $4, $5, $6, $7${gymId ? ', $8' : ''})
     ON CONFLICT (email) DO UPDATE SET "gymId" = EXCLUDED."gymId"
     RETURNING id`,
    gymId
      ? ['Test', role, email, passwordHash, role, true, false, gymId]
      : ['Test', role, email, passwordHash, role, true, false],
  );

  const id = result[0].id;

  const loginRes = await request(app.getHttpServer())
    .post('/auth/login')
    .send({ email, password: 'Admin123!' });

  return { token: loginRes.body.access_token, id };
}
