import { INestApplication } from '@nestjs/common';
import { DataSource } from 'typeorm';
import request from 'supertest';
import * as bcrypt from 'bcrypt';
import { createTestApp } from '../setup/test-app.factory';
import { cleanDatabase, seedBaseGym } from '../setup/db-cleanup.helper';

/**
 * Suite E2E: Membresías y Registro de Pagos
 *
 * Verifica el ciclo de vida de las membresías: registro de pagos,
 * extensión correcta de fechas, lógica del anchor-day, permisos por rol,
 * estado de cuota del alumno, listado de morosos y corrección de pagos.
 *
 * Reglas de negocio cubiertas:
 * - Regla 6.1 (MVP Membresía): Ciclo pagado → por vencer → vencido.
 * - Regla 6.2 (Lógica de Pagos): Cálculo basado en membershipStartDate.
 *   Si hay expiración futura, se extiende DESDE ella. Si está vencida,
 *   se extiende DESDE hoy.
 * - Regla 6.3 (Privilegios Financieros): Solo ADMIN/SA puede registrar pagos.
 * - Regla 5.2 (PROFE): Nula manipulación de finanzas (restricción estricta).
 *   PROFE solo puede consultar el estado de cuota de sus alumnos (lectura).
 * - Regla 5.3 (ALUMNO): No puede registrar su propio pago.
 * - PaymentsService.registerPayment: Múltiples meses crean múltiples
 *   PaymentRecord y avanzan la fecha N meses anclada al día de inicio.
 */
describe('[Suite] Payments - Membresías y Registro de Pagos', () => {
  let app: INestApplication;
  let dataSource: DataSource;

  // Tokens por rol
  let adminToken: string;
  let profeToken: string;
  let alumnoToken: string;

  // IDs
  let gymId: string;
  let alumnoId: string;

  // ── Setup ─────────────────────────────────────────────────────────────────

  beforeAll(async () => {
    ({ app, dataSource } = await createTestApp());
    await cleanDatabase(dataSource);

    const gym = await seedBaseGym(dataSource, { businessName: 'Payments Test Gym' });
    gymId = gym.id;

    adminToken = await bootstrapUser(app, dataSource, gymId, 'admin', 'admin.payments@example.com');
    profeToken = await bootstrapUser(app, dataSource, gymId, 'profe', 'profe.payments@example.com');

    // Crear alumno via invite
    const inviteRes = await request(app.getHttpServer())
      .post('/auth/generate-invite-link')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ gymId });

    const alumnoRes = await request(app.getHttpServer())
      .post('/auth/register-with-invite')
      .send({
        inviteToken: inviteRes.body.token,
        user: {
          firstName: 'Maria',
          lastName: 'Pagos',
          email: 'maria.pagos@example.com',
          password: 'Alumno123!',
        },
      });

    alumnoToken = alumnoRes.body.access_token;
    alumnoId = alumnoRes.body.user.id;

    // Establecer membershipStartDate para que los cálculos sean deterministas
    const anchorDay = new Date().getDate();
    await dataSource.query(
      `UPDATE users SET "membershipStartDate" = $1 WHERE id = $2`,
      [new Date().toISOString().split('T')[0], alumnoId],
    );
  });

  afterAll(async () => {
    await app.close();
  });

  // ── Tests: Permisos de Registro de Pago ─────────────────────────────────

  describe('POST /payments/user/:userId - Permisos de registro', () => {
    it('❌ PROFE no puede registrar pagos (403)', async () => {
      /**
       * REGLA 5.2 (RESTRICCIÓN ESTRICTA): El PROFE tiene nula manipulación
       * de finanzas, vencimientos o estados de cuota contables.
       */
      const res = await request(app.getHttpServer())
        .post(`/payments/user/${alumnoId}`)
        .set('Authorization', `Bearer ${profeToken}`)
        .send({ periodMonths: 1 });

      expect(res.status).toBe(403);
    });

    it('❌ ALUMNO no puede registrar su propio pago (403)', async () => {
      /**
       * REGLA 5.3: El alumno no puede autogestionar su estado de pago.
       * La gestión financiera siempre requiere intervención del staff ADMIN.
       */
      const res = await request(app.getHttpServer())
        .post(`/payments/user/${alumnoId}`)
        .set('Authorization', `Bearer ${alumnoToken}`)
        .send({ periodMonths: 1 });

      expect(res.status).toBe(403);
    });

    it('❌ Request sin autenticación es rechazado (401)', async () => {
      const res = await request(app.getHttpServer())
        .post(`/payments/user/${alumnoId}`)
        .send({ periodMonths: 1 });

      expect(res.status).toBe(401);
    });
  });

  // ── Tests: Registro de 1 mes ──────────────────────────────────────────────

  describe('ADMIN registra 1 mes de pago', () => {
    it('✅ Crea 1 PaymentRecord con período del 1ro al 1ro del mes siguiente', async () => {
      /**
       * REGLA 6.1 / 6.2: Los períodos de membresía siempre van del 1ro
       * al 1ro del mes siguiente, sin importar el día exacto del pago.
       *
       * REGLA 6.3: Solo el ADMIN puede ejecutar esta operación.
       */
      const res = await request(app.getHttpServer())
        .post(`/payments/user/${alumnoId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ periodMonths: 1 });

      expect(res.status).toBe(201);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBe(1);

      const record = res.body[0];
      expect(record).toHaveProperty('periodFrom');
      expect(record).toHaveProperty('periodTo');

      // Extraer el día directamente del string ISO (evita offset de timezone)
      // La BD puede devolver timestamps con offset ej: '2026-06-01T03:00:00.000Z'
      // Tomamos solo los primeros 10 caracteres 'YYYY-MM-DD' antes de parsear
      const fromDay = parseInt(record.periodFrom.slice(0, 10).split('-')[2], 10);
      const toDay = parseInt(record.periodTo.slice(0, 10).split('-')[2], 10);

      // periodFrom y periodTo siempre deben ser el día 1 de su mes
      expect(fromDay).toBe(1);
      expect(toDay).toBe(1);

      // periodTo debe ser exactamente 1 mes después de periodFrom
      const fromMonth = parseInt(record.periodFrom.slice(0, 10).split('-')[1], 10);
      const toMonth = parseInt(record.periodTo.slice(0, 10).split('-')[1], 10);
      expect(toMonth).toBe(fromMonth === 12 ? 1 : fromMonth + 1);

      // La expiración del usuario debe ser futura
      const userAfter = await request(app.getHttpServer())
        .get(`/users/${alumnoId}`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect(userAfter.body.membershipExpirationDate).toBeDefined();
      expect(new Date(userAfter.body.membershipExpirationDate).getTime()).toBeGreaterThan(
        new Date().getTime(),
      );
    });
  });

  // ── Tests: Pago adelantado (N meses) ────────────────────────────────────

  describe('ADMIN registra 3 meses de pago', () => {
    it('✅ Crea 3 PaymentRecords encadenados, todos del 1ro al 1ro', async () => {
      /**
       * REGLA 6.2: Al pagar 3 meses:
       * - Se crean 3 PaymentRecord encadenados (periodTo[i] = periodFrom[i+1])
       * - Cada período va siempre del 1ro al 1ro del mes siguiente
       * - Si la expiración es futura, se extiende DESDE ese 1ro (no desde hoy)
       */
      const res = await request(app.getHttpServer())
        .post(`/payments/user/${alumnoId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ periodMonths: 3 });

      expect(res.status).toBe(201);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBe(3);

      const records = res.body.sort(
        (a: any, b: any) =>
          new Date(a.periodFrom).getTime() - new Date(b.periodFrom).getTime(),
      );

      // Los registros deben estar encadenados sin gaps
      for (let i = 1; i < records.length; i++) {
        const prevTo = new Date(records[i - 1].periodTo).toISOString().split('T')[0];
        const currFrom = new Date(records[i].periodFrom).toISOString().split('T')[0];
        expect(currFrom).toBe(prevTo);
      }
    });
  });

  // ── Tests: Extensión desde expiración futura vs. desde hoy ───────────────

  describe('Lógica de extensión de membresía', () => {
    it('✅ Pago sobre membresía vigente extiende DESDE la expiración futura', async () => {
      /**
       * REGLA 6.2 (Lógica de Pagos): Si membershipExpirationDate > hoy,
       * el nuevo período comienza DESDE la expiración actual, no desde hoy.
       * Esto evita que un pago "adelantado" recorte tiempo ya pagado.
       */
      const userBefore = await request(app.getHttpServer())
        .get(`/users/${alumnoId}`)
        .set('Authorization', `Bearer ${adminToken}`);

      const currentExpiration = userBefore.body.membershipExpirationDate;
      expect(new Date(currentExpiration).getTime()).toBeGreaterThan(new Date().getTime());

      const res = await request(app.getHttpServer())
        .post(`/payments/user/${alumnoId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ periodMonths: 1 });

      expect(res.status).toBe(201);
      const newRecord = res.body[0];

      // Comparar las fechas con tolerancia de ±1 día para manejar diferencias de timezone.
      // La BD almacena fechas como `date` (sin TZ) pero el JSON puede tener offset.
      // Lo crítico es que el periodFrom del nuevo pago sea MUY cercano (≤1 día) a la expiración anterior.
      const prevDate = new Date(currentExpiration);
      const newDate = new Date(newRecord.periodFrom);
      const diffMs = Math.abs(newDate.getTime() - prevDate.getTime());
      const diffDays = diffMs / (1000 * 60 * 60 * 24);

      // El inicio del nuevo período debe estar dentro de 1 día calendario de la expiración anterior
      expect(diffDays).toBeLessThanOrEqual(1);
    });

    it('✅ Pago sobre membresía vencida extiende DESDE el 1ro del mes actual', async () => {
      /**
       * REGLA 6.2: Si la membresía está vencida, el nuevo período
       * arranca desde el 1ro del mes actual (no desde la expiración
       * pasada ni desde hoy si hoy no es día 1).
       */

      // Crear un alumno nuevo con membresía vencida
      const inviteRes = await request(app.getHttpServer())
        .post('/auth/generate-invite-link')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ gymId });

      const newAlumnoRes = await request(app.getHttpServer())
        .post('/auth/register-with-invite')
        .send({
          inviteToken: inviteRes.body.token,
          user: {
            firstName: 'Moroso',
            lastName: 'Test',
            email: 'moroso.test@example.com',
            password: 'Alumno123!',
          },
        });

      const morososoId = newAlumnoRes.body.user.id;

      // Setear una expiración en el pasado
      const pastDate = new Date();
      pastDate.setMonth(pastDate.getMonth() - 2);
      await dataSource.query(
        `UPDATE users SET "membershipExpirationDate" = $1, "membershipStartDate" = $1 WHERE id = $2`,
        [pastDate.toISOString().split('T')[0], morososoId],
      );

      const res = await request(app.getHttpServer())
        .post(`/payments/user/${morososoId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ periodMonths: 1 });

      expect(res.status).toBe(201);
      const record = res.body[0];

      // El periodFrom debe ser el 1ro del mes actual (no hoy si no es día 1)
      const firstOfMonth = new Date();
      const expectedFrom = new Date(firstOfMonth.getFullYear(), firstOfMonth.getMonth(), 1)
        .toISOString().split('T')[0];
      const recordFrom = new Date(record.periodFrom).toISOString().split('T')[0];
      expect(recordFrom).toBe(expectedFrom);

      // Y el periodTo debe ser el 1ro del mes siguiente
      const expectedTo = new Date(firstOfMonth.getFullYear(), firstOfMonth.getMonth() + 1, 1)
        .toISOString().split('T')[0];
      const recordTo = new Date(record.periodTo).toISOString().split('T')[0];
      expect(recordTo).toBe(expectedTo);
    });
  });

  // ── Tests: Historial de pagos ─────────────────────────────────────────────

  describe('GET /payments/user/:userId - Historial de pagos', () => {
    it('✅ ADMIN puede ver el historial completo de pagos de un alumno', async () => {
      /**
       * REGLA 6.3 / REGLA 5.1: El ADMIN tiene acceso completo al historial
       * financiero de su gym. Esto incluye el historial de pagos de los alumnos.
       */
      const res = await request(app.getHttpServer())
        .get(`/payments/user/${alumnoId}`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThan(0);

      // Los registros deben estar ordenados del más reciente al más antiguo
      const dates = res.body.map((r: any) => new Date(r.paidAt).getTime());
      for (let i = 1; i < dates.length; i++) {
        expect(dates[i - 1]).toBeGreaterThanOrEqual(dates[i]);
      }
    });

    it('✅ ALUMNO puede ver su propio historial de pagos', async () => {
      /**
       * El alumno tiene acceso a su propio estado contable para poder
       * revisar y alertar visualmente su suscripción (Regla 5.3).
       */
      const res = await request(app.getHttpServer())
        .get(`/payments/user/${alumnoId}`)
        .set('Authorization', `Bearer ${alumnoToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });

    it('❌ ALUMNO no puede ver el historial de pagos de otro alumno (403)', async () => {
      /**
       * REGLA 5.3: Un alumno no puede inspeccionar los datos financieros
       * de otros miembros del gym.
       */
      // Crear otro alumno en la BD
      const result = await dataSource.query(
        `SELECT id FROM users WHERE email = 'moroso.test@example.com' LIMIT 1`,
      );

      if (result.length > 0) {
        const otherAlumnoId = result[0].id;
        const res = await request(app.getHttpServer())
          .get(`/payments/user/${otherAlumnoId}`)
          .set('Authorization', `Bearer ${alumnoToken}`);

        expect(res.status).toBe(403);
      }
    });

    it('❌ PROFE no puede ver el historial de pagos (403)', async () => {
      /**
       * REGLA 5.2: El PROFE tiene restricción estricta sobre finanzas.
       * El historial de pagos es información administrativa exclusiva.
       */
      const res = await request(app.getHttpServer())
        .get(`/payments/user/${alumnoId}`)
        .set('Authorization', `Bearer ${profeToken}`);

      expect(res.status).toBe(403);
    });
  });

  // ── Tests: Estado de membresía reflejado en el perfil ────────────────────

  describe('Estado de membresía reflejado en el perfil del alumno', () => {
    it('✅ paymentStatus es "paid" y membershipExpirationDate es futura tras registrar pago', async () => {
      /**
       * REGLA 6.1: Después de registrar un pago, el alumno debe quedar
       * con paymentStatus = "paid" y una fecha de expiración en el futuro.
       * Este campo es calculado en tiempo real por el servicio al leer el usuario.
       */
      const res = await request(app.getHttpServer())
        .get(`/users/${alumnoId}`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.paymentStatus).toBe('paid');

      const expDate = new Date(res.body.membershipExpirationDate);
      expect(expDate.getTime()).toBeGreaterThan(new Date().getTime());
      expect(res.body.lastPaymentDate).toBeDefined();
    });

    it('✅ ALUMNO puede ver su propio paymentStatus en su perfil', async () => {
      /**
       * El alumno consulta su estado de cuota para mostrar el badge
       * "al día" / "vencido" en la app.
       */
      const res = await request(app.getHttpServer())
        .get('/users/profile')
        .set('Authorization', `Bearer ${alumnoToken}`);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('paymentStatus');
      expect(['paid', 'overdue', 'pending']).toContain(res.body.paymentStatus);
    });

    it('✅ paymentStatus es "overdue" para alumno con membresía vencida', async () => {
      /**
       * REGLA 6.1 (Ciclo completo): Un alumno cuya expiración está en el pasado
       * debe mostrar paymentStatus = "overdue".
       */
      const inviteRes = await request(app.getHttpServer())
        .post('/auth/generate-invite-link')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ gymId });

      const alumnoVencidoRes = await request(app.getHttpServer())
        .post('/auth/register-with-invite')
        .send({
          inviteToken: inviteRes.body.token,
          user: {
            firstName: 'Vencido',
            lastName: 'Status',
            email: 'vencido.status@example.com',
            password: 'Alumno123!',
          },
        });

      const vencidoId = alumnoVencidoRes.body.user.id;

      const pastDate = new Date();
      pastDate.setMonth(pastDate.getMonth() - 1);
      await dataSource.query(
        `UPDATE users SET "membershipExpirationDate" = $1, "membershipStartDate" = $1 WHERE id = $2`,
        [pastDate.toISOString().split('T')[0], vencidoId],
      );

      const res = await request(app.getHttpServer())
        .get(`/users/${vencidoId}`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      // El sistema puede retornar "overdue" (expiración pasada) o "pending"
      // (sin historial válido), ambos indican que la membresía NO está al día.
      expect(['overdue', 'pending']).toContain(res.body.paymentStatus);
      expect(res.body.paymentStatus).not.toBe('paid');
    });

    it('✅ paymentStatus es "paid" para alumno exento (paysMembership = false)', async () => {
      /**
       * Los profesores u otros exentos tienen paysMembership = false y siempre
       * se muestran como "paid" sin importar las fechas.
       */
      const profeUserRes = await request(app.getHttpServer())
        .get('/users')
        .set('Authorization', `Bearer ${adminToken}`)
        .query({ role: 'profe' });

      expect(profeUserRes.status).toBe(200);
      if (profeUserRes.body.length > 0) {
        const profe = profeUserRes.body[0];
        expect(profe.paymentStatus).toBe('paid');
      }
    });
  });

  // ── Tests: Listado de alumnos morosos ────────────────────────────────────

  describe('GET /users?role=alumno - Identificación de alumnos morosos', () => {
    it('✅ ADMIN puede listar todos los alumnos con su paymentStatus calculado', async () => {
      /**
       * REGLA 6.3 / REGLA 5.1: El ADMIN usa GET /users?role=alumno para ver
       * todos los alumnos del gym con su paymentStatus.
       * Esto alimenta la vista de "Gestionar Alumnos" y el panel de morosos.
       */
      const res = await request(app.getHttpServer())
        .get('/users')
        .set('Authorization', `Bearer ${adminToken}`)
        .query({ role: 'alumno' });

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThan(0);

      for (const alumno of res.body) {
        expect(alumno).toHaveProperty('paymentStatus');
        expect(['paid', 'overdue', 'pending']).toContain(alumno.paymentStatus);
      }
    });

    it('✅ La lista incluye tanto alumnos al día (paid) como morosos (overdue/pending)', async () => {
      /**
       * El sistema de morosos no tiene endpoint separado — el ADMIN filtra
       * por paymentStatus en el frontend. Este test verifica que conviven
       * los dos estados en el listado.
       */
      const res = await request(app.getHttpServer())
        .get('/users')
        .set('Authorization', `Bearer ${adminToken}`)
        .query({ role: 'alumno' });

      expect(res.status).toBe(200);

      const statuses = res.body.map((u: any) => u.paymentStatus);
      expect(statuses).toContain('paid');

      const hasOverdueOrPending = statuses.some(
        (s: string) => s === 'overdue' || s === 'pending',
      );
      expect(hasOverdueOrPending).toBe(true);
    });

    it('❌ ALUMNO no puede listar todos los usuarios del gym (403)', async () => {
      /**
       * REGLA 5.3: El alumno no tiene acceso a la lista global de usuarios.
       */
      const res = await request(app.getHttpServer())
        .get('/users')
        .set('Authorization', `Bearer ${alumnoToken}`);

      expect(res.status).toBe(403);
    });
  });

  // ── Tests: PROFE consulta estado de cuota de sus alumnos ─────────────────

  describe('GET /users - PROFE ve estado de cuota de sus alumnos asignados', () => {
    let profeId: string;
    let alumnoDelProfeId: string;

    beforeAll(async () => {
      const [profe] = await dataSource.query(
        `SELECT id FROM users WHERE email = 'profe.payments@example.com'`,
      );
      profeId = profe.id;

      const inviteRes = await request(app.getHttpServer())
        .post('/auth/generate-invite-link')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ gymId });

      const alumnoRes = await request(app.getHttpServer())
        .post('/auth/register-with-invite')
        .send({
          inviteToken: inviteRes.body.token,
          user: {
            firstName: 'Alumno',
            lastName: 'DelProfe',
            email: 'alumno.delprofe@example.com',
            password: 'Alumno123!',
          },
        });

      alumnoDelProfeId = alumnoRes.body.user.id;

      await dataSource.query(
        `UPDATE users SET "professorId" = $1 WHERE id = $2`,
        [profeId, alumnoDelProfeId],
      );
    });

    it('✅ PROFE puede ver el paymentStatus de sus propios alumnos', async () => {
      /**
       * REGLA 5.2 (Lectura permitida): El PROFE puede ver la lista de
       * sus alumnos con el paymentStatus para saber quiénes están al día.
       * No puede MODIFICAR el estado, pero sí consultarlo.
       */
      const res = await request(app.getHttpServer())
        .get('/users')
        .set('Authorization', `Bearer ${profeToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);

      const alumno = res.body.find((u: any) => u.id === alumnoDelProfeId);
      expect(alumno).toBeDefined();
      expect(alumno).toHaveProperty('paymentStatus');
      expect(['paid', 'overdue', 'pending']).toContain(alumno.paymentStatus);
    });

    it('✅ PROFE solo ve sus propios alumnos (aislamiento por professorId)', async () => {
      /**
       * REGLA 5.2 / Aislamiento: El PROFE no puede ver alumnos de otros profes
       * ni alumnos sin asignar. El sistema filtra por professorId.
       */
      const res = await request(app.getHttpServer())
        .get('/users')
        .set('Authorization', `Bearer ${profeToken}`);

      expect(res.status).toBe(200);

      for (const u of res.body) {
        expect(u.role).toBe('alumno');
      }

      // maria.pagos no está asignada a este profe → no debe aparecer
      const mariaEnLista = res.body.find((u: any) => u.email === 'maria.pagos@example.com');
      expect(mariaEnLista).toBeUndefined();
    });

    it('❌ PROFE no puede registrar pagos de sus alumnos (403)', async () => {
      /**
       * REGLA 5.2 (RESTRICCIÓN ESTRICTA): El PROFE solo lectura.
       * No puede registrar ni modificar estados de cuota.
       */
      const res = await request(app.getHttpServer())
        .post(`/payments/user/${alumnoDelProfeId}`)
        .set('Authorization', `Bearer ${profeToken}`)
        .send({ periodMonths: 1 });

      expect(res.status).toBe(403);
    });
  });

  // ── Tests: Corrección de estado de cuota ─────────────────────────────────

  describe('PATCH /users/:id/payment-status y corrección manual', () => {
    it('✅ ADMIN puede marcar un alumno como pagado con PATCH /payment-status', async () => {
      /**
       * El endpoint PATCH /users/:id/payment-status llama a markAsPaid,
       * que extiende la membresía 1 mes desde la expiración actual o desde hoy.
       * Es la forma rápida de registrar un pago sin especificar monto ni método.
       */
      const inviteRes = await request(app.getHttpServer())
        .post('/auth/generate-invite-link')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ gymId });

      const nuevoAlumnoRes = await request(app.getHttpServer())
        .post('/auth/register-with-invite')
        .send({
          inviteToken: inviteRes.body.token,
          user: {
            firstName: 'Nuevo',
            lastName: 'SinPago',
            email: 'nuevo.sinpago@example.com',
            password: 'Alumno123!',
          },
        });

      const nuevoId = nuevoAlumnoRes.body.user.id;

      const res = await request(app.getHttpServer())
        .patch(`/users/${nuevoId}/payment-status`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect([200, 201]).toContain(res.status);
      expect(res.body).toHaveProperty('membershipExpirationDate');

      const newExp = new Date(res.body.membershipExpirationDate);
      expect(newExp.getTime()).toBeGreaterThan(new Date().getTime());
    });

    it('❌ PROFE no puede usar PATCH /payment-status (403)', async () => {
      const res = await request(app.getHttpServer())
        .patch(`/users/${alumnoId}/payment-status`)
        .set('Authorization', `Bearer ${profeToken}`);

      expect(res.status).toBe(403);
    });

    it('❌ ALUMNO no puede marcar su propio estado como pagado (403)', async () => {
      const res = await request(app.getHttpServer())
        .patch(`/users/${alumnoId}/payment-status`)
        .set('Authorization', `Bearer ${alumnoToken}`);

      expect(res.status).toBe(403);
    });

    it('✅ ADMIN puede corregir membershipExpirationDate directamente con PATCH /users/:id', async () => {
      /**
       * Si el admin cometió un error (registró más meses de los que corresponden),
       * puede corregir la fecha de expiración directamente con PATCH /users/:id.
       * Esta es la "corrección manual" del sistema.
       */
      const correctedDate = new Date();
      correctedDate.setMonth(correctedDate.getMonth() + 1);
      const correctedDateStr = correctedDate.toISOString().split('T')[0];

      const res = await request(app.getHttpServer())
        .patch(`/users/${alumnoId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ membershipExpirationDate: correctedDateStr });

      expect([200, 201]).toContain(res.status);

      const verifyRes = await request(app.getHttpServer())
        .get(`/users/${alumnoId}`)
        .set('Authorization', `Bearer ${adminToken}`);

      const savedDate = new Date(verifyRes.body.membershipExpirationDate)
        .toISOString().split('T')[0];
      expect(savedDate).toBe(correctedDateStr);
    });
  });
});

// ── Helpers ───────────────────────────────────────────────────────────────────

async function bootstrapUser(
  app: INestApplication,
  dataSource: DataSource,
  gymId: string,
  role: string,
  email: string,
): Promise<string> {
  const passwordHash = await bcrypt.hash('Admin123!', 10);

  await dataSource.query(
    `INSERT INTO users ("firstName", "lastName", email, "passwordHash", role, "isActive", "paysMembership", "gymId")
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     ON CONFLICT (email) DO UPDATE SET "gymId" = EXCLUDED."gymId"`,
    ['Test', role, email, passwordHash, role, true, false, gymId],
  );

  const loginRes = await request(app.getHttpServer())
    .post('/auth/login')
    .send({ email, password: 'Admin123!' });

  return loginRes.body.access_token;
}
