# 🧪 Suite de Pruebas E2E — TuGymFlow Backend

## ¿Qué es esto?

Tests automatizados de extremo a extremo (E2E) que validan las reglas de negocio críticas del backend.
Cada test levanta una instancia real de NestJS, llama endpoints HTTP reales y verifica las respuestas
contra una base de datos de test aislada.

**Estado actual: 108 tests · 6 suites · ✅ todas verdes**

---

## Requisitos previos

| Requisito | Mínimo | Notas |
|---|---|---|
| Node.js | v18+ | `node --version` |
| npm | v9+ | incluido con Node |
| PostgreSQL | v14+ | corriendo localmente o vía Docker |

> El servidor de Postgres debe estar accesible. Si usás Docker Compose del proyecto,
> ya tenés Postgres corriendo en el puerto `5435`.

---

## Setup inicial (solo la primera vez)

```bash
# 1. Ir al directorio del backend
cd backend_service

# 2. Instalar dependencias (si no lo hiciste antes)
npm install

# 3. Crear el archivo de variables de entorno para tests
cp .env.test.example .env.test

# 4. Editar .env.test con tus credenciales de Postgres
#    Solo necesitás ajustar DB_HOST, DB_PORT, DB_USER y DB_PASSWORD
#    La base de datos gym_test_db se crea automáticamente
```

### Variables en `.env.test`

```env
NODE_ENV=test
DB_HOST=127.0.0.1
DB_PORT=5435          # Puerto de tu Postgres local (Docker usa 5435 por defecto)
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=gym_test_db   # BD exclusiva para tests — NO la misma que gym_db

JWT_SECRET=test_jwt_secret_for_e2e_only
JWT_INVITE_SECRET=test_invite_secret_for_e2e_only
JWT_REFRESH_SECRET=test_refresh_secret_for_e2e_only
JWT_EXPIRATION=1h
JWT_REFRESH_EXPIRATION=7d

PORT=3002             # Puerto diferente al de desarrollo (3001)
GOOGLE_CLIENT_ID=dummy
GOOGLE_CLIENT_SECRET=dummy
```

> ⚠️ `.env.test` **nunca se sube a Git** (está en `.gitignore`). El archivo `.env.test.example`
> sí está versionado como referencia.

---

## Cómo correr los tests

```bash
# Desde backend_service/

# ✅ Comando principal — corre toda la suite limpia
npm run test:e2e:clean

# Correr solo una suite específica
npm run test:e2e:clean -- --testPathPattern="payments"
npm run test:e2e:clean -- --testPathPattern="auth"
npm run test:e2e:clean -- --testPathPattern="plans"

# Ver output detallado de cada test
npm run test:e2e:clean -- --verbose
```

El comando `test:e2e:clean`:
1. Carga las variables de `.env.test` con `dotenv-cli`
2. Corre Jest con la config de `test/jest-e2e.json`
3. Fuerza ejecución en serie (`--runInBand`) para evitar conflictos de BD
4. Fuerza salida al terminar (`--forceExit`)

---

## Suites disponibles

| Suite | Archivo | Tests | Qué valida |
|---|---|---|---|
| Auth | `suites/auth.e2e-spec.ts` | ~26 | Login, JWT, registro por QR/invite, activación de cuenta, reset y cambio de password |
| Gyms | `suites/gyms.e2e-spec.ts` | ~8 | Creación de gyms, **aislamiento multi-tenant** |
| Users | `suites/users.e2e-spec.ts` | ~20 | CRUD usuarios, jerarquía de roles (ADMIN / PROFE / ALUMNO), permisos |
| Plans | `suites/plans.e2e-spec.ts` | ~20 | Ciclo completo: crear plan → asignar → activar → ejecutar sesión → completar |
| Exercises | `suites/exercises.e2e-spec.ts` | ~14 | Equipamiento, ejercicios con métricas (REPS/TIME/DISTANCE), permisos por rol |
| Payments | `suites/payments.e2e-spec.ts` | ~32 | Membresías 1ro-de-mes, período de gracia (días 1-10), morosos, correcciones |

---

## Cómo funciona internamente

```
npm run test:e2e:clean
  └─► dotenv-cli carga .env.test
       └─► Jest corre test/suites/*.e2e-spec.ts en serie (--runInBand)
            └─► Cada suite:
                 1. createTestApp()   → levanta NestJS completo en puerto 3002
                                        + verifica/crea gym_test_db en Postgres
                 2. cleanDatabase()   → trunca todas las tablas en orden FK-safe
                                        + inserta gym base para los tests
                 3. Tests            → llaman endpoints HTTP reales vía supertest
                                        (no mocks — todo pasa por el ORM y la BD real)
                 4. app.close()       → cierra la instancia NestJS
```

---

## Archivos de setup

| Archivo | Propósito |
|---|---|
| `setup/test-app.factory.ts` | Inicializa NestJS en modo test; verifica/crea `gym_test_db` |
| `setup/db-cleanup.helper.ts` | Trunca todas las tablas en orden FK-safe; `seedBaseGym()` crea un gym base |

---

## Troubleshooting

### ❌ "Connection refused" al correr los tests
```
Error: connect ECONNREFUSED 127.0.0.1:5435
```
**Solución:** Verificar que Postgres está corriendo y el puerto en `.env.test` es correcto.
```bash
# Con Docker:
docker ps | grep postgres

# Verificar puerto:
docker inspect <container_id> | grep HostPort
```

### ❌ "database gym_test_db does not exist"
**Solución:** El sistema lo crea automáticamente, pero el usuario de Postgres necesita permisos de `CREATEDB`.
```sql
ALTER USER postgres CREATEDB;
```

### ❌ Tests fallan por datos sucios de corridas anteriores
**Solución:** Usar siempre `test:e2e:clean` (no `test:e2e`). El `:clean` limpia la BD antes de cada suite.

### ❌ "JWT_SECRET is not defined"
**Solución:** Verificar que `.env.test` existe y tiene todos los campos requeridos.
```bash
cat .env.test
```

### ❌ Un test falla en CI pero pasa local
Las suites dependen de Postgres. En CI, configurar el servicio de Postgres antes de correr los tests.
Ver `.github/workflows/ci.yml` para referencia.

---

## Scripts manuales (debugging)

La carpeta `manual/` contiene scripts heredados para testear contra el servidor **en vivo**
(no la BD de test). Útiles para debugging rápido pero **no son tests automatizados**.

---

## Lo que NO hace este sistema

- ❌ No sube a producción (excluido en `tsconfig.build.json` y `.dockerignore`)
- ❌ No corre automáticamente en CI (requiere Postgres — se corre localmente o manualmente)
- ❌ No testea el frontend Flutter

---

## Bugs de producción detectados por los tests

| # | Bug | Corrección |
|---|---|---|
| 1 | `activateAssignment` no cargaba relaciones `assignedPlan`/`plan` → `BadRequestException` siempre | Agregado `relations` en la query |
| 2 | `finishAssignment` seteaba `startDate = null` → `NOT NULL` constraint crash 500 | Corregido el setter |
| 3 | `auth.service.ts` usaba `await import('crypto')` → crasheaba Jest | Cambiado a `require('crypto')` |
| 4 | TypeORM cascade save persistía `Equipment` sin `name` → `NOT NULL` error | Tests inician sesiones desde `assignedPlanId` existente |
| 5 | Billing por anchor-day (día de inscripción) → cálculos inconsistentes entre alumnos | Reemplazado por lógica fija: 1ro al 1ro del mes, 10 días de gracia universales |
