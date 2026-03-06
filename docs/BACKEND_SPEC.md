# Backend Specification

## Framework Principal
El backend está construido íntegramente sobre **NestJS** utilizando TypeScript. Emplea Programación Orientada a Objetos y patrones de Diseño Inyección de Dependencias.

## Módulos Principales

### Auth (`src/auth`)
Responsable de la seguridad principal y emisión de credenciales.
- Maneja el ciclo de vida del JWT y el Refresh Token.
- Resuelve pasarelas OAuth como Google Auth y Apple Auth (y las vincula al ecosistema interno).
- Incorpora la lógica de cierre de sesión (revocación de token en BD o Redis-like approach).

### Users (`src/users`)
Entidad transversal. Agrupa los perfiles de los usuarios (personales y físicos). Configura la capa del Profile.

### Gyms (`src/gyms`)
Unidad del "Tenant". Controla las configuraciones base corporativas de los centros, listado de sedes y es el pivote relacional de todo el software.

### Memberships (`src/memberships`)
Opera el aspecto financiero. Permite asignación de cuotas cíclicas o libres a los estudiantes y la consulta del estado de un alumno (Deudor/AlDía).

### Routines & Training (`src/plans`, `src/stats`)
Contiene los casos de uso para la creación de esquemas musculares. Incluye el manejo de bloques de entrenamiento, cargas, sets dinámicos y métricas evolutivas.

### Invite System (QR / Links)
Sistema acoplado en Auth y Gyms que encripta un JWK estático que representa: `{"gymId": 123, "role": "STUDENT"}`. Este endpoint es consultado exclusivamente a través de los Scanners o DeepLinks.

## Sistema de Autenticación en Detalle
Se emplea una solución estricta en seguridad:
- **JWT (Access Token):** Token primario inyectado por Bearer en cabecera HTTP, de vida corta (ej., 15 minutos). Representa los scopes temporales.
- **Refresh Tokens:** Almacenado de manera segura. Permite renovar el JWT. Al modificar credenciales en el sistema (ej. contraseña), se desechan todos los Refreshes activos, garantizando deslogueo remoto forzado.
- **SSO Google & Apple:** Los controladores reciben el token nativo (IdToken o IdentityToken según plataforma), lo validan matemáticamente con la autoridad (Google/Apple Keys), obtienen el perfil y homologan en el sistema el usuario hacia un JWT propio de GymFlow.

## Resolución Multi-Tenant
Al entrar a cualquier servicio del backend, el `JwtStrategy` extrae la información del usuario en `request.user`. Todas las consultas desde los `Controllers` re-pasan este sub-objeto a sus respectivos `Services`. El `Service` luego impone en sus condiciones TypeORM `where: { gymId: user.gymId }`, consiguiendo que el backend automáticamente delimite el radio de alcance, ignorando intencionadamente gimnasios ajenos.
