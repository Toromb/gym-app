# Release Notes - v1.2.14

**Date:** 2026-01-05
**Tag:** `v1.2.14`

## 🐛 Bug Fixes

### Stability & Touch Interaction (Round 12 - Clean Slate)
- **Issue:** Previous attempts to fix the whitespace bug resulted in unresponsive touch interactions ("locking") due to conflicting scroll mechanisms (Browser vs. Flutter).
- **Fix:** Restored a standard, clean configuration strictly following Flutter Web best practices.
- **Changes:**
    - **`index.html`:**
        - `overflow: hidden`: **Critically important.** Prevents the browser from handling scroll, ensuring Flutter's Gesture Arena receives all touch events. This fixes the "locked" UI.
        - `overscroll-behavior: none`: Adds "bounce" protection.
        - `interactive-widget=resizes-content`: Retained for modern keyboard metrics.
    - **`login_screen.dart`:**
        - **Reverted** Manual Inset Strategy.
        - **Restored** `resizeToAvoidBottomInset: true`.
        - **Retained** `SafeArea` and `onDrag` dismiss.

## 📦 Deployment Guidance

**Frontend-only Update:**
```bash
git fetch --tags
git checkout v1.2.14
docker compose --env-file .env.prod -f infra/docker-compose.prod.yml up -d --build frontend
```
