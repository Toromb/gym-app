# Release Notes - v1.2.9

**Date:** 2026-01-05
**Tag:** `v1.2.9`

## 🐛 Bug Fixes

### Hotfix: Compilation Error
- **Issue:** v1.2.8 failed to build due to a missing parenthesis in `login_screen.dart`.
- **Fix:** Corrected syntax error.
- **Includes:** All fixes from v1.2.8 (SafeArea, Keyboard Dismiss on Drag).

## 📦 Deployment Guidance

**Frontend-only Update:**
```bash
git fetch --tags
git checkout v1.2.9
docker compose --env-file .env.prod -f infra/docker-compose.prod.yml up -d --build frontend
```
