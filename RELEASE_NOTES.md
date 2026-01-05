# Release Notes - v1.2.11

**Date:** 2026-01-05
**Tag:** `v1.2.11`

## � Strategy Update: Force Flutter Framework Upgrade

### Objective
We are addressing the "Android Keyboard Whitespace" issue on two fronts:
1.  **Code Fixes (Already applied):** JS Viewport Sync + Flutter SafeArea (v1.2.10).
2.  **Framework Fix (New):** Forcing an update to the latest Flutter Stable branch, as recent reports suggest this issue may be resolved at the framework level in 2025/2026 releases.

### Deployment Instructions (CRITICAL)
This deployment uses the `--pull` flag to force Docker to download the absolute latest `cirruslabs/flutter:stable` image, ignoring any local cache.

**Frontend-only Update with Force Pull:**
```bash
git fetch --tags
git checkout v1.2.11
docker compose --env-file .env.prod -f infra/docker-compose.prod.yml build --pull frontend
docker compose --env-file .env.prod -f infra/docker-compose.prod.yml up -d frontend
```
