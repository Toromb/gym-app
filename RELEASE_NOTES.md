# Release Notes - v1.2.12

**Date:** 2026-01-05
**Tag:** `v1.2.12`

## 🐛 Bug Fixes

### Mobile Keyboard Whitespace (Round 10 - Manual Control)
- **Issue:** Persistent whitespace/viewport desync on Android Chrome when using the "Back" button to close the keyboard.
- **Fix:** Switched to a fully manual keyboard management strategy.
    - **Disabled Auto-Resize:** `resizeToAvoidBottomInset: false` stops Flutter from relying on the browser's viewport signals for layout resizing.
    - **Manual Padding:** Implemented a direct `Padding` widget that applies `MediaQuery.of(context).viewInsets.bottom`. This forces the layout to respect the keyboard height mathematically, independent of browser heuristics.
- **Note:** This strategy is browser-agnostic and relies on Flutter's internal engine to detect keyboard metrics.

## 📦 Deployment Guidance

**Frontend-only Update:**
```bash
git fetch --tags
git checkout v1.2.12
docker compose --env-file .env.prod -f infra/docker-compose.prod.yml up -d --build frontend
```
