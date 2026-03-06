# TuGymFlow - Simple Roadmap

## Funcionalidades Completadas
* **Autenticación Base:** Google Sign-in integrado, Apple Sign-In (lógica híbrida en transcurso).
* **Control de JWT:** Emisión, validación y Guards en toda la aplicación. Rotación y expiración estricta de Refresh Tokens. Mitigación contra Replay Attacks implementada.
* **Onboarding & Multi-Tenant:** Arquitectura Multi-gimnasio con bases relacionales controladas por Tenant ID.
* **Sistema de Invitaciones (Alta Privada):** MVP de escáner QR in-app para la unificación forzada de nuevos estudiantes (y profesores) al gimnasio pertinente, eliminando la dependencia de Landing Pages.
* **Sesión / Cronómetro de Trabajo:** Componente de la Sesión de Entrenamiento finalizado visualmente, optimizado con timer de fondo, modo "Chronometer" (ascendente) y modo "Temporizador" (descendente con alarmas integradas nativas e infinitas en entorno Web).
* **Progreso de Rutinas:** Guardado local simple, control state con Providers.

## Funcionalidades en Desarrollo
* Terminación de flujos de creación visual de rutas y dependencias musculares (Stats de Músculos Trabajados por día).
* Ajustes visuales de login, UX general del dashboard e invitaciones. 
* Alineación rigurosa de branches (feature-develop-main) para flujos de CI/CD.

## Funcionalidades Planificadas
* **Punto de Gestión Financiera:** Activación, bloqueo y suspensión de Students mediante visualización de morosidad basada en Cuotas/Membresías activas.
* Integración a Gateways de Pagos para cuotas online.
* Notificaciones y Alertas In-App de expiración de planes para recordatorios corporativos.
* Consolidación final para paso a producción en App Store (Apple Sign-in final) y subida de APK / AAB para Android PlayStore.
