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


## Super Admin & Multi-tenancy (New Epic)
- [x] **Backend: Architecture & Schema**
    - [x] Create `Gym` Entity (name, address, plan, status, limits)
    - [x] Update `User` Entity (add `gym` relation, add `SUPER_ADMIN` role)
    - [x] Migration Strategy (Default Gym for existing data)
- [x] **Backend: Gym Management API**
    - [x] CRUD Gyms (`/gyms`)
    - [x] Gym Status Toggle (Active/Suspended)
- [x] **Backend: Super Admin Logic**
    - [x] Manage Gym Admins (Create, Reset Pwd, Deactivate)
    - [x] Global Dashboard Stats (Gyms, Users counts)
- [x] **Frontend: Super Admin**
    - [x] Auth & Routing (Redirect SA to separate dashboard)
    - [x] Super Admin Dashboard (Widgets)
    - [x] Gym Management (List, Create, Edit)
    - [x] Admin Management (List, Create with Gym selection)

## Workout History & Calendar (Advanced)
    - [x] Create `PlanExecution` entity (OneToMany with ExerciseExecution)
    - [x] Create `ExerciseExecution` entity (Snapshots + Real Data)
    - [x] Register in `PlansModule`
    - [x] Create `ExecutionsService` (start, complete, conflict checks)
    - [x] Create `ExecutionsController` (API endpoints)
    - [x] Verification: Create and run `verify_executions_strict.ts` (Idempotency, Conflicts, Snapshots)
    - [x] API: Get Calendar History
- [x] **Frontend: Advanced Student View**
    - [x] Service Layer: Adapt to Execution API
    - [x] Day Detail: Integrate Execution (Live metrics, snapshots)
    - [x] Calendar Screen: Monthly view + Daily history

## Maintenance & UX Improvements
- [x] **Membership Logic**: Strict anchor date calculation (Start Date determines expiration day).
- [x] **Student Features**: Restart Plan button (Cycle reset).
