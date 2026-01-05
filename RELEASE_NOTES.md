# Release Notes - v1.2.4

**Date:** 2026-01-05
**Tag:** `v1.2.4`

## 🐛 Bug Fixes

### Mobile Keyboard Whitespace (Round 3)
- **Issue:** Viewport adjustments alone were not consistent across all devices.
- **Fix:** 
    - Disabled Flutter's `resizeToAvoidBottomInset` in `LoginScreen`.
    - Strategy: Rely fully on the browser's viewport resizing (configured in v1.2.3) rather than having Flutter attempt to calculate insets, avoiding double-resizing conflicts.

## 📦 Deployment Guidance

**Frontend-only Update:**
```bash
git fetch --tags
git checkout v1.2.4
docker compose --env-file .env.prod -f infra/docker-compose.prod.yml up -d --build frontend
```
