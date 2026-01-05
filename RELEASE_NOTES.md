# Release Notes - v1.2.3

**Date:** 2026-01-05
**Tag:** `v1.2.3`

## 🐛 Bug Fixes

### Mobile Keyboard Whitespace (Round 2)
- **Issue:** Previous fix (`viewport` meta tag only) was insufficient on some devices.
- **Fix:** 
    - Added `interactive-widget=resizes-content` to `viewport` meta tag (Specific to Chrome Android behavior).
    - Enforced `body { overflow: hidden; overscroll-behavior: none; }` via CSS to prevent elastic overscrolling effect.

## 📦 Deployment Guidance

**Frontend-only Update:**
```bash
git fetch --tags
git checkout v1.2.3
docker compose --env-file .env.prod -f infra/docker-compose.prod.yml up -d --build frontend
```
