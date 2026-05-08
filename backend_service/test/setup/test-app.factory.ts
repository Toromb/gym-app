import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { AppModule } from '../../src/app.module';
import { DataSource } from 'typeorm';
import { Client } from 'pg';

/**
 * Fábrica central que levanta la aplicación NestJS en modo test.
 *
 * Estrategia:
 * 1. Antes de iniciar la app, se conecta directamente a Postgres (BD: postgres)
 *    y crea `gym_test_db` si no existe, de forma idempotente.
 * 2. Levanta el AppModule completo, que apunta a `gym_test_db` gracias a las
 *    variables de entorno inyectadas por dotenv-cli desde `.env.test`.
 * 3. Activa synchronize: true (controlado por NODE_ENV=test) para que TypeORM
 *    cree el esquema automáticamente desde las entidades.
 * 4. Expone la app y el DataSource para que las suites puedan usarlos.
 *
 * Regla de negocio relacionada:
 * - Regla 10 (DO NOT BREAK): En ningún modo de test deben presentarse logs de
 *   datos ajenos ni cruzarse con la BD de producción/desarrollo.
 */
export async function createTestApp(): Promise<{
  app: INestApplication;
  dataSource: DataSource;
}> {
  // ── Paso 1: Crear la BD de test si no existe ──────────────────────────────
  await ensureTestDatabaseExists();

  // ── Paso 2: Levantar la aplicación NestJS ────────────────────────────────
  const moduleFixture: TestingModule = await Test.createTestingModule({
    imports: [AppModule],
  }).compile();

  const app = moduleFixture.createNestApplication();

  // Validación de DTOs igual que en producción
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: false,
      transform: true,
    }),
  );

  await app.init();

  // ── Paso 3: Obtener el DataSource para limpieza entre tests ──────────────
  const dataSource = moduleFixture.get<DataSource>(DataSource);

  return { app, dataSource };
}

/**
 * Crea la base de datos `gym_test_db` si aún no existe.
 *
 * Se conecta con el usuario configurado en .env.test a la BD `postgres`
 * (que siempre existe en cualquier instalación PostgreSQL) y ejecuta
 * CREATE DATABASE de forma segura.
 */
async function ensureTestDatabaseExists(): Promise<void> {
  const dbName = process.env.DB_NAME || 'gym_test_db';
  const client = new Client({
    host: process.env.DB_HOST || '127.0.0.1',
    port: Number(process.env.DB_PORT) || 5435,
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    database: 'postgres', // Siempre disponible; no conectamos a gym_test_db aún
  });

  try {
    await client.connect();

    // Verificar si la BD ya existe
    const result = await client.query(
      `SELECT 1 FROM pg_database WHERE datname = $1`,
      [dbName],
    );

    if (result.rowCount === 0) {
      // La BD no existe, la creamos
      // No podemos usar parámetros en CREATE DATABASE, pero dbName viene de .env
      await client.query(`CREATE DATABASE "${dbName}"`);
      console.log(`[TestSetup] Base de datos '${dbName}' creada exitosamente.`);
    } else {
      console.log(`[TestSetup] Base de datos '${dbName}' ya existe. Continuando...`);
    }
  } finally {
    await client.end();
  }
}
