# Release Notes - v1.2.5

**Date:** 2026-01-05
**Tag:** `v1.2.5`

## 🐛 Bug Fixes

### Mobile Keyboard Whitespace (Round 4)
- **Issue:** v1.2.4 caused additional layout issues ("worse" state).
- **Fix:** 
    - **Reverted:** `resizeToAvoidBottomInset` set back to `true` (letting Flutter handle safe areas).
    - **JS Scroll Lock:** Added `window.scrollTo(0, 0)` listener to prevent the elusive "PWA scroll drift" where the browser shifts the body element.
    - **CSS:** Switched body height to `100dvh` for better mobile support.

## 📦 Deployment Guidance

**Frontend-only Update:**
```bash
git fetch --tags
git checkout v1.2.5
docker compose --env-file .env.prod -f infra/docker-compose.prod.yml up -d --build frontend
```
