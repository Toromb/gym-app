# Requerimientos Gym App

Este documento sirve como la fuente de verdad para los requerimientos funcionales y no funcionales de la aplicación Gym App. Refleja el estado actual del sistema (MVP validado) y define las bases para su evolución futura.

## 1. Visión General
Aplicación multiplataforma (Web y Móvil) para la gestión integral de gimnasios.
Soporta un modelo SaaS multi-tenant, permitiendo administrar múltiples gimnasios de forma aislada, gestionar usuarios por rol, crear planes de entrenamiento estructurados y realizar el seguimiento detallado de la ejecución y el progreso de los alumnos.

## 2. Roles de Usuario

### 2.1. Super Admin (Plataforma)
- **Alcance**: Global (todos los gimnasios).
- **Responsabilidades**:
  - Crear, editar, suspender y eliminar gimnasios.
  - Gestionar usuarios Admin de cada gimnasio.
  - Definir límites por gimnasio (usuarios, planes, etc.).
  - Visualizar métricas globales de la plataforma.

### 2.2. Admin (Gimnasio)
- **Alcance**: Exclusivo de su gimnasio.
- **Responsabilidades**:
  - Gestión administrativa del gimnasio.
  - Crear, editar y eliminar usuarios Profesor y Alumno.
  - Asignar Profesores a Alumnos.
  - Gestionar el estado de membresía y pagos (manual en MVP).
  - Visualizar información general del progreso de los alumnos del gimnasio.

### 2.3. Profesor
- **Alcance**: Únicamente alumnos asignados explícitamente por un Admin.
- **Responsabilidades**:
  - Crear y gestionar alumnos asignados.
  - Crear planes de entrenamiento (plantillas).
  - Asignar planes a alumnos bajo su responsabilidad.
  - Monitorear el progreso y el historial de entrenamientos de sus alumnos.
- **Restricciones**:
  - No puede ver ni gestionar alumnos no asignados.
  - No puede administrar usuarios ni configuraciones del gimnasio.

### 2.4. Alumno
- **Alcance**: Personal.
- **Responsabilidades**:
  - Visualizar su plan de entrenamiento activo.
  - Ejecutar rutinas diarias y registrar resultados reales.
  - Ver historial de entrenamientos y progreso.
  - Visualizar el estado de su membresía.

## 3. Requerimientos Funcionales

### 3.1. Gestión de Gimnasios (Multi-tenancy)
- Soporte para múltiples gimnasios con aislamiento lógico de datos.
- Entidad Gym: nombre, dirección, estado y límites de usuarios.
- Todos los usuarios (excepto Super Admin) pertenecen a un único gimnasio.

### 3.2. Gestión de Planes de Entrenamiento
- Estructura jerárquica: Plan, Semanas, Días, Ejercicios.
- Ejercicios con series, repeticiones, carga sugerida y video.
- Los planes funcionan como plantillas reutilizables.
- Restricción MVP: los planes asignados no se editan estructuralmente.

### 3.3. Ejecución y Seguimiento (Data Planificada vs. Real)
- **Inicio y finalización**: Control de tiempo de sesión.
- **Datos Sugeridos**: El usuario visualiza la carga y repeticiones planificadas por el profesor.
- **Datos Reales (Input del Alumno)**:
  - El alumno puede y debe ingresar los valores reales ejecutados (Kilos, Reps).
  - Estos campos son editables al momento de la ejecución.
- **Persistencia (Snapshot)**:
  - Al completar un ejercicio/día, se genera un registro histórico ("Clon" de ejecución) con los datos reales.
  - El plan original (plantilla) permanece inalterado con los valores sugeridos originales para futuros ciclos, permitiendo la comparación "Planificado vs Real".
- **Visualización de progreso**: Gráficos o listas comparativas.

### 3.4. Ciclos de Entrenamiento
- Cada asignación es un ciclo.
- Reinicio de planes preservando historial.
- Separación entre progreso activo e histórico.

### 3.5. Biblioteca de Ejercicios
- Nombre, descripción, categoría y video.
- Reutilizables en múltiples planes.

### 3.6. Gestión de Membresías
- Estados: Activa, Por vencer, Vencida.
- Cálculo automático por fechas.
- Registro manual de pagos (MVP).

## 4. Requerimientos No Funcionales

### 4.1. Stack Tecnológico
- Backend: NestJS + TypeScript.
- Base de Datos: PostgreSQL.
- Frontend: Flutter (Web y Mobile).
- Infraestructura: Docker.

### 4.2. UX/UI
- Mobile-first para alumnos.
- Dashboards para Admin y Profesor.
- Feedback visual inmediato.

### 4.3. Seguridad
- Autenticación JWT.
- Control por roles.
- Aislamiento por gimnasio.
- Protección de datos sensibles.

## 5. Roadmap
- [x] MVP validado.
- [x] Multi-tenancy.
- [x] Ejecución avanzada.
- [x] Gestión de membresías (Modelo de datos - *Falta lógica automática*).
- [ ] Reinicio de planes.
- [ ] Futuro: pagos online, analytics, notificaciones, deploy productivo.

## Estado del Documento
**Versión 1.0 – Aprobado**
