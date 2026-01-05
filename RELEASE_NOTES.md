# Release Notes - v1.2.2

**Date:** 2026-01-05
**Tag:** `v1.2.2`

## 🐛 Bug Fixes

### Mobile Keyboard Layout Fix
- **Issue:** On mobile web (PWA), closing the keyboard left a blank space at the bottom of the screen.
- **Fix:** Added `viewport` meta tag to `index.html` to correctly instruct mobile browsers on resize behavior.
  ```html
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
  ```

## 📦 Deployment Guidance

This is a **Frontend-only** update.
- The Backend does NOT need to be rebuilt.
- The Frontend container MUST be rebuilt to pick up the `index.html` change.

**Command:**
```bash
git fetch --tags
git checkout v1.2.2
docker compose --env-file .env.prod -f infra/docker-compose.prod.yml up -d --build frontend
```
