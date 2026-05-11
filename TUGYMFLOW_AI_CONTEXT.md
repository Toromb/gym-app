# 🏋️ TuGymFlow — AI Context Document

> **Versión:** 2026-05-08 | **Proyecto:** TuGymFlow (Gym App)  
> **Propósito:** Contexto completo para desarrollo colaborativo con IA (Claude / Gemini).  
> Usar este archivo al inicio de cada sesión para que el AI entienda el proyecto desde cero.

---

## 1. Identidad del Proyecto

- **Nombre comercial:** TuGymFlow
- **Tipo:** SaaS B2B multiplataforma para gestión integral de gimnasios
- **Dominio producción:** https://tugymflow.com
- **Repositorio local:** `c:\Users\Cristian\.gemini\antigravity\scratch\gym_app`
- **Estado actual:** MVP validado en producción, evolución activa

---

## 2. Stack Tecnológico

### Backend
| Componente | Tecnología |
|---|---|
| Framework | NestJS 11 (TypeScript) |
| ORM | TypeORM 0.3 |
| Base de datos | PostgreSQL 15 |
| Autenticación | JWT + Passport + Refresh Tokens |
| Rate limiting | `@nestjs/throttler` (100 req/min) |
| Cache | `@nestjs/cache-manager` (TTL 60s) |
| Archivos estáticos | `@nestjs/serve-static` → `/uploads` |
| Validación DTOs | `class-validator` + `class-transformer` |
| Docs API | Swagger UI en `/api-docs` |
| Versión | `package.json` version `1.1.7` |

### Frontend
| Componente | Tecnología |
|---|---|
| Framework | Flutter (Web + Mobile) |
| State Management | Provider (`ChangeNotifier` + `ChangeNotifierProxyProvider`) |
| HTTP Client | `http` package (patrón singleton `ApiClient`) |
| Almacenamiento seguro | `flutter_secure_storage` (mobile) / `shared_preferences` (web) |
| Offline cache | Hive + `local_storage_service.dart` + `sync_service.dart` |
| Localización | `flutter_localizations` + `AppLocalizations` (español primario) |
| URL Strategy | `url_strategy` → path URLs sin `#` |
| Autenticación social | `google_sign_in` + Sign In with Apple |

### Infraestructura (Producción)
| Componente | Descripción |
|---|---|
| Contenerización | Docker Compose (`infra/docker-compose.prod.yml`) |
| Servicios | `postgres` + `backend` + `frontend` + `nginx-proxy` + `acme-companion` |
| SSL | Let's Encrypt via `acme-companion` automático |
| Reverse Proxy | `nginxproxy/nginx-proxy:alpine` |
| Dominio | `tugymflow.com` / `www.tugymflow.com` |
| Backend port | `3000:3000` (expuesto a la red interna) |
| Uploads volume | `uploads:/app/uploads` (persistente) |
| DB volume | `infra_postgres_data` (external, persistente) |

---

## 3. Estructura del Proyecto

```
gym_app/
├── backend_service/          # NestJS API
│   ├── src/
│   │   ├── auth/             # Auth: JWT, Google, Apple, Refresh Tokens
│   │   ├── users/            # Users + Onboarding
│   │   ├── plans/            # Plans, Weeks, Days, Exercises, TrainingSessions, FreeTrainings
│   │   ├── exercises/        # Exercise Library + Equipments
│   │   ├── payments/         # Payment history + registration
│   │   ├── gyms/             # Gym entity + config
│   │   ├── gym-schedule/     # Schedule slots
│   │   ├── gym-leads/        # Lead capture (public)
│   │   ├── stats/            # Analytics / progress stats
│   │   └── notifications/    # Push notifications
│   ├── infra/
│   │   └── docker-compose.prod.yml
│   └── stress_tests/         # Load test scripts
│
├── frontend/                 # Flutter app
│   └── lib/
│       ├── main.dart         # App entry point, providers, routing, interceptors
│       └── src/
│           ├── constants/
│           ├── localization/  # AppLocalizations (es/en)
│           ├── models/        # Dart models con fromJson/toJson
│           ├── providers/     # State management (Provider)
│           ├── screens/       # Pantallas por rol
│           ├── services/      # API calls + local storage
│           ├── theme/         # AppTheme, BackgroundStyles
│           ├── utils/         # AppColors, constants, swap logic
│           └── widgets/       # Widgets reutilizables
│
├── BUSINESS_RULES.md         # Reglas de negocio (fuente de verdad)
├── requirements.md           # Requerimientos funcionales y NFR
├── BACKLOG.md               # Deuda técnica y próximas features
├── RELEASE_NOTES.md          # Changelog
└── docs/                    # Documentación adicional
```

---

## 4. Roles y Permisos

```
SUPER_ADMIN → Plataforma global (todos los gimnasios)
ADMIN       → Gestión completa de su gimnasio (users, pagos, config)
PROFE       → Crear plans, asignar a alumnos, ver progreso de sus alumnos
ALUMNO      → Ejecutar rutinas, ver progreso propio, ver estado membresía
```

**Reglas críticas de acceso:**
- Todo usuario debe pertenecer a un gimnasio (no hay registro público independiente)
- PROFE no tiene acceso a finanzas ni configuración administrativa
- Solo ADMIN/SUPER_ADMIN pueden registrar pagos
- Los alumnos ingresan solo por invitación (QR o enlace)

---

## 5. Módulos Backend — Endpoints Clave

### Auth (`/auth`)
| Método | Endpoint | Descripción |
|---|---|---|
| POST | `/auth/login` | Login email/password |
| POST | `/auth/google` | Login con Google |
| POST | `/auth/apple` | Login con Apple |
| POST | `/auth/refresh` | Renovar JWT con Refresh Token |
| POST | `/auth/logout` | Revocar refresh token |
| POST | `/auth/activate-account` | Activar cuenta con token |
| POST | `/auth/reset-password` | Resetear password |
| POST | `/auth/change-password` | Cambiar password (autenticado) |

### Users (`/users`)
- CRUD de usuarios + perfil propio + asignación de profesores

### Plans (`/plans`)
- Crear/editar planes (plantillas) y semanas/días/ejercicios
- Asignar planes a alumnos (`StudentPlan`)
- Historial completado (`CompletedPlan`)

### Training Sessions (`/training-sessions`)
- Iniciar/completar sesiones de entrenamiento
- Guardar datos reales ejecutados (`SessionExercise`)

### Free Trainings (`/free-trainings`)
- Entrenamientos libres sin estructura de plan

### Payments (`/payments`)
| Método | Endpoint | Descripción |
|---|---|---|
| POST | `/payments/user/:userId` | Registrar pago (ADMIN only) |
| GET | `/payments/user/:userId` | Ver historial de pagos |

### Gym Schedule (`/gym-schedule`)
- Slots de horario del gimnasio

### Stats (`/stats`)
- Métricas de progreso del alumno

### Gym Leads (`/gym-leads`)
- `POST /gym-leads` — público, sin autenticación
- Captura de leads interesados en el gimnasio

---

## 6. Entidades de Base de Datos (TypeORM)

### `User` (tabla `users`)
```typescript
id: uuid (PK)
firstName, lastName, email (unique)
provider: 'LOCAL' | 'GOOGLE' | 'APPLE'
role: UserRole ('admin' | 'profe' | 'alumno' | 'super_admin')
paymentStatus: PaymentStatus ('pending' | 'paid' | 'overdue')
paysMembership: boolean (exención de pago)
membershipStartDate, membershipExpirationDate, lastPaymentDate
isActive: boolean
// Relaciones:
gym: ManyToOne → Gym
professor: ManyToOne → User (self)
students: OneToMany → User (self)
studentPlans: OneToMany → StudentPlan
completedPlans: OneToMany → CompletedPlan
onboardingProfile: OneToOne → OnboardingProfile
refreshTokens: OneToMany → RefreshToken
```

### Jerarquía de Planes
```
Plan (plantilla)
  └── PlanWeek
        └── PlanDay (asignado con ejercicios)

StudentPlan (asignación plan→alumno)
  └── AssignedPlanWeek
        └── AssignedPlanDay
              └── AssignedPlanExercise

CompletedPlan (snapshot inmutable al finalizar)
TrainingSession (sesión de ejecución activa)
  └── SessionExercise (datos reales ejecutados por el alumno)
```

### Métricas de ejercicio soportadas
- `REPS` — Repeticiones (series x reps x peso)
- `TIME` — Duración en segundos
- `DISTANCE` — Distancia en metros

---

## 7. Sistema de Autenticación

### Flujo JWT + Refresh Token
1. Login → `access_token` (corto plazo) + `refresh_token` (largo plazo, almacenado en DB)
2. `ApiClient` detecta 401 → llama a `onTokenExpired` → `AuthService.refreshToken()`
3. Si el refresh falla → `onSessionTerminated` → logout + snackbar "Tu sesión ha expirado"
4. Logout voluntario:
   - `_isLoggingOut = true` en `AuthProvider`
   - `deleteLocalTokens()` antes del network call → requests en vuelo no disparan interceptor
   - `revokeServerToken()` en background (best-effort)

### Autenticación Social
- **Google:** `google_sign_in` → `idToken` → `POST /auth/google`
- **Apple:** `sign_in_with_apple` → `identityToken` → `POST /auth/apple`

### Almacenamiento de tokens
- **Mobile:** `flutter_secure_storage` → key `'jwt'`
- **Web:** `SharedPreferences` → key `'jwt'`

---

## 8. State Management (Frontend)

### Providers registrados en `main.dart`
| Provider | Responsabilidad |
|---|---|
| `AuthProvider` | Autenticación, sesión, datos del user logueado, gym info |
| `UserProvider` | Gestión de usuarios (admin panel) |
| `PlanProvider` | Plans, StudentPlans, TrainingSessions, progreso |
| `ExerciseProvider` | Biblioteca de ejercicios |
| `GymScheduleProvider` | Horarios del gimnasio |
| `GymsProvider` | Config del gimnasio (admin) |
| `StatsProvider` | Estadísticas y progreso |
| `ThemeProvider` | Light/Dark mode, persistencia por userId |

### Patrón de limpieza al logout
```dart
ChangeNotifierProxyProvider<AuthProvider, PlanProvider>(
  update: (_, auth, prev) {
    if (!auth.isAuthenticated) prev?.clear();
    return prev!;
  },
)
```

### `ApiClient` (Singleton)
- Agrega `Authorization: Bearer $token` a todos los requests
- Cache-busting en GET: agrega `?_t={timestamp}`
- Timeout: 30 segundos
- Interceptor 401 automático con retry tras refresh

---

## 9. Routing (Frontend)

| Ruta | Pantalla |
|---|---|
| `/` | HomeScreen (auth-guarded) → redirige a dashboard por rol |
| `/login` | LoginScreen |
| `/invite?token=X` | LoginScreen (flujo de invitación) |
| `/activate-account?token=X` | ActivateAccountScreen (modo activate) |
| `/reset-password?token=X` | ActivateAccountScreen (modo reset) |
| `/soporte` | SupportScreen |
| `/terminos` | TermsScreen |

### Routing por Rol (en `HomeScreen`)
```
SUPER_ADMIN → super_admin dashboard
ADMIN       → admin/admin_dashboard_screen.dart
PROFE       → teacher/dashboard_screen.dart
ALUMNO      → student/student_home_screen.dart
```

---

## 10. Pantallas por Rol

### Admin
- `admin_dashboard_screen.dart` — Dashboard principal admin
- `manage_users_screen.dart` — Gestión completa de usuarios
- `edit_user_screen.dart` / `add_user_screen.dart` — CRUD usuarios
- `collection_dashboard_screen.dart` — Dashboard de cobranza/finanzas
- `payment_history_screen.dart` — Historial de pagos por usuario
- `gym_config_screen.dart` — Configuración del gimnasio
- `manage_equipments_screen.dart` — Gestión de equipamiento
- `free_training/` — Entrenamiento libre (admin)

### Profesor
- `dashboard_screen.dart` — Dashboard profesor
- `manage_students_screen.dart` — Ver alumnos asignados
- `student_plans_screen.dart` — Planes de un alumno específico (tabs: Activos / Historial)
- `create_plan_screen.dart` — Creador de planes complejo
- `create_exercise_screen.dart` — Crear ejercicio
- `exercises_list_screen.dart` — Biblioteca de ejercicios
- `exercise_detail_screen.dart` — Detalle del ejercicio
- `assign_plan_modal.dart` — Modal para asignar plan a alumno
- `add_student_screen.dart` — Agregar alumno

### Alumno
- `student_home_screen.dart` — Dashboard principal (plan activo, progreso)
- `student_plans_list_screen.dart` — Lista de todos sus planes
- `calendar_screen.dart` — Vista calendario de sesiones
- `student_history_screen.dart` — Historial de planes completados
- `muscle_flow_screen.dart` — Vista muscular (MuscleFlow)
- `muscle_flow/` — Sub-pantallas MuscleFlow
- `onboarding_screen.dart` — Onboarding inicial del alumno
- `profile/` — Sub-pantallas de perfil

### Compartidas
- `shared/day_detail_screen.dart` — Detalle de un día de entrenamiento (alumno ejecuta, profe lee)

### Públicas
- `public/activate_account_screen.dart` — Activación/reset
- `public/support_screen.dart` — Soporte
- `public/terms_screen.dart` — Términos

---

## 11. Sistema de Diseño (Design Tokens)

### `AppColors` (`lib/src/utils/app_colors.dart`)
```dart
// [GYM-CONFIGURABLE] — futuros tokens dinámicos por gimnasio
primary       = Color(0xFF2563EB)  // Blue-600
primaryDark   = Color(0xFF1E40AF)  // Blue-800
accent        = Color(0xFF3B82F6)  // Blue-500
cardSurface   = Color(0xFFB8D4F5)  // Pastel blue — TOKEN CENTRAL

// Semánticos
success = Color(0xFF10B981)  // Emerald-500
warning = Color(0xFFF59E0B)  // Amber-500
error   = Color(0xFFEF4444)  // Red-500

// Fondos
background    = Color(0xFFF8FAFC)  // Slate-50
surface       = Color(0xFFFFFFFF)  // White
surfaceVariant= Color(0xFFF1F5F9)  // Slate-100

// Textos
textMain = Color(0xFF0F172A)  // Slate-900
textBody = Color(0xFF334155)  // Slate-700
textSoft = Color(0xFF64748B)  // Slate-500
```

> ⚠️ **Regla**: Nunca hardcodear colores hex en pantallas. Siempre usar `AppColors.*`

### `AppTheme` (`lib/src/theme/app_theme.dart`)
- `CardThemeData` global: `color: AppColors.cardSurface` en modo claro
- `AppBarTheme`: transparente, íconos blancos, sin elevación
- `useMaterial3: true`
- Soporte light/dark mode dinámico por `ThemeProvider`
- Colores del gimnasio se cargan dinámicamente desde `auth.user.gym.primaryColor` (hex string)

### `BackgroundStyles` (`lib/src/theme/background_styles.dart`)
Para texto/iconos sobre imágenes de fondo (fuera de Cards):
```dart
BackgroundStyles.title    // blanco + sombra doble
BackgroundStyles.subtitle // blanco70 + sombra
BackgroundStyles.label    // blanco60 + sombra, 12px
BackgroundStyles.iconColor // Colors.white
BackgroundStyles.fromTheme(textStyle) // adapta cualquier TextStyle
```

---

## 12. Lógica de Negocio Clave

### Ciclo de Vida de un Plan
```
Plantilla (Plan) → [Asignación] → StudentPlan (activo/pendiente)
  → [Ejecución] → TrainingSession + SessionExercises
  → [Completar] → CompletedPlan (snapshot inmutable)
  → [Reiniciar] → Reset de progreso en StudentPlan, historial blindado
```

- **Solo 1 plan activo a la vez** por alumno; el resto queda `pending`
- **Las ediciones al Plan plantilla NO afectan** StudentPlans ya asignados (regla MVP — ver IMPLEMENTATION RISKS #2)
- **CompletedPlan es inmutable** — registro histórico permanente

### Membresías y Pagos

**Regla fundamental:** Los períodos de membresía van siempre del **1ro al 1ro del mes siguiente**.

```
membershipExpirationDate  → siempre es el 1ro de algún mes
lastPaymentDate           → fecha del último pago registrado por el ADMIN
paysMembership: boolean   → exención total de pago (profes, personal interno)

Cálculo de paymentStatus (runtime, no persiste en BD):
  Si paysMembership = false          → 'paid' (exento)
  Si membershipExpirationDate >= hoy → 'paid'
  Si día del mes <= 10              → 'pending' (período de gracia: días 1-10)
  Si día del mes > 10               → 'overdue' (mora)
```

**Cómo se generan los períodos al registrar N meses:**
- Si la expiración actual es **futura** → el nuevo período arranca desde esa fecha.
- Si la expiración es **pasada o nula** → el nuevo período arranca desde el 1ro del mes actual.
- Cada mes adicional extiende del 1ro al 1ro del siguiente mes.
- El `membershipExpirationDate` siempre queda en el **1ro del mes posterior** al último período pagado.

**PaymentRecord entity** (tabla `payment_records`):
- Cada mes pagado genera 1 registro con `periodFrom` y `periodTo` (ambos siempre día 1ro).
- Guarda: monto, método de pago, notas, quién lo registró (`registeredBy`).
- Inmutables — errores se corrigen con `PATCH /users/:id` ajustando `membershipExpirationDate`.

**Permisos sobre pagos:**
- `ADMIN`/`SUPER_ADMIN`: registran pagos y corrigen fechas.
- `ALUMNO`: puede ver su propio historial.
- `PROFE`: puede ver `paymentStatus` de sus alumnos (lectura), NO puede registrar ni ver historial.

- No hay acumulación de deuda histórica en MVP.
- Al inicio de cada mes el estado vuelve a `pending` automáticamente (sin intervención del ADMIN).

### Onboarding (Alumno)
- `OnboardingProfile` entity en DB → datos físicos del alumno
- `checkOnboardingStatus()` se llama al login
- Solo alumnos pasan por onboarding; profes/admins = `isOnboarded: true`

### 🏋️ Sistema de Peso Corporal en Ejercicios (Bodyweight)

> **IMPORTANTE**: Leer antes de modificar cualquier cosa relacionada con peso en ejercicios.

#### Entidades clave
| Campo | Entidad | Descripción |
|---|---|---|
| `Equipment.isBodyWeight` | `equipments` table | `true` solo para "Peso Corporal" (no editable, no eliminable) |
| `SessionExercise.weightUsed` | `session_exercises` | **Carga total efectiva** = pesoCorporal + lastre (string) |
| `SessionExercise.addedWeight` | `session_exercises` | **Solo el lastre** en kg (float, útil para analytics y swap logic) |
| `User.currentWeight` | `users` table | Peso corporal actual del alumno (actualizable) |
| `User.initialWeight` | `users` table | Peso corporal inicial registrado en onboarding |

#### Flujo completo
```
1. Profe crea ejercicio con equipment "Peso Corporal" (isBodyWeight=true)
2. Se asigna a alumno → genera SessionExercise con equipmentsSnapshot incluyendo "Peso Corporal"
3. Alumno abre la sesión → ExerciseExecutionCard detecta isBodyWeight=true
4. UI muestra:
     [Peso Corp.: 80 kg] (read-only, de auth.user.currentWeight ?? initialWeight)
     [Lastre (kg):  5  ] (editable, es el peso extra)
5. Al guardar (_buildUpdateData):
     addedWeight = 5 (solo el lastre)
     weightUsed  = 80 + 5 = "85" (total efectivo)
6. Si el alumno no tiene peso corporal en su perfil:
     weightUsed = addedWeight (solo lastre, sin suma de corporal)
```

#### Archivos involucrados
| Archivo | Rol |
|---|---|
| `frontend/lib/src/screens/shared/exercise_execution_card.dart` | UI + lógica de cálculo (campo `_isBodyWeight`, `_userBodyWeight`, `_buildUpdateData`) |
| `frontend/lib/src/utils/swap_exercise_logic.dart` | Usa `addedWeight` y `isBodyWeight` para calcular carga de referencia al hacer swap |
| `frontend/lib/src/screens/student/student_history_screen.dart` | Muestra diferente el peso en historial si `isBodyWeight=true` |
| `backend_service/src/exercises/entities/equipment.entity.ts` | Flag `isBodyWeight` en entidad |
| `backend_service/src/plans/entities/session-exercise.entity.ts` | Campos `weightUsed` y `addedWeight` |
| `backend_service/src/exercises/equipments.service.ts` | Crea "Peso Corporal" con `isEditable: false` al inicializar cada gym |

#### Reglas críticas — NO romper
- `_weightController` **NO se usa** en modo bodyweight (no se muestra en UI)
- `weightUsed` en modo bodyweight **siempre** se calcula: `pesoCorporal + lastre`
- `addedWeight` **siempre** es solo el lastre (nunca el total)
- El equipment "Peso Corporal" tiene `isEditable: false` → el backend lo rechaza si intentan borrarlo
- El `_userBodyWeight` se carga en `didChangeDependencies()` desde `AuthProvider`, NO desde el widget tree al momento de guardar

---

## 13. URL del Backend por Entorno

```dart
// constants.dart
Release:  'https://tugymflow.com/api'
Web-Dev:  'http://localhost:3001'
Android:  'http://10.0.2.2:3001'
iOS/Win:  'http://localhost:3001'
// Custom: --dart-define=API_URL=...
```

Backend corre en puerto `3001` en desarrollo local, `3000` en producción (el nginx hace el proxy).

---

## 14. Deuda Técnica Conocida (Implementation Risks)

1. **Multi-gym:** `gymId` en `User` entity → no escala a multi-gym. Solución futura: tabla bridge `UserGymSubscription`. Nota: `membershipStartDate` ya no se usa para el cálculo de períodos (reemplazado por lógica del 1ro de mes fija), pero persiste en DB como campo legacy.

2. **Plan Snapshot falso:** `StudentPlan` apunta por FK al plan maestro → editar el plan afecta alumnos activos. Solución: clonar árbol completo con `isTemplate: false`.

3. **Progress como JSONB:** Los datos de ejecución están en campo JSON `progress` en `StudentPlan`, no en entidades separadas. Dificulta analytics. Solución: módulo `TrainingSessionData` normalizado.

4. **Pagos sin transacciones duras:** Sin entidad `Invoice/Payment` real. Solo flags en `User`. Solución futura: modelo de Pagos/Facturas para Stripe/MercadoPago.

---

## 15. Backlog Activo

### 🔴 Alta Prioridad
- Integrar **Sentry** (backend) + **Firebase Crashlytics** (Flutter)

### 🟡 Prioridad Media
- **CI ✅ COMPLETO:** GitHub Actions (`.github/workflows/ci.yml`) corriendo en `main`:
  - Backend: TypeScript type-check + ESLint
  - Flutter: `flutter analyze --fatal-warnings --no-fatal-infos` + `dart format`
  - Resultado: **verde en cada push a main**
- **CD 🟡 Pendiente:** Automatizar deploy al VPS (actualmente manual via SSH + `docker compose -f docker-compose.prod.yml up -d --build`)

### 🟢 Baja Prioridad
- Git hooks (Husky + lint-staged) para linting obligatorio
- Evaluar migración de Provider a Riverpod/BLoC a largo plazo

---

## 16. Modelos Frontend (Dart)

| Archivo | Modelo principal |
|---|---|
| `user_model.dart` | `User`, `Gym` |
| `plan_model.dart` | `Plan`, `PlanWeek`, `PlanDay`, `PlanExercise`, `Equipment` |
| `execution_model.dart` | `TrainingSession`, `SessionExercise`, `StudentPlan` |
| `completed_plan_model.dart` | `CompletedPlan` |
| `free_training_model.dart` | `FreeTrainingDefinition`, `FreeTrainingSession` |
| `gym_model.dart` | `Gym`, configuración |
| `gym_schedule_model.dart` | `GymScheduleSlot` |
| `payment_record_model.dart` | `PaymentRecord` |
| `stats_model.dart` | `UserStats`, métricas de progreso |
| `onboarding_model.dart` | `OnboardingProfile` |
| `student_assignment_model.dart` | `StudentAssignment` |

---

## 17. Servicios Frontend (Dart)

| Servicio | Descripción |
|---|---|
| `api_client.dart` | Singleton HTTP client con interceptor JWT |
| `auth_service.dart` | Login, refresh, logout, change password |
| `user_service.dart` | Perfil, actualizar datos |
| `plan_service.dart` | CRUD plans, asignaciones, sesiones |
| `exercise_api_service.dart` | Biblioteca de ejercicios |
| `payment_service.dart` | Historial y registro de pagos |
| `stats_service.dart` | Métricas de progreso |
| `sync_service.dart` | Sincronización offline (Hive) |
| `local_storage_service.dart` | Abstracción Hive |
| `onboarding_service.dart` | Estado de onboarding |
| `free_training_service.dart` | Entrenamientos libres |
| `google_auth_service.dart` | Google Sign-In |
| `apple_auth_service.dart` | Apple Sign-In |

---

## 18. Guidelines de Desarrollo

### Backend (NestJS)
- Usar Guards JWT (`@UseGuards(AuthGuard('jwt'))`) en todos los endpoints protegidos
- Validar rol con `req.user.role` y arrojar `ForbiddenException` si no corresponde
- DTOs con `class-validator` decorators (no validación manual)
- Nunca exponer datos de otro gimnasio (validar siempre `gymId === requestor.gymId`)
- `synchronize: true` SOLO en dev/staging, validar con `DB_SYNCHRONIZE` env

### Frontend (Flutter)
- **Nunca hardcodear colores hex** → usar siempre `AppColors.*`
- **Texto sobre fondos de imagen** → usar `BackgroundStyles.*` (no `Colors.white` directo)
- **Cards y contenedores** → usar `Card()` (el `CardThemeData` global aplica el color correcto) o `AppColors.cardSurface` para `Container`
- Consumir state via `Provider.of<XProvider>(context, listen: false)` para acciones, `Consumer<X>` para UI reactiva
- Todo acceso a API va por el servicio correspondiente, nunca llamar `ApiClient` directo desde pantallas

### Testing
- Backend: Jest (`npm run test`, `npm run test:e2e:clean`)
- **Cobertura E2E actual: 108 tests en 6 suites** — todas verdes:
  | Suite | Tests | Cubre |
  |---|---|---|
  | `auth.e2e-spec.ts` | ~26 | Login, QR/invite, activación, reset/cambio de password |
  | `users.e2e-spec.ts` | ~20 | CRUD usuarios, permisos por rol |
  | `plans.e2e-spec.ts` | ~20 | Ciclo completo de planes: creación, asignación, ejecución, completar |
  | `exercises.e2e-spec.ts` | ~14 | Equipamiento + ejercicios con métricas |
  | `payments.e2e-spec.ts` | ~32 | Ciclo de membresía, estado de cuota, morosos, correcciones |
  | `gyms.e2e-spec.ts` | ~8 | Config del gym, aislamiento multi-tenant |
- Comando: `npm run test:e2e:clean` (limpia DB de test antes de correr)
- Archivo de setup: `test/setup/test-app.factory.ts` + `test/setup/db-cleanup.helper.ts`

---

## 19. Comandos Útiles

```bash
# Backend — Desarrollo
cd backend_service
npm run start:dev      # Watch mode

# Backend — Tests
npm run test           # Unit tests
npm run test:e2e       # E2E tests
npm run test:cov       # Coverage

# Backend — Seed
npm run seed

# Frontend — Web Dev
cd frontend
flutter run -d chrome --web-port 3000

# Frontend — Build Web
flutter build web --release

# Producción — Deploy
cd infra
docker compose -f docker-compose.prod.yml up -d --build
```

---

## 20. Información Adicional para Claude

- **Idioma de comentarios/variables:** Español (documentación) + inglés (código)
- **Idioma de la UI:** Español, localizado vía `AppLocalizations`
- **Formato de fechas:** ISO 8601 en API, display en español en UI
- **UUIDs** como PKs en todas las entidades backend
- El proyecto tiene `gymName` como campo legacy en `User` y `gym.businessName` como fuente actual — usar `businessName` cuando esté disponible
- El frontend carga la imagen de fondo del gimnasio desde `gym.backgroundImageUrl` y la usa en los dashboards
- `swap_exercise_logic.dart` — lógica de intercambio de ejercicios dentro de un día (no tocar sin revisión)

---

*Generado por Antigravity AI. Última actualización: 2026-05-08. Actualizar ante cambios estructurales significativos.*
