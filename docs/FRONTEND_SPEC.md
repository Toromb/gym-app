# Frontend Specification

## Estructura General de la App
La aplicación está programada en **Flutter** utilizando Dart garantizando presencia isomórfica (Web, iOS, Android) mediante un único árbol de código.
Estructuralmente agrupa la interfaz en `lib/src/screens` y la lógica reactiva en gestores de estado descentralizados bajo `lib/src/providers`.

## Modelo de Navegación
- Hace uso de `MaterialPageRoute` y rutado basado en URIs con `onGenerateRoute` en `main.dart`.
- El flujo rechaza inmediatamente los deep-links e invitaciones si el usuario no tiene credenciales, empujándolo a LoginScreen y luego retornando.
- La pantalla raíz resuelve automáticamente la pantalla de destino dependiendo del `AuthStatus` y del `Role` del usuario (ej. Dirige al Scaffold del estudiante o al Tablero del profesor).

## Gestión de Estado
Implementado primariamente con **Provider** (`ChangeNotifierProvider`). Las vistas son del tipo `Consumer` para reaccionar asíncronamente a los cambios.
- `AuthProvider`: Persiste caché de sesión (JWT) interno.
- `UserProvider`: Maneja información del perfil logueado.
- Exclusivas proxy de proveedores (`ChangeNotifierProxyProvider`) para garantizar que listas de ejercicios, planes, y sedes borren sus valores cuando el AuthStatus cae (Logout seguro sin fugas de datos de otros Tenants).

## Pantallas Importantes

- **LoginScreen:** Puerta principal; incluye botones de SocialAuth (Google/Apple) y un punto de escaneo para `Onboarding`.
- **Registro con Invitación (Onboarding del Gym):** Formulario adaptativo que restringe la elección del gimnasio ocultando campos y usando estáticamente el ID contenido en el QR.
- **Dashboard:** Un hub central distinto para Alumnos, Profesores y Admins con sus debidas analíticas y notificaciones.
- **DayDetailScreen (Sesiones de Entrenamiento):** La pantalla de trabajo grueso del Alumno. Le permite ir tildando progresos, revisando historial de RM (Repetición Máxima) en ejercicios específicos.
- **Training Timer Card:** Widget re-usable persistente que incluye Cronómetro y Temporizador con notificaciones de alarma web-safe y background-safe.
- **Perfil:** Configuraciones de cuentas de usuario, notificaciones y cierres de sesión forzados.

## Comunicación con la API del Backend
El frontend se abstrae en un wrapper HTTP dinámico llamado `ApiClient`.
- Este cliente de servicios adhiere el `Authorization: Bearer <TOKEN>` silenciosamente interceptando cada petición mediante los interceptores locales.
- Implementa un sistema global contra `401 Unauthorized` que inicia una revalidación automática (`refreshToken`) de fondo si caduca un token, asegurando que las pantallas mantengan su sesión sin molestar al usuario, a menos que fallase y redirigiese al LogIn expulsando la sesión defectuosa de manera controlada para prevenir **Rate Limiting**.
