# Gym App Tasks

## Roles & Permissions
- [x] Implement User Roles (Admin, Profe, Alumno)
- [x] Implement Permissions (Teacher full control, Student read-only)

## Manage Students (Backend)
- [x] List Students API (`GET /users`)
- [x] Add Student API (`POST /users`)
- [x] View Student API (`GET /users/:id`)
- [x] Edit Student API (`PATCH /users/:id`)
- [x] Assign Plan API (`POST /plans/:id/assign`)

## Create Plan (Backend)
- [x] Plan Entity Structure (Plan -> Weeks -> Days -> Exercises)
- [x] Create Plan API (`POST /plans`)
- [x] List Plans API (`GET /plans`)
- [x] Fix Video URL Persistence


## Student View (Backend)
- [x] Get My Plan API (`GET /plans/student/my-plan`)

## Frontend (To Do)
- [x] Dashboard (Teacher)
- [x] Manage Students View
    - [x] List Students
    - [x] Add Student Form
    - [x] Student Details / Edit
- [x] Create Plan View
    - [x] Plan General Info Form
    - [x] Weekly Structure Builder
- [x] Student App View
    - [x] My Plan Display
    - [x] Progress Tracking (Checkboxes & Completion logic)

