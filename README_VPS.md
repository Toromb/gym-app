# 🚀 Gym App - VPS Deployment Guide

This guide details how to deploy the Gym App on a Virtual Private Server (VPS) running Ubuntu (or similar Linux).

## Prerequisites

- **VPS**: Minimum 4GB RAM (Required for building Flutter Web inside Docker).
- **Docker & Docker Compose**: Installed on the VPS.
- **Git**: Installed on the VPS.

## 1. Clone the Repository

```bash
git clone <YOUR_REPO_URL>
cd gym_app
```

## 2. Environment Configuration

You must create the production environment file.

```bash
cp .env.prod.example .env.prod
```

**Edit `.env.prod` with your secure credentials:**
```bash
nano .env.prod
```
*   Set a strong `DB_PASSWORD`.
*   Set a strong `JWT_SECRET`.
*   ensure `DB_HOST=postgres` (Required for Docker networking).

## 3. Deploy

Run the following command to build and start the services. 
*Note: The first run will take a few minutes as it downloads the Flutter SDK and compiles the web application.*

```bash
docker compose --env-file .env.prod -f infra/docker-compose.prod.yml up -d --build
```

## 4. Verification

1.  **Check Status**:
    ```bash
    docker compose -f infra/docker-compose.prod.yml ps
    ```
    Ensure `gym_app_backend_prod`, `gym_app_frontend_prod`, and `gym_app_db_prod` are `Up`.

2.  **Access the App**:
    Open your browser and navigate to `http://<VPS_IP_ADDRESS>`.
    You should see the Gym App login screen.

## Troubleshooting

*   **Logs**: To see what's happening:
    ```bash
    docker compose -f infra/docker-compose.prod.yml logs -f
    ```
*   **Database Connection**: If backend fails to connect, ensure `DB_HOST=postgres` in `.env.prod`.
*   **Permissions**: Ensure `pgdata` volume is writable (Docker usually handles this).

## Security Notes

*   **Database**: Port 5432 is NOT exposed to the internet. It is only accessible inside the Docker network.
*   **Backend**: Port 3000 is exposed to the host but mapped effectively to the internal network for Nginx. (Note: Nginx proxies requests, so 3000 doesn't strictly need to be exposed to the *public* internet if you have a firewall/UFW. Only port 80/443 is needed publicly).
    *   *Recommendation*: Configure UFW to allow only 80/443/22.
