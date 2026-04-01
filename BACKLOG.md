# 📝 TuGymFlow - Backlog de Tareas Futuras

Este documento mantiene un registro de las mejoras técnicas, refactorizaciones y deuda técnica planeadas para ser abordadas a futuro, categorizadas por su criticidad o impacto.

## 🔴 Alta Prioridad (Seguridad y Producción)
- **Monitoreo de Errores y Crash Analytics:** Integrar **Sentry** (Backend) y **Firebase Crashlytics / Sentry** (Frontend/Flutter) para capturar pantallazos rojos y excepciones silenciosas en tiempo real en dispositivos reales de los alumnos.

## 🟡 Prioridad Media (Automatización y Escalabilidad)
- **Implementar Integración y Despliegue Continuo (CI/CD):** Mover los despliegues de scripts locales de PowerShell (`deploy_vps.ps1`, `align_branches.ps1`) a una canalización automatizada mediante GitHub Actions o GitLab CI, asegurando que cada *push* pase tests antes de ir a producción.

## 🟢 Prioridad Baja (Mantenimiento y Deuda Técnica)
- **Hooks de Git (Husky & lint-staged):** Asegurar que ningún desarrollador pueda hacer un `commit` si su código de NestJS o Flutter no pasa las reglas de linting y formateo (Prettier).
- **Evolución del Gestor de Estado Frontend:** Analizar la viabilidad a muy largo plazo de migrar de `Provider` a un gestor robusto diseñado para inyección de dependencias estricta (como `Riverpod` o `BLoC`), especialmente cuando el manejo de caché y sincronización offline crezca.
