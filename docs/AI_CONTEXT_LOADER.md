# TuGymFlow - AI Context Loader

**Project:** TuGymFlow
**Description:** Plataforma SaaS multi-tenant para la gestión integral de gimnasios. Permite a los administradores gestionar su centro, a los profesores asignar rutinas y a los alumnos registrar y seguir sus entrenamientos diarios en tiempo real. 

**Tech Stack:**
- **Frontend:** Flutter (Mobile/Web) con Provider para el manejo de estado.
- **Backend:** NestJS (Node.js/TypeScript).
- **Database:** PostgreSQL (con TypeORM).

**Architecture Summary:** 
Arquitectura basada en API REST y un modelo de datos multi-tenant donde la lógica de negocio aísla la información según el identificador único del gimnasio (`gymId`).

**Roles Principales:**
1. SUPER_ADMIN: Control total del sistema y gimnasios.
2. GYM_ADMIN: Administración del gimnasio asignado.
3. TEACHER (Profesor): Creación y asignación de rutinas.
4. STUDENT (Alumno): Ejecución de rutinas y seguimiento.

**Core Modules:**
- Auth (JWT, Google/Apple Login, Refresh Tokens).
- Gyms & Enrollments (Invitaciones por QR/link).
- Training & Routines (Cronómetro, flujo muscular, definición de ejercicios).
- Memberships & Stats.

**Current Focus:**
Optimización de la experiencia de usuario (UI), sistema robusto de inicio de sesión/seguridad y herramientas integradas para el entrenamiento en tiempo real (temporizadores, progreso por grupos musculares).
