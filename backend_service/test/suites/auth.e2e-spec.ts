import { INestApplication } from '@nestjs/common';
import { DataSource } from 'typeorm';
import request from 'supertest';
import * as bcrypt from 'bcrypt';
import { createTestApp } from '../setup/test-app.factory';
import { cleanDatabase, seedBaseGym } from '../setup/db-cleanup.helper';

/**
 * Suite E2E: Autenticación y Gestión de Acceso
 *
 * Cubre todos los flujos de acceso al sistema:
 * - Registro vía invite link / QR
 * - Login con credenciales
 * - Perfil autenticado
 * - Consulta de info del gym por invite token (pantalla previa al registro)
 * - Activación de cuenta por link de email (admin crea usuario → usuario activa)
 * - Reset de contraseña por link de email (flujo completo)
 * - Cambio de contraseña estando logueado
 *
 * Reglas de negocio cubiertas:
 * - Regla 7 (Onboarding): Canal único de ingreso = QR / invite link.
 * - Regla 9 (Modelo de Acceso): Imposible acceder sin token de dominio de gym.
 * - Regla 10 (DO NOT BREAK): Blindaje del JWT y seguridad de sesiones.
 */
describe('[Suite] Auth - Autenticación y Gestión de Acceso', () => {
  let app: INestApplication;
  let dataSource: DataSource;

  let gymId: string;
  let inviteToken: string;

  // Usuario registrado para tests de login/perfil/password
  let registeredUserEmail: string;
  let accessToken: string;
  let registeredUserId: string;

  // Admin para operaciones de generación de tokens
  let adminToken: string;
  let adminUserId: string;

  // ── Setup ─────────────────────────────────────────────────────────────────

  beforeAll(async () => {
    ({ app, dataSource } = await createTestApp());
    await cleanDatabase(dataSource);

    const gym = await seedBaseGym(dataSource, { businessName: 'Auth Test Gym' });
    gymId = gym.id;

    // Crear super admin para bootstrapping (no hay endpoint público para esto)
    const saToken = await bootstrapSuperAdmin(app, dataSource, gymId);

    // Generar invite token del gym (usado en varios tests)
    const inviteRes = await request(app.getHttpServer())
      .post('/auth/generate-invite-link')
      .set('Authorization', `Bearer ${saToken}`)
      .send({ gymId });

    inviteToken = inviteRes.body.token;
    expect(inviteToken).toBeDefined();

    // Crear ADMIN del gym para tests de activate/reset
    adminUserId = await bootstrapAdmin(dataSource, gymId);
    const adminLoginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'admin.auth.test@example.com', password: 'Admin123!' });
    adminToken = adminLoginRes.body.access_token;
  });

  afterAll(async () => {
    await app.close();
  });

  // ── 1. Invite Link: Consulta de info del gym (pantalla pre-registro) ──────

  describe('GET /auth/invite-info/:token - Info del gym por token de invitación', () => {
    it('✅ Devuelve el nombre del gym para un token válido', async () => {
      /**
       * REGLA 7 / REGLA 9: Antes de mostrar el formulario de registro,
       * la app consulta qué gym está asociado al token del QR.
       * Este es el endpoint público que alimenta la pantalla de bienvenida.
       */
      const res = await request(app.getHttpServer())
        .get(`/auth/invite-info/${inviteToken}`);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('gymName');
      expect(res.body.gymName).toBe('Auth Test Gym');
      expect(res.body).toHaveProperty('role');
      // El rol del invite link es siempre ALUMNO para QR públicos
      expect(res.body.role).toBe('alumno');
    });

    it('❌ Retorna 400 con token de invitación inválido', async () => {
      const res = await request(app.getHttpServer())
        .get('/auth/invite-info/token.completamente.falso.xyz');

      expect(res.status).toBe(400);
    });
  });

  // ── 2. Registro con Invite Link / QR ─────────────────────────────────────

  describe('POST /auth/register-with-invite - Registro vía QR / invite link', () => {
    it('✅ Registra un alumno correctamente con token de invitación válido', async () => {
      /**
       * REGLA 7 / REGLA 9: El único canal de onboarding para alumnos es
       * vía invite token. Sin él, la puerta está cerrada.
       *
       * Este es el mismo flujo que se ejecuta al escanear el QR del gym.
       */
      const res = await request(app.getHttpServer())
        .post('/auth/register-with-invite')
        .send({
          inviteToken,
          user: {
            firstName: 'Juan',
            lastName: 'Pérez',
            email: 'juan.perez.auth@example.com',
            password: 'Password123!',
          },
        });

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('access_token');
      expect(res.body.user).toHaveProperty('id');
      expect(res.body.user.role).toBe('alumno');
      // El alumno queda ligado al gym del QR
      expect(res.body.user.gym?.id ?? res.body.user.gymId).toBeDefined();

      registeredUserEmail = 'juan.perez.auth@example.com';
      registeredUserId = res.body.user.id;
    });

    it('✅ El mismo token de QR puede usarse para registrar múltiples alumnos', async () => {
      /**
       * El QR del gym no es de un solo uso — varios alumnos lo escanean.
       */
      const res = await request(app.getHttpServer())
        .post('/auth/register-with-invite')
        .send({
          inviteToken,
          user: {
            firstName: 'María',
            lastName: 'García',
            email: 'maria.garcia.auth@example.com',
            password: 'Password123!',
          },
        });

      expect(res.status).toBe(201);
      expect(res.body.user.role).toBe('alumno');
    });

    it('❌ Rechaza el registro sin token de invitación (401)', async () => {
      /**
       * REGLA 9 (CRÍTICA): No existe registro auto-gestionado sin código de sede.
       * Intentar registrarse directamente sin QR debe ser bloqueado.
       */
      const res = await request(app.getHttpServer())
        .post('/auth/register-with-invite')
        .send({
          // Sin inviteToken
          user: {
            firstName: 'Intento',
            lastName: 'Sin Token',
            email: 'sin.token.auth@example.com',
            password: 'Password123!',
          },
        });

      expect(res.status).toBe(401);
    });

    it('❌ Rechaza el registro con token inválido (400)', async () => {
      /**
       * REGLA 9: Un token corrupto o falsificado es rechazado inmediatamente.
       */
      const res = await request(app.getHttpServer())
        .post('/auth/register-with-invite')
        .send({
          inviteToken: 'token.completamente.falso.xyz',
          user: {
            firstName: 'Hacker',
            lastName: 'Ejemplo',
            email: 'hacker.auth@example.com',
            password: 'Password123!',
          },
        });

      expect(res.status).toBe(400);
    });

    it('❌ El rol siempre es ALUMNO sin importar lo que se envíe (anti-privilege-escalation)', async () => {
      /**
       * REGLA 9 / REGLA 5.3: El backend fuerza rol ALUMNO en registerWithInvite,
       * sin importar lo que el cliente intente enviar en el body.
       * Previene escalada de privilegios vía QR manipulado.
       */
      const res = await request(app.getHttpServer())
        .post('/auth/register-with-invite')
        .send({
          inviteToken,
          user: {
            firstName: 'Trampa',
            lastName: 'Rol',
            email: 'trampa.rol.auth@example.com',
            password: 'Password123!',
            role: 'admin', // Intento de escalada de privilegios
          },
        });

      expect(res.status).toBe(201);
      expect(res.body.user.role).toBe('alumno'); // Backend fuerza ALUMNO siempre
    });
  });

  // ── 3. Login ──────────────────────────────────────────────────────────────

  describe('POST /auth/login - Login con credenciales locales', () => {
    it('✅ Login exitoso con credenciales correctas', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: registeredUserEmail, password: 'Password123!' });

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('access_token');
      expect(res.body.user.email).toBe(registeredUserEmail);

      accessToken = res.body.access_token;
    });

    it('❌ Login rechazado con contraseña incorrecta (401)', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: registeredUserEmail, password: 'ContraseñaIncorrecta' });

      expect(res.status).toBe(401);
    });

    it('❌ Login rechazado con email inexistente (401)', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: 'noexiste@example.com', password: 'Password123!' });

      expect(res.status).toBe(401);
    });
  });

  // ── 4. Perfil autenticado ─────────────────────────────────────────────────

  describe('GET /auth/profile - Perfil del usuario autenticado', () => {
    it('✅ Devuelve el perfil del usuario con token válido', async () => {
      const res = await request(app.getHttpServer())
        .get('/auth/profile')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('email', registeredUserEmail);
      expect(res.body).toHaveProperty('role', 'alumno');
    });

    it('❌ Devuelve 401 sin token de autorización', async () => {
      /**
       * REGLA 10: Cualquier endpoint protegido sin JWT debe rechazar.
       */
      const res = await request(app.getHttpServer()).get('/auth/profile');
      expect(res.status).toBe(401);
    });

    it('❌ Devuelve 401 con token malformado', async () => {
      const res = await request(app.getHttpServer())
        .get('/auth/profile')
        .set('Authorization', 'Bearer token.invalido.xyz');

      expect(res.status).toBe(401);
    });
  });

  // ── 5. Activación de cuenta por link de email ─────────────────────────────

  describe('POST /auth/activate-account - Activación de cuenta vía link', () => {
    /**
     * FLUJO: Admin crea usuario inactivo → sistema genera token de activación
     * → usuario recibe email con link → usuario setea su contraseña → cuenta activa
     *
     * En producción el token va en el email. En tests, lo generamos directamente.
     */
    let activationToken: string;
    let inactiveUserId: string;

    beforeAll(async () => {
      // Crear un usuario inactivo directamente en la BD (sin password aún)
      // Esto simula lo que hace el admin cuando "crea" un alumno/profe
      const result = await dataSource.query(
        `INSERT INTO users ("firstName", "lastName", email, "passwordHash", role, "isActive", "paysMembership", "gymId")
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING id`,
        ['Carlos', 'Pendiente', 'carlos.pending@example.com', null, 'alumno', false, false, gymId],
      );
      inactiveUserId = result[0].id;

      // Admin genera el token de activación para el usuario
      const tokenRes = await request(app.getHttpServer())
        .post('/auth/generate-activation-link')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ userId: inactiveUserId });

      expect(tokenRes.status).toBe(201);
      activationToken = tokenRes.body.token;
    });

    it('✅ El admin puede generar un link de activación para un usuario inactivo', async () => {
      // Verificar que el token fue generado y guardado en la BD
      const [user] = await dataSource.query(
        `SELECT "activationTokenHash", "activationTokenExpires", "isActive"
         FROM users WHERE id = $1`,
        [inactiveUserId],
      );

      expect(user.activationTokenHash).toBeDefined();
      expect(user.activationTokenHash).not.toBeNull();
      expect(user.isActive).toBe(false); // Aún inactivo
    });

    it('✅ El usuario activa su cuenta con el token del link', async () => {
      /**
       * El usuario hace click en el link del email (o pega el token)
       * y setea su contraseña inicial. La cuenta queda activa.
       */
      const res = await request(app.getHttpServer())
        .post('/auth/activate-account')
        .send({
          token: activationToken,
          password: 'NuevaContrasena123!',
        });

      expect(res.status).toBe(201);

      // Verificar que la cuenta quedó activa en la BD
      const [user] = await dataSource.query(
        `SELECT "isActive", "activationTokenHash" FROM users WHERE id = $1`,
        [inactiveUserId],
      );

      expect(user.isActive).toBe(true);
      expect(user.activationTokenHash).toBeNull(); // Token consumido
    });

    it('✅ El usuario puede loguearse luego de activar su cuenta', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: 'carlos.pending@example.com', password: 'NuevaContrasena123!' });

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('access_token');
    });

    it('❌ El token de activación ya usado no puede reutilizarse', async () => {
      /**
       * El token es de un solo uso. Una vez consumido, intenta usarlo de nuevo
       * y debe ser rechazado.
       */
      const res = await request(app.getHttpServer())
        .post('/auth/activate-account')
        .send({
          token: activationToken, // Token ya consumido
          password: 'OtraContrasena456!',
        });

      expect([400, 401]).toContain(res.status);
    });

    it('❌ Falla con token de activación inválido/falso (401)', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/activate-account')
        .send({ token: 'token_falso_activacion_xyz', password: 'Pass123!' });

      expect([400, 401]).toContain(res.status);
    });
  });

  // ── 6. Reset de contraseña por link de email ──────────────────────────────

  describe('POST /auth/reset-password - Recuperación de contraseña', () => {
    /**
     * FLUJO: Usuario olvidó su contraseña → admin/sistema genera token de reset
     * → usuario recibe email con link → usuario setea nueva contraseña
     * → puede loguearse con la nueva contraseña
     *
     * Este era el flujo que se reportó como "no funcionaba". El test lo verifica
     * de extremo a extremo.
     */
    let resetToken: string;
    const targetEmail = 'juan.perez.auth@example.com';
    let targetUserId: string;

    beforeAll(async () => {
      // Obtener el ID del usuario registrado anteriormente
      const [user] = await dataSource.query(
        `SELECT id FROM users WHERE email = $1`,
        [targetEmail],
      );
      targetUserId = user.id;

      // Generar token de reset (requiere autenticación del admin)
      const tokenRes = await request(app.getHttpServer())
        .post('/auth/generate-reset-link')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ userId: targetUserId });

      expect(tokenRes.status).toBe(201);
      resetToken = tokenRes.body.token;
    });

    it('✅ El admin puede generar un link de reset de contraseña', async () => {
      // El token debe estar guardado en la BD con expiración
      const [user] = await dataSource.query(
        `SELECT "resetTokenHash", "resetTokenExpires" FROM users WHERE id = $1`,
        [targetUserId],
      );

      expect(user.resetTokenHash).toBeDefined();
      expect(user.resetTokenHash).not.toBeNull();

      // La expiración es de 30 minutos
      const expires = new Date(user.resetTokenExpires);
      const now = new Date();
      const diffMinutes = (expires.getTime() - now.getTime()) / (1000 * 60);
      expect(diffMinutes).toBeGreaterThan(0);
      expect(diffMinutes).toBeLessThanOrEqual(31);
    });

    it('✅ El usuario resetea su contraseña con el token del link', async () => {
      /**
       * El usuario hace click en el link del email, ingresa su nueva contraseña.
       * El sistema la actualiza y revoca todos los refresh tokens activos.
       */
      const res = await request(app.getHttpServer())
        .post('/auth/reset-password')
        .send({
          token: resetToken,
          password: 'NuevaContrasena999!',
        });

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('message', 'Password reset successful');

      // El resetTokenHash debe borrarse (token consumido)
      const [user] = await dataSource.query(
        `SELECT "resetTokenHash" FROM users WHERE id = $1`,
        [targetUserId],
      );
      expect(user.resetTokenHash).toBeNull();
    });

    it('✅ El usuario puede loguearse con la nueva contraseña después del reset', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: targetEmail, password: 'NuevaContrasena999!' });

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('access_token');
    });

    it('❌ La contraseña antigua ya no funciona después del reset', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: targetEmail, password: 'Password123!' });

      expect(res.status).toBe(401);
    });

    it('❌ El token de reset ya usado no puede reutilizarse', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/reset-password')
        .send({
          token: resetToken, // Token ya consumido
          password: 'OtraContrasena777!',
        });

      expect([400, 401]).toContain(res.status);
    });

    it('❌ Token de reset inválido/falso es rechazado (401)', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/reset-password')
        .send({ token: 'token_falso_reset_xyz', password: 'Pass123!' });

      expect([400, 401]).toContain(res.status);
    });
  });

  // ── 7. Cambio de contraseña estando logueado ──────────────────────────────

  describe('POST /auth/change-password - Cambio de contraseña autenticado', () => {
    it('✅ Usuario logueado puede cambiar su contraseña', async () => {
      /**
       * A diferencia del reset (que requiere el token del email),
       * este flujo requiere estar autenticado y conocer la contraseña actual.
       */

      // Juan ya reseteó su contraseña a 'NuevaContrasena999!', así que usamos esa
      const loginRes = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: 'juan.perez.auth@example.com', password: 'NuevaContrasena999!' });

      const userToken = loginRes.body.access_token;

      const res = await request(app.getHttpServer())
        .post('/auth/change-password')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          currentPassword: 'NuevaContrasena999!',
          newPassword: 'ContrasenaFinal123!',
        });

      expect([200, 201]).toContain(res.status);
    });

    it('❌ No puede cambiar contraseña con contraseña actual incorrecta', async () => {
      const loginRes = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: 'juan.perez.auth@example.com', password: 'ContrasenaFinal123!' });

      const userToken = loginRes.body.access_token;

      const res = await request(app.getHttpServer())
        .post('/auth/change-password')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          currentPassword: 'ContraseñaIncorrecta',
          newPassword: 'OtroIntento123!',
        });

      expect([400, 401, 403]).toContain(res.status);
    });

    it('❌ No puede cambiar contraseña sin estar autenticado (401)', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/change-password')
        .send({
          currentPassword: 'ContrasenaFinal123!',
          newPassword: 'Intento123!',
        });

      expect(res.status).toBe(401);
    });
  });
});

// ── Helpers ───────────────────────────────────────────────────────────────────

/**
 * Crea un Super Admin directamente en la BD (sin endpoint público)
 * y retorna su access_token para operaciones de setup.
 */
async function bootstrapSuperAdmin(
  app: INestApplication,
  dataSource: DataSource,
  gymId: string,
): Promise<string> {
  const passwordHash = await bcrypt.hash('SuperAdmin123!', 10);

  await dataSource.query(
    `INSERT INTO users
       ("firstName", "lastName", email, "passwordHash", role, "isActive", "paysMembership", "gymId")
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     ON CONFLICT (email) DO NOTHING`,
    ['Super', 'Admin', 'super.admin.auth@example.com', passwordHash, 'super_admin', true, false, gymId],
  );

  const loginRes = await request(app.getHttpServer())
    .post('/auth/login')
    .send({ email: 'super.admin.auth@example.com', password: 'SuperAdmin123!' });

  expect(loginRes.status).toBe(201);
  return loginRes.body.access_token;
}

/**
 * Crea un ADMIN del gym en la BD y retorna su userId.
 * (El token se obtiene via login después.)
 */
async function bootstrapAdmin(
  dataSource: DataSource,
  gymId: string,
): Promise<string> {
  const passwordHash = await bcrypt.hash('Admin123!', 10);

  const result = await dataSource.query(
    `INSERT INTO users
       ("firstName", "lastName", email, "passwordHash", role, "isActive", "paysMembership", "gymId")
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     ON CONFLICT (email) DO UPDATE SET "gymId" = EXCLUDED."gymId"
     RETURNING id`,
    ['Admin', 'Auth', 'admin.auth.test@example.com', passwordHash, 'admin', true, false, gymId],
  );

  return result[0].id;
}
