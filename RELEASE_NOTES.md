# Release Notes - v1.2.8

**Date:** 2026-01-05
**Tag:** `v1.2.8`

## 🐛 Bug Fixes

### Mobile Keyboard Whitespace (Round 8 - Final Robust Fix)
- **Issue:** Android "Back" button to dismiss keyboard leaves residual whitespace. Gesture dismiss works fine.
- **Root Cause:** Inconsistency in Android IME dismiss events affecting Flutter layout.
- **Fix:** 
    - **Flutter:** Wrapped Login body in `SafeArea` to handle system insets properly.
    - **Flutter:** Added `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag` to `SingleChildScrollView`. This allows users to intuitively dismiss the keyboard by scrolling, which is known to trigger a correct layout rebuild.
    - **Continued Support:** Retains `resizeToAvoidBottomInset: true` and the Natural Scroll (v1.2.7) web config.

## 📦 Deployment Guidance

**Frontend-only Update:**
```bash
git fetch --tags
git checkout v1.2.8
docker compose --env-file .env.prod -f infra/docker-compose.prod.yml up -d --build frontend
```
