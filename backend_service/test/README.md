# 🧪 Suite de Pruebas E2E — TuGymFlow Backend

## ¿Qué es esto?

Tests automatizados de extremo a extremo (E2E) que validan las reglas de negocio críticas del backend. Cada vez que cambiás código, corrés estos tests para saber en segundos si rompiste algo importante — sin hacer pruebas manuales.

## Cómo correrlos

```bash
# Desde backend_service/
npm run test:e2e:clean
```

> **Prerequisito:** PostgreSQL corriendo con acceso a crear bases de datos.
> El sistema crea `gym_test_db` automáticamente si no existe.

## Configuración inicial (solo la primera vez)

```bash
cp .env.test.example .env.test
# Editá .env.test con tus credenciales de Postgres locales
```

## Suites disponibles

| Suite | Archivo | Qué valida |
|---|---|---|
| Auth | `suites/auth.e2e-spec.ts` | Login, JWT, invite/QR, activación de cuenta, reset y cambio de password |
| Gyms | `suites/gyms.e2e-spec.ts` | Creación de gyms, **aislamiento multi-tenant** |
| Users | `suites/users.e2e-spec.ts` | Jerarquía de roles (ADMIN / PROFE / ALUMNO) |
| Plans | `suites/plans.e2e-spec.ts` | Ciclo completo de planes: creación, asignación, ejecución, sesión y completar |
| Exercises | `suites/exercises.e2e-spec.ts` | Equipamiento, ejercicios con métricas (REPS/TIME/DISTANCE), permisos |
| Payments | `suites/payments.e2e-spec.ts` | Membresías 1ro-de-mes, período de gracia (días 1-10), morosos, correcciones |

## Cómo funciona

```
npm run test:e2e:clean
  └─► dotenv-cli carga .env.test
       └─► Jest corre test/suites/*.e2e-spec.ts en serie (--runInBand)
            └─► Cada suite:
                 1. createTestApp()   → levanta NestJS completo + verifica/crea gym_test_db
                 2. cleanDatabase()   → trunca todas las tablas (estado limpio)
                 3. Corre los tests   → llama endpoints HTTP reales con supertest
                 4. app.close()       → cierra la instancia
```

## Archivos de setup

| Archivo | Propósito |
|---|---|
| `setup/test-app.factory.ts` | Inicializa NestJS en modo test; crea `gym_test_db` si no existe |
| `setup/db-cleanup.helper.ts` | Limpia todas las tablas en orden FK-safe; seed de gym base |

## Scripts manuales (debugging)

La carpeta `manual/` contiene scripts heredados para testear contra el servidor **en vivo** (no la BD de test). Útiles para debugging rápido pero **no son tests automatizados**.

## Lo que NO hace este sistema

- ❌ No sube a producción (excluido en `tsconfig.build.json` y `.dockerignore`)
- ❌ No corre en el CI automático (requiere Postgres — se corre localmente o en CD)
- ❌ No testea el frontend Flutter

## Bugs encontrados durante la implementación

Estos bugs de producción fueron detectados por los tests y ya están corregidos:

1. **`activateAssignment`** no cargaba las relaciones `assignedPlan`/`plan` → siempre tiraba `BadRequestException`.
2. **`finishAssignment`** seteaba `startDate = null` violando el constraint `NOT NULL` de la BD → crash 500.
3. **`auth.service.ts`** usaba `await import('crypto')` (import dinámico) → crasheaba en Jest sin `--experimental-vm-modules`. Corregido a `require('crypto')`.
4. **`TrainingSession` / cascade save** en TypeORM persistia entidades `Equipment` incompletas al guardar sesiones → error `NOT NULL` en columna `name`. Corregido iniciando sesiones desde `assignedPlanId` existente.
5. **Anchor-day de membresía**: La lógica original calculaba el vencimiento basado en el día de inscripción del alumno (`membershipStartDate`). Reemplazada por lógica fija: **todos los períodos van del 1ro al 1ro del mes siguiente**, con 10 días de gracia universales.
