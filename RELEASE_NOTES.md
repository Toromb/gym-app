# Release Notes - v1.2.7

**Date:** 2026-01-05
**Tag:** `v1.2.7`

## 🐛 Bug Fixes

### Mobile Keyboard Whitespace (Round 7 - Natural Scroll)
- **Issue:** Fixed 100% height and disabled scrolling caused viewport resizing issues in Chrome Android ("Keyboard overlap").
- **Fix:** 
    - **Strategy:** "Natural Scroll" (Recommended by user research).
    - **CSS:** `min-height: 100dvh` ensures full viewport coverage but allows growth.
    - **CSS:** `overflow-y: auto` allows the browser to handle content displacement naturally when the keyboard appears.
    - **CSS:** `overflow-x: hidden` prevents horizontal shift.
    - **Theme:** Matched html/body background color to app theme (`#F8FAFC`).

## 📦 Deployment Guidance

**Frontend-only Update:**
```bash
git fetch --tags
git checkout v1.2.7
docker compose --env-file .env.prod -f infra/docker-compose.prod.yml up -d --build frontend
```
