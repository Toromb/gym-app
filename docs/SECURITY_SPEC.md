# Security Specification

## Autenticación Base
TuGymFlow confía en un marco de seguridad híbrido donde la API REST está resguardada por **Decoradores Custom** (`@Public()`, `@Roles(...)`) y `Guards` de Passport/JWT (`JwtAuthGuard`, `RolesGuard`). Cualquier endpoint no público exige un `Bearer Token`.

## Tokens JWT (Access Tokens)
El sistema emite Web Tokens firmados criptográficamente y expuestos al cliente (Frontend) mediante el endpoint `/auth/login`.  
- **Vida útil:** Son deliberadamente cortos (ej. de 15 minutos a 1 hora).
- **Payload:** Contienen `sub` (userId), `email`, `role`, y `gymId`. Evitan consultas extra a la Base de Datos agilizando las respuestas.
- **Limitaciones:** Al ser "Steless", no pueden ser revocados hasta que expiren.

## Refresh Tokens
Para suplir las deficiencias del JWT convencional y evitar que el usuario deba loguearse constamente, se implementa el uso estricto de **Refresh Tokens Rotativos**:
1. Al Iniciar Sesión, se guarda localmente (y segura) un Refresh Token cifrado.
2. Está persistido en base de datos (`refresh_tokens` entity).
3. **Rotación:** Cuando el JWT vence, el Frontend silenciosemente lo negocia por uno nuevo enviándolo a `/auth/refresh`. El Backend anula el Refresh Token usado, genera otro par de Access+Refresh y los devuelve, reduciendo el riesgo de re-uso.
4. Si un atacante roba el Refresh Token roto, la API identificará el re-uso e invalidará todos los tokens de la "familia" afectada obligando al cierre de sesión ("Revocación general").

## Sistema de Invitaciones Cerrado (SSOT)
Un usuario no puede "elegir" en qué gimnasio registrarse desde un Dropdown. Las inscripciones están selladas matemáticamente (por firma QR o DeepLink):
- El gimnasio genera un QR.
- Ese QR en sí contiene un JSON Encriptado del Backend validando `{"gymId": XYZ, "role": "STUDENT"}` que no puede ser falsificado.
- El usuario lo escanea y esa clave se adosa al Body de `google/login` o registro para validarlo. Si el Token URL se modifica manualmente, el servidor devuelve 403 Forbidden.

## Vectores de Ataque Identificados y Protecciones

1. **Replay Attacks:** Se mitiga completamente con la familia de Refresh Tokens de 1 solo uso, los cuales deshabilitan la sesión global si son abusados.
2. **Access Data Leaks (Aislamiento de Multi-Tenant):** Controlado gracias a que el `gym_id` está codificado en el token del Backend, el frontend NUNCA puede suplantar la variable. Un intento de consulta tipo `GET /gyms/2/users` por un miembro del `gym 1` será repelido instantáneamente por el filtro local del `GymService`.
3. **Fugas de Logout:** Cuando un usuario utiliza la acción de `Logout`, el API detiene sus HTTP Interceptors y procede sí o sí con la purga, liquidando la base de datos (invalida la vida del Refresh Token).
4. **Brute Force Registration:** Cubierto delegando el Login a OAuth2 (Google Sign In y Sign In with Apple).
