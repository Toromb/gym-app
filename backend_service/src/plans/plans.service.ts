import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Plan, PlanDay, PlanExercise } from './entities/plan.entity';
import { PlanWeek } from './entities/plan-week.entity';
import { StudentPlan } from './entities/student-plan.entity';
import { User, UserRole } from '../users/entities/user.entity';
import { CreatePlanDto } from './dto/create-plan.dto';
import { UpdatePlanDto } from './dto/update-plan.dto';
import { AssignedPlan } from './entities/assigned-plan.entity';
import { AssignedPlanWeek } from './entities/assigned-plan-week.entity';
import { AssignedPlanDay } from './entities/assigned-plan-day.entity';
import { AssignedPlanExercise } from './entities/assigned-plan-exercise.entity';
import { AssignedPlanMapper } from './dto/assigned-plan.mapper';

@Injectable()
export class PlansService {
  private readonly logger = new Logger(PlansService.name);

  constructor(
    @InjectRepository(Plan)
    private plansRepository: Repository<Plan>,
    @InjectRepository(StudentPlan)
    private studentPlanRepository: Repository<StudentPlan>,
  ) { }

  async create(createPlanDto: CreatePlanDto, teacher: User): Promise<Plan> {
    // Map DTO to Entities
    const plan = new Plan();
    plan.name = createPlanDto.name;
    plan.objective = createPlanDto.objective;
    plan.durationWeeks = createPlanDto.durationWeeks;
    plan.generalNotes = createPlanDto.generalNotes;
    plan.teacher = teacher;
    plan.weeks = createPlanDto.weeks.map((w) => {
      const week = new PlanWeek();
      week.weekNumber = w.weekNumber;
      week.days = w.days.map((d) => {
        const day = new PlanDay();
        day.title = d.title;
        day.dayOfWeek = d.dayOfWeek;
        day.order = d.order;
        day.dayNotes = d.dayNotes;
        if (d.trainingIntent) day.trainingIntent = d.trainingIntent;
        day.week = week; // Back reference
        day.exercises = d.exercises.map((e) => {
          const exercise = new PlanExercise();
          exercise.sets = e.sets;
          exercise.reps = e.reps;
          exercise.suggestedLoad = e.suggestedLoad;
          exercise.rest = e.rest;
          exercise.notes = e.notes;
          exercise.videoUrl = e.videoUrl;
          exercise.targetTime = e.targetTime;
          exercise.targetDistance = e.targetDistance;
          exercise.order = e.order;
          exercise.exercise = { id: e.exerciseId } as any;
          exercise.day = day; // Back reference
          if (e.equipmentIds && e.equipmentIds.length > 0) {
            exercise.equipments = e.equipmentIds.map((eqId: string) => ({ id: eqId } as any));
          }
          return exercise;
        });
        return day;
      });
      week.plan = plan; // Back reference
      return week;
    });

    const saved = await this.plansRepository.save(plan);
    return this.findOne(saved.id) as Promise<Plan>;
  }

  async findAll(gymId?: string): Promise<Plan[]> {
    const query = this.plansRepository
      .createQueryBuilder('plan')
      .leftJoinAndSelect('plan.weeks', 'weeks')
      .leftJoinAndSelect('weeks.days', 'days')
      .leftJoinAndSelect('days.exercises', 'exercises')
      .leftJoinAndSelect('exercises.exercise', 'exercise')
      .leftJoinAndSelect('plan.teacher', 'teacher')
      .leftJoinAndSelect('teacher.gym', 'gym');

    if (gymId) {
      // console.log(`[PlansService] Filtering plans by Gym ID: ${gymId}`);
      query.where('gym.id = :gymId', { gymId });
    } else {
      // console.log('[PlansService] No Gym ID filter provided');
    }

    return query.getMany();
  }

  async findAllByTeacher(teacherId: string): Promise<Plan[]> {
    return this.plansRepository.find({
      where: { teacher: { id: teacherId } },
      relations: [
        'weeks',
        'weeks.days',
        'weeks.days.exercises',
        'weeks.days.exercises.exercise',
      ],
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Plan | null> {
    return this.plansRepository.findOne({
      where: { id },
      relations: [
        'weeks',
        'weeks.days',
        'weeks.days.exercises',
        'weeks.days.exercises.exercise',
        'weeks.days.exercises.equipments',
        'teacher',
      ],
    });
  }



  async assignPlan(planId: string, studentId: string, assigner: User): Promise<StudentPlan> {
    const plan = await this.findOne(planId);
    if (!plan) throw new NotFoundException('Plan not found');

    // Validate Plan Ownership (Allow own plans OR Admin/Global plans OR if Assigner is Admin)
    const planTeacherId = plan.teacher?.id;
    const planTeacherRole = plan.teacher?.role;
    const isAssignerAdmin = assigner.role === UserRole.ADMIN || assigner.role === UserRole.SUPER_ADMIN;

    // Allow if:
    // 1. Plan belongs to the assigner
    // 2. Plan belongs to an Admin (Global) (and user can see it)
    // 3. Assigner is Admin (can assign any plan)

    const isOwner = planTeacherId === assigner.id;
    const isAdminPlan = planTeacherRole === UserRole.ADMIN || planTeacherRole === UserRole.SUPER_ADMIN;

    if (!isOwner && !isAdminPlan && !isAssignerAdmin) {
      throw new ForbiddenException('You can only assign your own plans or library plans');
    }

    // Validate Student Ownership 
    const student = await this.plansRepository.manager.findOne(User, { where: { id: studentId }, relations: ['professor', 'gym'] });
    if (!student) throw new NotFoundException('Student not found');

    const studentPlan = this.studentPlanRepository.create({
      plan: { id: planId } as any,
      student: { id: studentId } as any,
      assignedAt: new Date().toISOString(),
      startDate: new Date().toISOString(), // Default to today
      isActive: true,
    });

    const assignedPlan = new AssignedPlan();
    assignedPlan.originalPlanId = plan.id;
    assignedPlan.originalPlanName = plan.name;
    assignedPlan.assignedAt = new Date();
    assignedPlan.assignedByUserId = assigner.id;
    assignedPlan.name = plan.name;
    assignedPlan.description = plan.description;
    assignedPlan.objective = plan.objective;
    assignedPlan.generalNotes = plan.generalNotes;
    assignedPlan.durationWeeks = plan.durationWeeks;

    assignedPlan.weeks = (plan.weeks || []).map(w => {
      const assignedWeek = new AssignedPlanWeek();
      assignedWeek.weekNumber = w.weekNumber;
      assignedWeek.days = (w.days || []).map(d => {
        const assignedDay = new AssignedPlanDay();
        assignedDay.title = d.title;
        assignedDay.dayOfWeek = d.dayOfWeek;
        assignedDay.order = d.order;
        assignedDay.trainingIntent = d.trainingIntent;
        assignedDay.dayNotes = d.dayNotes;
        assignedDay.exercises = (d.exercises || []).map(e => {
          const assignedEx = new AssignedPlanExercise();
          assignedEx.exercise = e.exercise;
          assignedEx.sets = e.sets;
          assignedEx.reps = e.reps;
          assignedEx.suggestedLoad = e.suggestedLoad;
          assignedEx.rest = e.rest;
          assignedEx.notes = e.notes;
          assignedEx.videoUrl = e.videoUrl;
          assignedEx.targetTime = e.targetTime;
          assignedEx.targetDistance = e.targetDistance;
          assignedEx.order = e.order;
          assignedEx.equipments = e.equipments || [];
          return assignedEx;
        });
        return assignedDay;
      });
      return assignedWeek;
    });

    return this.plansRepository.manager.transaction(async transactionalEntityManager => {
      const savedAssignedPlan = await transactionalEntityManager.save(AssignedPlan, assignedPlan);
      studentPlan.assignedPlan = savedAssignedPlan;
      return await transactionalEntityManager.save(StudentPlan, studentPlan);
    });
  }

  async update(
    id: string,
    updatePlanDto: UpdatePlanDto,
    user: User,
  ): Promise<Plan> {
    const plan = await this.findOne(id);
    if (!plan) throw new NotFoundException('Plan not found');

    // Simple update scalars
    plan.name = updatePlanDto.name ?? plan.name;
    plan.objective = updatePlanDto.objective ?? plan.objective;
    plan.durationWeeks = updatePlanDto.durationWeeks ?? plan.durationWeeks;
    plan.generalNotes = updatePlanDto.generalNotes ?? plan.generalNotes;

    return await this.plansRepository.manager
      .transaction(async (transactionalEntityManager) => {
        // Full structure replacement with ID preservation (Diff & Sync)
        if (updatePlanDto.weeks && updatePlanDto.weeks.length > 0) {
          // --- 1. SYNC WEEKS ---
          const incomingWeeks = updatePlanDto.weeks;
          const incomingWeekIds = incomingWeeks.map(w => w.id).filter(id => !!id);

          // Delete missing weeks
          const existingWeeks = plan.weeks || [];
          const weeksToDelete = existingWeeks.filter(w => w.id && !incomingWeekIds.includes(w.id));
          if (weeksToDelete.length > 0) {
            await transactionalEntityManager.delete(PlanWeek, weeksToDelete.map(w => w.id));
          }

          // Upsert Weeks
          const processedWeeks: PlanWeek[] = [];

          for (const wDto of incomingWeeks) {
            let weekEntity = wDto.id ? existingWeeks.find(ew => ew.id === wDto.id) : null;

            if (!weekEntity) {
              weekEntity = new PlanWeek();
              // If it had an ID but not found in DB, it might be a new ID or error. Treat as new.
              // Actually if wDto.id is present but not in DB, TypeORM update will fail or creaet if strict is false. 
              // Better to let TypeORM handle 'save' but we must prepare relationships.
            }

            weekEntity.weekNumber = wDto.weekNumber;
            weekEntity.plan = plan;

            // We must save the week first to have an ID if it's new, OR we can rely on cascade? 
            // Cascade is safer for deep structures, but for Deletion we needed manual manual handling above.
            // Let's attempt to build the graph and save the Plan? 
            // Problem: if we rely on cascade for everything, we must remove orphans from the array. 
            // TypeORM cascade update is sometimes tricky with orphans. 
            // Explicit handling is more robust.

            const savedWeek = await transactionalEntityManager.save(PlanWeek, weekEntity);

            // --- 2. SYNC DAYS ---
            const incomingDays = wDto.days;
            const incomingDayIds = incomingDays.map(d => d.id).filter(id => !!id);

            // Fetch existing days if we just saved/loaded the week. 
            // Since we might have mutated weekEntity, let's look at what it HAD if it was existing.
            // If it's new, it has no existing days in DB.
            // If update, we need to know its days. 'weekEntity.days' might not be loaded if we didn't use fetch with relations?
            // VALIDATION: 'plan.weeks' was loaded with relations in 'findOne'.

            const existingDays = weekEntity.days || [];
            const daysToDelete = existingDays.filter(d => d.id && !incomingDayIds.includes(d.id));
            if (daysToDelete.length > 0) {
              await transactionalEntityManager.delete(PlanDay, daysToDelete.map(d => d.id));
            }

            const processedDays: PlanDay[] = [];
            for (const dDto of incomingDays) {
              let dayEntity = dDto.id ? existingDays.find(ed => ed.id === dDto.id) : null;
              if (!dayEntity) dayEntity = new PlanDay();

              dayEntity.title = dDto.title;
              dayEntity.dayOfWeek = dDto.dayOfWeek;
              dayEntity.order = dDto.order;
              dayEntity.dayNotes = dDto.dayNotes;
              if (dDto.trainingIntent) dayEntity.trainingIntent = dDto.trainingIntent;
              dayEntity.week = savedWeek;

              const savedDay = await transactionalEntityManager.save(PlanDay, dayEntity);

              // --- 3. SYNC EXERCISES ---
              const incomingExercises = dDto.exercises;
              const incomingExIds = incomingExercises.map(e => e.id).filter(id => !!id);

              const existingExercises = dayEntity.exercises || [];
              const exToDelete = existingExercises.filter(e => e.id && !incomingExIds.includes(e.id));
              if (exToDelete.length > 0) {
                await transactionalEntityManager.delete(PlanExercise, exToDelete.map(e => e.id));
              }

              const processedExercises: PlanExercise[] = [];
              for (const eDto of incomingExercises) {
                let exEntity = eDto.id ? existingExercises.find(ee => ee.id === eDto.id) : null;
                if (!exEntity) exEntity = new PlanExercise();

                exEntity.sets = eDto.sets;
                exEntity.reps = eDto.reps;
                exEntity.suggestedLoad = eDto.suggestedLoad;
                exEntity.rest = eDto.rest;
                exEntity.notes = eDto.notes;
                exEntity.videoUrl = eDto.videoUrl;
                exEntity.targetTime = eDto.targetTime;
                exEntity.targetDistance = eDto.targetDistance;
                exEntity.order = eDto.order;
                exEntity.day = savedDay;
                exEntity.day = savedDay;
                exEntity.day = savedDay;
                exEntity.exercise = { id: eDto.exerciseId } as any; // Link to Catalog Exercise

                // DEBUG LOG
                this.logger.log(`[UpdatePlan] Processing Ex ${eDto.exerciseId} DTO: ${JSON.stringify(eDto)}`);
                // this.logger.log(`Payload: targetTime=${eDto.targetTime}, targetDistance=${eDto.targetDistance}, sets=${eDto.sets}`);

                if (exEntity.sets !== eDto.sets) {
                  this.logger.log(`[UpdatePlan] Updating Sets for Ex ${exEntity.id}: ${exEntity.sets} -> ${eDto.sets}`);
                } else {
                  this.logger.log(`[UpdatePlan] Sets for Ex ${exEntity.id}: ${eDto.sets} (No Change or New)`);
                }


                if (eDto.equipmentIds) {
                  exEntity.equipments = eDto.equipmentIds.map((eqId: string) => ({ id: eqId } as any));
                }

                // Note: We don't save PlanExercise individually to avoid N+1 queries ideally, 
                // but inside this loop it is N writes. For valid volume it is OK.
                processedExercises.push(exEntity);
              }

              // Batch save exercises for this day?
              // await transactionalEntityManager.save(PlanExercise, processedExercises);
              // But we need to handle equipments (ManyToMany). Save handles it.
              // Let's iterate saveto be safe or use save(array).
              await transactionalEntityManager.save(PlanExercise, processedExercises);

              savedDay.exercises = processedExercises;
              processedDays.push(savedDay);
            }
            savedWeek.days = processedDays;
            processedWeeks.push(savedWeek);
          }
          plan.weeks = processedWeeks;
        }

        const saved = await transactionalEntityManager.save(plan);
        return saved;
      })
      .then((saved) => this.findOne(saved.id) as Promise<Plan>);
  }

  async findStudentPlan(studentId: string): Promise<any | null> {
    const studentPlan = await this.studentPlanRepository.findOne({
      where: { student: { id: studentId }, isActive: true },
      relations: [
        'plan',
        'assignedPlan',
        'assignedPlan.weeks',
        'assignedPlan.weeks.days',
        'assignedPlan.weeks.days.exercises',
        'assignedPlan.weeks.days.exercises.exercise',
        'assignedPlan.weeks.days.exercises.equipments',
        'plan.weeks',
        'plan.weeks.days',
        'plan.weeks.days.exercises',
        'plan.weeks.days.exercises.exercise',
      ],
      order: {
        assignedAt: 'DESC',
      },
    });

    if (!studentPlan) return null;

    if (studentPlan.assignedPlan) {
      // Return the DTO exactly shaped like a Plan for the frontend
      return AssignedPlanMapper.assignedPlanToPlanDto(studentPlan.assignedPlan);
    }

    // Fallback for pre-migration data
    return studentPlan.plan;
  }

  async findAllAssignmentsByStudent(studentId: string): Promise<any[]> {
    const assignments = await this.studentPlanRepository.find({
      where: { student: { id: studentId } },
      relations: ['plan', 'assignedPlan'],
      order: { assignedAt: 'DESC' },
    });
    return assignments.map(a => AssignedPlanMapper.toResponseDto(a));
  }

  async findStudentAssignments(studentId: string): Promise<any[]> {
    const assignments = await this.studentPlanRepository.find({
      where: { student: { id: studentId } },
      relations: [
        'plan',
        'assignedPlan',
        'assignedPlan.weeks',
        'assignedPlan.weeks.days',
        'assignedPlan.weeks.days.exercises',
        'assignedPlan.weeks.days.exercises.exercise',
        'assignedPlan.weeks.days.exercises.equipments',
        'plan.weeks',
        'plan.weeks.days',
        'plan.weeks.days.exercises',
        'plan.weeks.days.exercises.exercise',
      ],
      order: {
        assignedAt: 'DESC',
      },
    });
    return assignments.map(a => AssignedPlanMapper.toResponseDto(a));
  }

  async removeAssignment(assignmentId: string, user: User): Promise<void> {
    const assignment = await this.studentPlanRepository.findOne({
      where: { id: assignmentId },
      relations: ['student', 'student.professor'],
    });

    if (!assignment) throw new NotFoundException('Assignment not found');

    // Permission Check:
    // Admin can delete any assignment.
    // Professor can delete assignment ONLY if the student belongs to them.
    if (user.role === 'admin') {
      // Allowed
    } else if (user.role === 'profe') {
      const student = assignment.student;
      // The student entity loaded via 'student.professor' relation might have professor object.
      // If student has no professor assigned, or professor is diff, deny.
      if (!student.professor || student.professor.id !== user.id) {
        throw new ForbiddenException(
          'You can only remove plans for your own students',
        );
      }
    } else {
      throw new ForbiddenException('Not authorized');
    }

    await this.studentPlanRepository.remove(assignment);
  }

  async remove(id: string, user: User): Promise<void> {
    const plan = await this.findOne(id);
    if (!plan) throw new NotFoundException('Plan not found');

    // Permission: Admin, Super Admin or Plan Owner
    if (
      user.role !== 'admin' &&
      user.role !== 'super_admin' &&
      plan.teacher?.id !== user.id
    ) {
      throw new ForbiddenException('You can only delete your own plans');
    }

    const activeAssignments = await this.studentPlanRepository.find({
      where: { plan: { id: id }, isActive: true },
      relations: ['student'],
    });

    if (activeAssignments.length > 0) {
      // LOG for debugging
      this.logger.warn(`Attempted to delete Plan ${id} but found ${activeAssignments.length} active assignments.`);
      activeAssignments.forEach(a => {
        this.logger.warn(`- Assignment ID: ${a.id}, Student: ${a.student?.firstName} ${a.student?.lastName} (${a.student?.id})`);
      });

      const studentNames = activeAssignments
        .map((a) => `${a.student.firstName} ${a.student.lastName} (ID: ${a.student.id})`)
        .join(', ');
      const { ConflictException } = require('@nestjs/common');
      throw new ConflictException(
        `No se puede eliminar: El plan está activo para: ${studentNames}`,
      );
    }

    try {
      await this.plansRepository.remove(plan);
    } catch (error) {
      this.logger.error(`Failed to delete Plan ${id}`, error.stack);
      // Re-throw or handle specific TypeORM errors if needed
      throw error;
    }
  }

  async updateProgress(
    studentPlanId: string,
    userId: string,
    payload: {
      type: 'exercise' | 'day';
      id: string;
      completed: boolean;
      date?: string;
    },
  ): Promise<StudentPlan> {
    const studentPlan = await this.studentPlanRepository.findOne({
      where: { id: studentPlanId },
      relations: ['student'],
    });

    if (!studentPlan) throw new NotFoundException('Assignment not found');
    if (studentPlan.student.id !== userId)
      throw new ForbiddenException('Access denied');

    // Initialize progress structure if needed
    if (!studentPlan.progress)
      studentPlan.progress = { exercises: {}, days: {} };
    if (!studentPlan.progress.exercises) studentPlan.progress.exercises = {};
    if (!studentPlan.progress.days) studentPlan.progress.days = {};

    if (payload.type === 'exercise') {
      if (payload.completed) {
        studentPlan.progress.exercises[payload.id] = true;
      } else {
        delete studentPlan.progress.exercises[payload.id];
      }
    } else if (payload.type === 'day') {
      if (payload.completed) {
        studentPlan.progress.days[payload.id] = {
          completed: true,
          date: payload.date || new Date().toISOString(),
        };
      } else {
        delete studentPlan.progress.days[payload.id];
      }
    }

    // Force update
    const updated = await this.studentPlanRepository.save(studentPlan);
    return updated;
  }

  async restartAssignment(
    assignmentId: string,
    userId: string,
  ): Promise<StudentPlan> {
    return this.studentPlanRepository.manager.transaction(
      async (transactionalEntityManager) => {
        // 1. Find the existing assignment
        const oldAssignment = await transactionalEntityManager.findOne(
          StudentPlan,
          {
            where: { id: assignmentId },
            relations: ['student', 'plan'],
          },
        );

        if (!oldAssignment) throw new NotFoundException('Assignment not found');
        if (oldAssignment.student.id !== userId)
          throw new ForbiddenException('Access denied');

        // 2. Archive the old one
        oldAssignment.isActive = false;
        oldAssignment.endDate = new Date().toISOString();
        await transactionalEntityManager.save(oldAssignment);

        // 3. Re-assign using the underlying assignPlan method if we have originalPlanId
        // However, we need 'assigner' which we don't have.
        // We'll emulate it by directly calling the private equivalent or just reloading and cloning.
        // For simplicity and to reuse the logic:
        const originalPlanId = oldAssignment.assignedPlan?.originalPlanId || oldAssignment.plan?.id;
        if (!originalPlanId) throw new ConflictException('Cannot restart a plan with no original origin');
        
        const teacher = oldAssignment.plan?.teacher || { id: oldAssignment.assignedPlan?.assignedByUserId || userId, role: UserRole.ALUMNO } as User;
        
        // Save the archived one first
        await transactionalEntityManager.save(oldAssignment);
        
        // We defer to the standard assignPlan mechanism, but wait, assignPlan requires a separate transaction or handles its own.
        // Let's just emulate the creation logic without the transaction:
        
        const newAssignment = this.studentPlanRepository.create({
          plan: { id: originalPlanId } as any,
          student: { id: userId } as any,
          assignedAt: new Date().toISOString(),
          startDate: new Date().toISOString(),
          isActive: true,
          progress: { exercises: {}, days: {} },
        });

        const planTemplate = await transactionalEntityManager.findOne(Plan, {
          where: { id: originalPlanId },
          relations: ['weeks', 'weeks.days', 'weeks.days.exercises', 'weeks.days.exercises.exercise', 'weeks.days.exercises.equipments'],
        });

        if (planTemplate) {
            const assignedPlan = new AssignedPlan();
            assignedPlan.originalPlanId = planTemplate.id;
            assignedPlan.originalPlanName = planTemplate.name;
            assignedPlan.assignedAt = new Date();
            assignedPlan.assignedByUserId = teacher.id;
            assignedPlan.name = planTemplate.name;
            assignedPlan.description = planTemplate.description;
            assignedPlan.objective = planTemplate.objective;
            assignedPlan.generalNotes = planTemplate.generalNotes;
            assignedPlan.durationWeeks = planTemplate.durationWeeks;

            assignedPlan.weeks = (planTemplate.weeks || []).map(w => {
              const assignedWeek = new AssignedPlanWeek();
              assignedWeek.weekNumber = w.weekNumber;
              assignedWeek.days = (w.days || []).map(d => {
                const assignedDay = new AssignedPlanDay();
                assignedDay.title = d.title;
                assignedDay.dayOfWeek = d.dayOfWeek;
                assignedDay.order = d.order;
                assignedDay.trainingIntent = d.trainingIntent;
                assignedDay.dayNotes = d.dayNotes;
                assignedDay.exercises = (d.exercises || []).map(e => {
                  const assignedEx = new AssignedPlanExercise();
                  assignedEx.exercise = e.exercise;
                  assignedEx.sets = e.sets;
                  assignedEx.reps = e.reps;
                  assignedEx.suggestedLoad = e.suggestedLoad;
                  assignedEx.rest = e.rest;
                  assignedEx.notes = e.notes;
                  assignedEx.videoUrl = e.videoUrl;
                  assignedEx.targetTime = e.targetTime;
                  assignedEx.targetDistance = e.targetDistance;
                  assignedEx.order = e.order;
                  assignedEx.equipments = e.equipments || [];
                  return assignedEx;
                });
                return assignedDay;
              });
              return assignedWeek;
            });
            const savedAssignedPlan = await transactionalEntityManager.save(AssignedPlan, assignedPlan);
            newAssignment.assignedPlan = savedAssignedPlan;
        }

        return await transactionalEntityManager.save(StudentPlan, newAssignment);
      },
    );
  }
}
