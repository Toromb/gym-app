# Release Notes - v1.2.6

**Date:** 2026-01-05
**Tag:** `v1.2.6`

## 🐛 Bug Fixes

### Mobile Keyboard Whitespace (Round 6 - The Nuclear Option)
- **Issue:** Document `<body>` was scrolling up when keyboard opened but not returning correctly, causing persistent white space.
- **Fix:** 
    - Applied `position: fixed; inset: 0;` to `<body>`.
    - This creates a rigid container that cannot be scrolled by the browser. 
    - Relies entirely on `interactive-widget=resizes-content` to resize the view.

## 📦 Deployment Guidance

**Frontend-only Update:**
```bash
git fetch --tags
git checkout v1.2.6
docker compose --env-file .env.prod -f infra/docker-compose.prod.yml up -d --build frontend
```
