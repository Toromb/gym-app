"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PlansModule = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const plans_controller_1 = require("./plans.controller");
const plans_service_1 = require("./plans.service");
const plan_entity_1 = require("./entities/plan.entity");
const plan_week_entity_1 = require("./entities/plan-week.entity");
const student_plan_entity_1 = require("./entities/student-plan.entity");
const exercises_module_1 = require("../exercises/exercises.module");
const users_module_1 = require("../users/users.module");
const plan_execution_entity_1 = require("./entities/plan-execution.entity");
const exercise_execution_entity_1 = require("./entities/exercise-execution.entity");
const executions_controller_1 = require("./executions.controller");
const executions_service_1 = require("./executions.service");
let PlansModule = class PlansModule {
};
exports.PlansModule = PlansModule;
exports.PlansModule = PlansModule = __decorate([
    (0, common_1.Module)({
        imports: [
            typeorm_1.TypeOrmModule.forFeature([
                plan_entity_1.Plan,
                plan_week_entity_1.PlanWeek,
                plan_entity_1.PlanDay,
                plan_entity_1.PlanExercise,
                student_plan_entity_1.StudentPlan,
                plan_execution_entity_1.PlanExecution,
                exercise_execution_entity_1.ExerciseExecution
            ]),
            exercises_module_1.ExercisesModule,
            users_module_1.UsersModule,
        ],
        controllers: [plans_controller_1.PlansController, executions_controller_1.ExecutionsController],
        providers: [plans_service_1.PlansService, executions_service_1.ExecutionsService],
        exports: [plans_service_1.PlansService],
    })
], PlansModule);
//# sourceMappingURL=plans.module.js.map