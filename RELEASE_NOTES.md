# Release Notes - v1.2.10

**Date:** 2026-01-05
**Tag:** `v1.2.10`

## 🐛 Bug Fixes

### Mobile Keyboard Whitespace (Round 9 - Viewport Sync)
- **Issue:** Chrome Android "Back button" dismisses keyboard without always triggering a full layout recalculation, leaving whitespace.
- **Fix:** Added JavaScript listeners to `index.html` to force synchronization:
    1.  **Visual Viewport API:** Listens for `resize` events on `window.visualViewport` and explicitly sets `document.body.style.minHeight`.
    2.  **FocusOut Hack:** Listens for `focusout` on inputs (keyboard closing) and triggers a `window.scrollTo(0,0)` to force a browser repaint.
- **Includes:** Previous Flutter-side improvements (SafeArea, Dismiss on Drag).

## 📦 Deployment Guidance

**Frontend-only Update:**
```bash
git fetch --tags
git checkout v1.2.10
docker compose --env-file .env.prod -f infra/docker-compose.prod.yml up -d --build frontend
```
