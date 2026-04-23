# TuGymFlow - Reglas de Negocio

## 1. Principios Core (Core Principles)
* La plataforma está diseñada exclusivamente para la gestión de gimnasios (modelo B2B).
* Todo acceso al sistema debe estar asociado al menos a un gimnasio activo; no existe el registro público independiente.
* Al momento de su creación, cada usuario debe quedar vinculado explícitamente a un recinto deportivo.
* Los alumnos nuevos ingresan exclusivamente mediante invitación del gimnasio (vía código QR o enlace).
* El escaneo del QR actúa como el método principal y óptimo de onboarding para alumnos.

## 2. Identidad del Usuario e Historial (User Identity & History)
* El historial de entrenamiento es propiedad exclusiva e inalienable del alumno, independientemente del gimnasio donde se haya generado.
* Si el alumno cambia de gimnasio, su historial deportivo debe permanecer intacto y disponible para él en todo momento.
* Este historial debe ser accesible por:
  * El propio alumno.
  * El profesor actual asignado a su seguimiento.
  * El administrador del gimnasio vigente del usuario.
* El historial abarca:
  * Histórico de planes ejecutados y finalizados.
  * Nivel y progresión atlética del alumno.
  * Métricas y datos físicos particulares relevantes para su entrenamiento.

## 3. Multi-Gimnasio: Visión a Futuro (Multi-Gym Direction)
* Estado actual: Un usuario solo puede pertenecer a un gimnasio en el sistema.
* Visión técnica: El diseño debe contemplar asociaciones múltiples, donde un perfil único pueda inscribirse en diversos establecimientos simultáneamente a futuro.
* Aislamiento de datos (Multi-tenancy): Toda la información operativa (planes de la sede, ejercicios privados, facturación) debe estar estrictamente segregada y encapsulada por gimnasio.
* No existirá el cruce o fuga de datos administrativos, financieros ni de configuración de rutinas entre distintos clientes comerciales.

## 4. Sistema de Entrenamiento (Training System)

### 4.1. Estructura de Planes
* Los planes funcionan como plantillas prearmadas creadas por roles ADMIN o PROFE.
* La asignación originaria en el sistema no implica clonación de datos de manera explícita visible al usuario.
* El motor permite que un alumno tenga un conjunto múltiple de planes asignados a su perfil.

### 4.2. Ejecución de Planes
* El alumno solo tiene permitido ejecutar y accionar un plan en estado activo/en curso a la vez.
* Cualquier plan adicional en cola queda suspendido bajo estado "pendiente".
* Al terminar un plan activo, se le habilita al alumno la elección de cuál de sus planes en reserva consumirá a continuación.

### 4.3. Modificación de Planes
* Las ediciones estructurales sobre una plantilla base (Plan) NO deben alterar la vista ni ejecución de los alumnos que ya han recibido dicho plan.
* Toda nueva asignación debe operar lógicamente como un *snapshot* o copia fotográfica independiente de la plantilla original al momento exacto de entregarse.

### 4.4. Finalización e Historial
* Una vez concluido y cerrado un plan, se debe consolidar una copia fiel, inmutable y definitiva del mismo.
* Esta bitácora histórica registrará la ejecución de campo, detallando:
  * Ejercicios efectivamente realizados vs encomendados.
  * Variaciones aplicadas sobre los ejercicios.
  * Cargas (pesajes) reales utilizados.
  * Volumen y cantidad de repeticiones completadas.
  * Timestamps y fechas exactas.
* Se establece la inmutabilidad absoluta de este registro post-guardado final.

### 4.5. Reinicio de Planes
* Al solicitar reiniciar un circuito (Plan), el estado de partida es la configuración inicial aséptica originalmente asignada por el staff.
* Las ejecuciones previas de ese plan quedan blindadas en el historial y no son vulneradas ni sobrescritas por el reseteo operativo.

## 5. Roles y Permisos (Roles & Permissions)

Roles habilitados en arquitectura:
* **SUPER_ADMIN**: Superusuario técnico general.
* **ADMIN**: Dueño, inversor o director de un recinto específico.
* **PROFE**: Instructor y estratega deportivo.
* **ALUMNO**: Cliente / consumidor del centro.

### 5.1. ADMIN
* Autoridad magna sobre la gestión total de la sucursal.
* Facultades principales:
  * Control y mutación del personal y clientes de su gimnasio.
  * Administración, validación y mutación de finanzas y caja.
  * Creación sistemática de librerías de planes de entrenamiento.
  * Transparencia de lectura absoluta de data del gimnasio.

### 5.2. PROFE
* Rol anclado focalmente hacia la operación en piso y coaching.
* Facultades principales:
  * Diagramación de circuitos, edición de su biblioteca y asignación manual.
* Restricciones estrictas:
  * Nula manipulación de finanzas, vencimientos o estados de cuota contables.
  * Bloqueo en la eliminación o depreciación de la base de registros de "ejercicios" macro y crudos.
  * Sin acceso ni permiso a modificaciones estructurales administrativas.

### 5.3. ALUMNO
* Rol delimitado por la lectura de valor y usabilidad final.
* Facultades principales:
  * Ejecutar métricas y check-ins en la terminal de rutinas temporales.
  * Checar indicadores de progreso personal.
  * Alertar y revisar visualmente el estado contable corriente de la suscripción.
* Restricciones: Imposibilitado a un 100% de alterar data basal, topológica u operativa del marco arquitectónico.

## 6. Membresías y Pagos (Memberships & Payments)

### 6.1. Modelo Actual (MVP)
* La membresía es un atributo directo ligado a la ficha base del usuario.
* Ciclo de vida del estado de flujo económico:
  * **Pagado**: Transcurrido y salvado mediante abono.
  * **Por vencer**: Zona buffer/gracia latente.
  * **Vencido**: Agotamiento de ventana y omisión sin pago.
* En su etapa MVP temprana, el sistema no acumula el lastre transaccional crónico mes a mes (No Deuda Acumulativa).
* La mecánica orbital mensual está cimentada y atada de forma íntegra al día oficial de inscripción (`membershipStartDate`).
* Lógica práctica de ventana (Ej: mes iniciando un día 1):
  * Días 1 al 10 en calendario: Refleja inercia del estado "Por vencer" sin coartar accesibilidad plena.
  * Día 11 en adelante en calendario: Conmuta al semáforo de bloqueo o advertencia "Vencido" en tanto el staff no concilie.
* Transición inter-mes (Roll-over temporal): El vencimiento anterior se evapora puramente visual en la IU al inicio de otra fecha 1 natural, recayendo en la zona "Por vencer" (días 1 al 10).
* Un alumno persistente en morosidad mantendrá de manera plana y rígida la entidad visual del "Vencido" tras la ventana de diez días sin salvamentos técnicos sistémicos.
* Con la liquidación acreditada por la gerencia, el flanco permuta y solidifica al flag "Pagado".

### 6.2. Lógica de Pagos
* El cálculo aritmético de periodo y estados se desprende puramente de evaluar la distancia respecto a la fecha `membershipStartDate`.
* Controles base para deducción determinística de la ecuación contable: `membershipStartDate`, `membershipExpirationDate` y la constante de bypass (`paysMembership`).
* Excepcionalidad de negocio: El mandato real actual descansa íntegramente sobre la *fotografía mensual presente* contigua, sin recaer sobre auditorías de deuda vieja para propósitos de viabilidad de pase o puerta.

### 6.3. Privilegios Financieros
* La facultad técnica para imputar, mutar o blanquear las flags de pago recae exclusivametnte en la credencial funcional `ADMIN`.

### 6.4. Evolución de Pagos
* La meta expansiva es la injerencia holística y real de terceras terminales (p.ej., pasarelas on-ramp Stripe o MercadoPago).
* Vertices a solventar obligatoriamente en iteración posterior:
  * Consolidación estructurada en una base de datos tabular del historial robusto de cajas y pagos.
  * Ponderación matemática de moratorias compuestas intermensuales y saldos de deuda en remanente.
  * Orquestación programada de debitos cíclicos o suscripciones nativas.

## 7. Onboarding
* Experiencia de apertura curada direccionalmente. Separación de ecosistemas de ingreso:
  * **ADMIN** → Senda programática para erigir las primitivas topológicas, contables y visuales del core gimnasio.
  * **PROFE** → Rampa de inducción orientada a la mecánica operativa de inyeccion de entrenamientos y captura de librerías.
  * **ALUMNO** → Unificación, pureza y velocidad: ingreso inmediato a rutinas a través de scan o hipervínculo profundo.
* Este canal requiere refactor y auditoría continua de experiencia por ser el cono transaccional primario de enganche y conversión más endeble al día de hoy.

## 8. Foco del Producto (Product Focus)
* Núcleo duro: Framework administrativo y operativo multi-escalable para instalaciones físicas y franquicias fitness de índole integral.
* Límite Crítico: Operar como blindaje en ingresos económicos, seguimiento de flujos y estado nominal contable.
* Radiografía superficial de debilidades perentorias a parchar:
  1. Onboarding de adquisición para usuarios satélite.
  2. Coherencia global UX e Interfaces visuales amigables de retención final.
  3. Escalabilidad contable sistémica aséptica y blindada.

## 9. Modelo de Acceso (Access Model)
* Imposibilidad absoluta y categórica de penetrar la plataforma sin token referencial del dominio de un local.
* Escáner QR de token presencial en instalaciones es vital para el funnel B2B2C.
* Topologías a bifurcar o sondear en release futuro:
  * Redes y credenciales agnósticas (Entrenadores Free-lance, freelancers nómadas sin locación monolítica estática).
  * Consumidores self-service huérfanos y direct-to-consumer (sin paraguas administrativo y B2B).

## 10. Reglas Críticas Inquebrantables (DO NOT BREAK)
* Ninguna fusión de base o update debe corromper el diseño de silo de cliente o estropear la barrera *Multi-tenancy* per origin de gimnasio.
* No permitir, bajo ningún esquema, registro e ingreso auto-gestivo flotante si no es portando código de sede.
* **Proscrito radicalmente que el Update y PATCH funcional de la librería Plan destruya, reemplace, sobre-escriba y contamine una asignación en curso ya dada en el dominio del teléfono receptor.**
* Protección militar del banco de historial biológico del alumno: no debe decaer ni ante baja definitiva, exilio, baneo ni traslados multi-sede del cliente emisor.
* Absoluto blindaje del JWT, Refresh Auth Tokens y secuestros de sesión en los servicios middleware.
* Ni en modo debug, ni en modo testeo comercial deben presentarse logs de flujos nominales de data ajena de otra franquicia o centro sobre usuarios de gerencias antagónicas cruzadas paralelos.

---

## 11. IMPLEMENTATION RISKS
> Observaciones Técnicas y de Arquitectura basadas en el estado actual del Código Válidos para refactor a futuro.

1. **Aislamiento Multi-Gym vs. Arquitectura de Base de Datos actual:**
   * La entidad `User` actual hospeda directamente al `gymId` acoplado con `membershipStartDate`, `membershipExpirationDate`, y `paymentStatus`.
   * **Problema Proyectado**: Desbloquear que un usuario integre dos gimnasios de forma sincrónica derivará en un fallo o cruce de estados en la DB de este esquema rígido de columnas nativas en usuario. 
   * **Mitigación recomendada**: Centralizar estos ejes temporales y financieros hacia un "Bridge Entity" robusto: la tabla `UserMembershipTracker` o `UserGymSubscription`, desacoplando completamente pagos de identidad universal.

2. **Snapshot Real vs. Ficción Categórica en el Código (La Ilusión de los Planes):**
   * Pese a la regla de oro **4.3**, los estudiantes acceden a la rutina conectándose unívocamente vía ForeignKey a la instancia maestro en la DB (`planId` anclado dentro de `StudentPlan`). Al generarse Mutaciones REST/GraphQL (`PlansService.update`), estas modificaciones atacan estructuralmente los días (`PlanDay`) y ejercicios (`PlanExercise`) que el alumno activamente interpela leyendo.
   * **Problema Proyectado**: Cambios retroactivos involuntarios en sets y repeteciones paralizan o alteran la percepción de progresión histórica de la rutina en el consumidor al estar consumiendo una instancia mutante y "No Clónica".
   * **Mitigación recomendada**: Forzar una transpilación profunda en backend que instancie la totalidad del árbol (`Plan`, `PlanWeek`, `Day`, `Exercise`) hacia un bloque puramente aislado referenciado por el `isTemplate: false`.

3. **Inmutabilidad de Track Record Vs Status JSON (`progress`):**
   * El andamio estipula como regla inquebrantable que (REGLA 4.4) la bitácora es inviolable y la ejecución es el patrimonio de retención personal físico. En contraste a esta regla, la metadata de cierre aséptica actualmente subsiste encapsulada como sub-nodo serializado JSONB en la columna `progress: { exercises: { ... } }`.
   * **Problema Proyectado**: Buscar en la analítica de BI interna si Carlos superó su carga global de 100Kg en prensa descansa sobre búsquedas sub-óptimas no indexadas con Json. Y, por consiguiente, si el plan madre se purga (aunque el ORM no lo permita porque `activeAssignments` lo prohíbe mediante Cascade/Protect), o sí los logs exigen escalada atómica, la escalabilidad peligra frente a esta fragilidad tabular.
   * **Mitigación recomendada**: Implementar el módulo analítico `TrainingSessionData` y `TrainingSessionSets` para desacoplar y estibar los logs atómicos del alumno frente a mutabilidad estructural del sistema o desasignaciones a nivel capa relacional.

4. **Escalabilidad de Caja a Futuro (Ciclo vs Transacción Dura):**
   * El motor procesa "status de finanzas" a partir de evaluación determinista sobre variables fijas en el backend. Sin entidad `Invoices` u transacciones físicas inmutables como entidades auditables propias (`Payments`). Lógica de negocio es validada sobre el aire desde la base de `User`.
   * **Problema Proyectado**: Implementables futuros, pagos de dos o cinco meses por anticipado como abonos, reintegros monetarios, y devoluciones bancarias estrellarán al proyecto cuando Stripe retorne códigos de disputa y la base de datos se de contra el muro con estados on-the-fly (`PENDING` y variables fecha puras temporales) en lugar de un rastro sólido de auditoría (`Receipt / Orders / Subscriptions Invoices`).
