# Release Notes - v1.2.13

**Date:** 2026-01-05
**Tag:** `v1.2.13`

## 🐛 Bug Fixes

### Mobile Touch Fix (Round 11 - Cleanup)
- **Issue:** Touch interactions became unresponsive after keyboard usage in v1.2.12.
- **Root Cause:** The JavaScript listeners added in Round 9 (`focusout` forcing scroll) were conflicting with Flutter's native gesture handling and the Manual Inset strategy from Round 10.
- **Fix:** Removed all custom JavaScript listeners from `index.html`.
- **Current Strategy:** Pure "Manual Inset" (Flutter-side only).
    - `index.html`: `interactive-widget=resizes-content` (for correct browser metrics).
    - `login_screen.dart`: `resizeToAvoidBottomInset: false` + Manual `Padding` using `MediaQuery`.

## 📦 Deployment Guidance

**Frontend-only Update:**
```bash
git fetch --tags
git checkout v1.2.13
docker compose --env-file .env.prod -f infra/docker-compose.prod.yml up -d --build frontend
```
