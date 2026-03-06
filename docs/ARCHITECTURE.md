# Architecture Documentation

## Estrategia Multi-Tenant
TuGymFlow está diseñado bajo el esquema **Data Isolation at Application Level** (Single Database, Shared Schema). Todos los gimnasios coexisten en la misma base de datos relacional y las mismas tablas, pero el aislamiento se garantiza operativamente agregando de forma obligatoria la clave foránea `gym_id` a casi todas las entidades persistentes.

## Separación de Datos de Cada Gimnasio
- **Consultas (Read):** Cualquier petición que invoque un servicio interno incluye implícita o explícitamente el `gymId` extraído del token del solicitante en los parámetros de la cláusula `WHERE`.
- **Escrituras (Write):** Las relaciones predeterminan que cualquier nuevo registro de un usuario vinculado (entrenamientos, membresías, cuotas) asigne automáticamente por el backend el identificador de su Tenant (gimnasio), prohibiendo al cliente frontend alterarlo.
- Un usuario `STUDENT` no posee capacidad de "saltar" entre gimnasios. Está ligado a uno solo según el `inviteToken` que utilizó originalmente.

## Jerarquía de Roles (RBAC)
- **SUPER_ADMIN**: Bypass global.
- **GYM_ADMIN**: Permisos globales de lectura y escritura exclusivamente para entidades donde `entity.gymId == user.gymId`.
- **TEACHER**: Permisos de lectura/escritura limitados al ámbito deportivo y a alumnos de su misma sede. Acceso denegado a balances o configuraciones del gimnasio.
- **STUDENT**: Permisos operacionales "Self". Únicamente lee/escribe su propio progreso o rutinas.

## Estructura de Módulos (Macro)
La arquitectura refleja un monolito modular:
1. **Core/Auth:** Provee Autenticación, Inyección de Contexto, Estrategias JWT y Guards.
2. **Business/Entities:** Los diferentes dominios funcionales (Gimnasios, Membresías, Cuotas, Ejercicios, Estadísticas).
3. **Presentation (Frontend):** Consume la API y delega el acceso visual de los módulos dependiendo del RBAC provisto en la autenticación.

## Principales Servicios del Backend (NestJS)
- **UsersService & AuthService**: Orquestan el Onboarding, Generación/Revocación de JWT y las pasarelas con OAuth2.
- **GymPlanService & RoutineService**: Constructores de jerarquía deportiva. Manejan desde el macrociclo (Plan) hasta el microciclo (Ejercicio -> Set -> Reps).
- **InviteService / GymsController**: Despacho de tokens QR estáticos limitados que desencadenan el enrolamiento.

## Capas de la API
1. **Guards y Decoradores:** (`@Roles()`, `JwtAuthGuard`) validan la petición HTTP.
2. **Controllers:** Recogen la solicitud DTO y dirigen inmediatamente hacia la capa de casos de uso (Services).
3. **Services:** Procesan reglas de negocio, autorizaciones lógicas y determinan el tenant.
4. **Repositories / ORM (TypeORM):** Construyen el transaccional hacia PostgreSQL inyectando el filtro multi-tenant.

## Relaciones Principales de Base de Datos
- Un `Gym` tiene muchos `Users`.
- Un `User` tiene un `Role` y un `Gym` asociado.
- Un `User` (Alumno) tiene muchas `Memberships`, las cuales tienen asociadas `Dues` (cuotas).
- Un `Plan` o `Routine` pertenece a un `Gym` o a un `User`.
- Un `TrainingSession` referencia a un `User`, una `Routine` y a eventos atómicos de completitud de ejercicios.
