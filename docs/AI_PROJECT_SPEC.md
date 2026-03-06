# TuGymFlow - AI Project Spec

## Descripción General del Proyecto
TuGymFlow es una plataforma SaaS (Software as a Service) diseñada para digitalizar y optimizar la administración y la experiencia deportiva de gimnasios. El objetivo es proporcionar un ecosistema unificado donde los administradores, profesores y estudiantes interactúan fluidamente para la configuración técnica del centro y el seguimiento físico.

## Objetivo del Sistema
Brindar una solución integral que ataque dos frentes principales:
1. **El frente administrativo:** Control de sedes, estudiantes, cuotas, membresías y finanzas del gimnasio.
2. **El frente deportivo:** Facilitar herramientas avanzadas a los profesores para construir y asignar rutinas, y a los alumnos una aplicación interactiva para seguirlas, registrar cargas musculares y medir tiempos de descanso.

## Usuarios Objetivo y Roles del Sistema
El sistema implementa control de acceso basado en roles (RBAC) estricto:
- **SUPER_ADMIN:** Gestión global de la plataforma, creación de nuevos gimnasios y supervisión técnica transversal.
- **GYM_ADMIN:** Encargado operativo de un recinto específico. Invita a nuevos profesores/alumnos y monitorea la salud financiera/matriculaciones.
- **TEACHER (Profesor):** Perfil técnico deportivo. Diseña los bloques de ejercicios, configura cargas y supervisa la evolución de los alumnos asignados.
- **STUDENT (Alumno):** Usuario final. Consume las rutinas asignadas, anota sus repeticiones/peso en tiempo real y gestiona su perfil.

## Capacidades Principales de la Plataforma
- **Gestión de Gimnasios:** Creación, configuración de sedes y aislamiento de datos (multi-tenant).
- **Gestión de Miembros:** Panel de control de alumnos y staff, con roles específicos mediante invitaciones tokenizadas de un solo uso.
- **Sistema de Cuotas / Membresías:** Manejo de pagos, estado de actividad, y restricciones de acceso para morosos.
- **Rutinas de Entrenamiento:** Creación de planes libres y predefinidos. Organización por grupos musculares y bloques dinámicos.
- **Sesiones de Entrenamiento:** Modo enfoque para el alumno, incluye utilidades integradas como reloj/cronómetro/temporizador web/mobile.
- **Formulario de Onboarding:** Flujo paso a paso para configurar nuevos miembros en su respectivo gimnasio.
- **Sistema de Invitación / QR:** Altas centralizadas mediante un enlace cerrado o código QR. El JWT de invitación liga obligatoriamente el usuario al `gymId` mitigando la selección manual de sedes.

## Arquitectura General
- **SaaS Multi-tenant:** Una misma instancia de aplicación y base de datos sirve a múltiples clientes operando en su propio silo lógico protegido por claves foráneas y middleware de seguridad.
- **Separación de Datos:** Todas las consultas transaccionales exigen o filtran mediante la propiedad `gym_id`.
- **Enfoque de Autenticación:** Se utiliza OAuth2 complementado con controles JWT internos, y políticas estrictas de actualización (Refresh Tokens).

## Infraestructura
- **Backend:** NestJS centralizado que actúa como API Controller y Business Layer.
- **Base de Datos:** Motor relacional (PostgreSQL) garantizando integridad de transacciones financieras y cascadas de rutinas.
- **Frontend:** SDK Flutter con despliegue nativo múltiple (aplicación móvil iOS/Android) y aplicación Web responsiva.
- **Despliegue:** Nubes híbridas bajo demanda. Empaquetado de artefactos web en el servidor y `.apk`/`.aab`/`.ipa` para distribución móvil.
