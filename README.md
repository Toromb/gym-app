# Gym App MVP

## Overview
Mobile application for Gym management with Profe (Teacher) and Alumno (Student) roles.
Built with NestJS (Backend) and Flutter (Frontend).

## Project Structure
- `backend/`: NestJS API
- `frontend/`: Flutter App
- `infra/`: Docker Compose configuration

## Setup

### Backend
1. Navigate to `backend/`
2. Install dependencies: `npm install`
3. Configure `.env` (copy from `.env.example` or use provided defaults)
4. Start Docker Compose for DB: `docker-compose up -d` (in `infra/`)
5. Run migrations (TypeORM sync is enabled for dev)
6. Seed data: `npm run seed` (or `npx ts-node src/seed.ts`)
7. Start server: `npm run start:dev`

### Frontend
1. Navigate to `frontend/`
2. Install dependencies: `flutter pub get`
3. Run app: `flutter run`

## API Documentation
Swagger is available at `http://localhost:3000/api` when backend is running.

## Default Users (Seed)
- Admin: admin@gym.com / admin123
- Profe: profe@gym.com / admin123
- Alumno: alumno@gym.com / admin123
