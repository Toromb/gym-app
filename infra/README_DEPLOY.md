# Guía de Despliegue (Producción)

Este documento describe cómo levantar el entorno de producción que incluye la Base de Datos (PostgreSQL) y el Backend (NestJS).

## Prerrequisitos

1. Tener Docker y Docker Compose instalados.
2. Generar el archivo de configuración `.env.prod`.

## Configuración Inicial

1. Copia el archivo de ejemplo:
   ```bash
   cp .env.prod.example .env.prod
   ```
2. Edita `.env.prod` con tus credenciales reales. **IMPORTANTE**:
   - `DB_HOST` debe ser `postgres` (el nombre del servicio en docker-compose).
   - Define contraseñas seguras.

## Comandos de Despliegue

Todos los comandos se ejecutan desde la raíz del proyecto.

### Levantar Servicios
Para construir la imagen y levantar los contenedores en segundo plano.
**Nota:** Es crucial usar `--env-file .env.prod` para que las variables se sustituyan correctamente.

```bash
docker compose --env-file .env.prod -f infra/docker-compose.prod.yml up -d --build
```

### Ver Logs
Para ver qué está pasando en el backend:

```bash
docker compose -f infra/docker-compose.prod.yml logs -f backend
```

### Detener Servicios
Para detener los contenedores (conservando los datos):

```bash
docker compose --env-file .env.prod -f infra/docker-compose.prod.yml down
```

### Resetear Datos (Cuidado)
Para detener y **borrar** la base de datos (volúmenes):

```bash
docker compose --env-file .env.prod -f infra/docker-compose.prod.yml down -v
```

## Estructura

- **postgres**: Base de datos persistente. Usa el volumen `pgdata`.
- **backend**: Aplicación NestJS. Se construye desde la carpeta `backend/` y escucha en el puerto 3000 (interno).
- **frontend**: Cliente Flutter Web. Servido por Nginx en puerto 80. Proxy `/api` al backend.

## Accesos
- **Web App**: [http://localhost](http://localhost) (Puerto 80)
- **API Swagger**: [http://localhost:3005/api](http://localhost:3005/api) (Si PROD_PORT=3005)
