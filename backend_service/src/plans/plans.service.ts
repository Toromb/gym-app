import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  ConflictException,
  BadRequestException,
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
import { CompletedPlan, CompletedReason } from './entities/completed-plan.entity';
import { AssignedPlanWeek } from './entities/assigned-plan-week.entity';
import { AssignedPlanDay } from './entities/assigned-plan-day.entity';
import { AssignedPlanExercise } from './entities/assigned-plan-exercise.entity';
import { TrainingSession } from './entities/training-session.entity';
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



  // ---------------------------------------------------------------------------
  // PLAN ASSIGNMENT — Snapshot System (Phase 1+)
  // ---------------------------------------------------------------------------
  //
  // DESIGN INTENT: When a teacher assigns a plan to a student we must NOT store
  // a simple foreign-key reference to the master Plan. If we did, any future edit
  // to the template would silently change what the student sees mid-routine.
  //
  // Instead, assignPlan() deep-clones the entire plan tree into an *AssignedPlan*
  // (+ AssignedPlanWeek / AssignedPlanDay / AssignedPlanExercise). The student
  // works exclusively against this frozen snapshot. The master Plan template can
  // be freely edited without affecting active students.
  //
  // Re-assignment (same plan, same student): replaces the snapshot reference so
  // the student gets the *current* version of the exercises, but does NOT reset
  // their in-progress tracking or startDate unless they had no active plan at all.
  async assignPlan(planId: string, studentId: string, assigner: User): Promise<StudentPlan> {
    const plan = await this.findOne(planId);
    if (!plan) throw new NotFoundException('Plan not found');

    // Validate Plan Ownership (Allow own plans OR Admin/Global plans OR if Assigner is Admin)
    const planTeacherId = plan.teacher?.id;
    const planTeacherRole = plan.teacher?.role;
    const isAssignerAdmin = assigner.role === UserRole.ADMIN || assigner.role === UserRole.SUPER_ADMIN;

    const isOwner = planTeacherId === assigner.id;
    const isAdminPlan = planTeacherRole === UserRole.ADMIN || planTeacherRole === UserRole.SUPER_ADMIN;

    if (!isOwner && !isAdminPlan && !isAssignerAdmin) {
      throw new ForbiddenException('You can only assign your own plans or library plans');
    }

    // Validate Student Ownership 
    const student = await this.plansRepository.manager.findOne(User, { where: { id: studentId }, relations: ['professor', 'gym'] });
    if (!student) throw new NotFoundException('Student not found');

    // --- Deep-clone the plan tree into an AssignedPlan snapshot ---
    // Each field is copied by value so the snapshot is fully decoupled from the
    // master Plan. originalPlanId is kept for audit/history purposes only.
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
      // 1. Save the new snapshot
      const savedAssignedPlan = await transactionalEntityManager.save(AssignedPlan, assignedPlan);

      // 2. Check if student already has this exact Library Plan assigned
      let studentPlan = await transactionalEntityManager.findOne(StudentPlan, {
        where: {
          student: { id: studentId },
          plan: { id: planId }
        },
        relations: ['assignedPlan']
      });

      const existingActive = await transactionalEntityManager.findOne(StudentPlan, {
        where: { student: { id: studentId }, isActive: true }
      });

      if (studentPlan) {
        // --- EXISTING PLAN REASSIGNMENT LOGIC ---
        // 1. Snapshot: We update the reference so the student gets the newest version of the exercises.
        //    (Old snapshot remains in DB for any completed histories that point to it).
        studentPlan.assignedPlan = savedAssignedPlan;
        
        // 2. isActive: 
        //    - If this plan is ALREADY active, we leave it active (true). This updates the ongoing routine in real-time.
        //    - If this plan is reusable/pending (false), we leave it false UNLESS they have absolutely no active plan!
        if (!studentPlan.isActive && !existingActive) {
           studentPlan.isActive = true;
           studentPlan.startDate = new Date().toISOString();
        }

        // 3. progress: We DO NOT touch the progress JSON! 
        //    This completely avoids implicitly wiping the student's partial progress just because the professor bumped the routine.
        
        // 4. assignedAt / startDate: 
        //    - `assignedAt` dates up to today (bumps the card up in "Seleccionar plan" or lists).
        //    - `startDate` is NOT altered unless it was newly auto-activated just now.
        studentPlan.assignedAt = new Date().toISOString();

      } else {
        // --- NEW PLAN ASSIGNMENT LOGIC ---
        studentPlan = this.studentPlanRepository.create({
          plan: { id: planId } as any,
          student: { id: studentId } as any,
          assignedAt: new Date().toISOString(),
          startDate: new Date().toISOString(), // First activation default
          isActive: existingActive ? false : true,
          assignedPlan: savedAssignedPlan
        });
      }

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


  async findAllAssignmentsByStudent(studentId: string): Promise<any[]> {
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
      order: { assignedAt: 'DESC' },
    });
    // Filtrar asignaciones corruptas (sin plan) para que no compitan con las sanas
    const validAssignments = assignments.filter((a) => a.assignedPlan != null || a.plan != null);
    
    return validAssignments.map(a => AssignedPlanMapper.toResponseDto(a));
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
    
    // Filtrar asignaciones corruptas
    const validAssignments = assignments.filter((a) => a.assignedPlan != null || a.plan != null);
    return validAssignments.map(a => AssignedPlanMapper.toResponseDto(a));
  }

  async activateAssignment(assignmentId: string, studentId: string): Promise<void> {
    const assignment = await this.studentPlanRepository.findOne({
      where: { id: assignmentId, student: { id: studentId } },
    });
    
    if (!assignment) {
      throw new NotFoundException('Assignment not found for this student');
    }
    
    if (!assignment.assignedPlan && !assignment.plan) {
      throw new BadRequestException('Cannot activate a corrupted assignment without a valid plan structure.');
    }

    await this.studentPlanRepository.manager.transaction(async (manager) => {
      // 1. Mark all other assignments for this student as inactive
      await manager.query(
        `UPDATE student_plans SET "isActive" = false WHERE "studentId" = $1`,
        [studentId]
      );
      
      // 2. Mark this assignment as active
      await manager.query(
        `UPDATE student_plans SET "isActive" = true, "startDate" = $1 WHERE "id" = $2 AND "studentId" = $3`,
        [new Date().toISOString(), assignmentId, studentId]
      );
    });
  }

  async removeAssignment(assignmentId: string, user: User): Promise<void> {
    const assignment = await this.studentPlanRepository.findOne({
      where: { id: assignmentId },
      relations: ['student', 'student.professor', 'student.gym', 'plan', 'assignedPlan'],
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

    const originalPlanId = assignment.assignedPlan?.originalPlanId || assignment.plan?.id;
    const planNameSnapshot = assignment.assignedPlan?.name || assignment.plan?.name || 'Unknown Plan';

    const assignedPlanId = assignment.assignedPlan?.id || null;
    const legacyPlanId = assignment.plan?.id || null;

    const countRes = await this.studentPlanRepository.manager.query(
      `SELECT COUNT(*) as count FROM training_sessions WHERE "studentId" = $1 AND ("assignedPlanId" = $2 OR "planId" = $3) AND "completedPlanId" IS NULL`,
      [assignment.student.id, assignedPlanId, legacyPlanId]
    );
      
    const hasSessions = parseInt(countRes[0].count, 10) > 0;
    const progress = assignment.progress || {};
    const hasLegacyProgress = Object.keys(progress.exercises || {}).length > 0 || Object.keys(progress.days || {}).length > 0;
    const hasEvidencia = hasSessions || hasLegacyProgress;

    if (hasEvidencia) {
      const completedPlan = new CompletedPlan();
      completedPlan.student = assignment.student;
      completedPlan.gym = assignment.student.gym;
      completedPlan.assignedPlanId = assignedPlanId;
      completedPlan.originalPlanId = originalPlanId;
      completedPlan.planNameSnapshot = planNameSnapshot;
      completedPlan.startedAt = assignment.startDate;
      completedPlan.completedAt = new Date();
      completedPlan.completedReason = CompletedReason.CANCELLED;

      const savedCompletedPlan = await this.studentPlanRepository.manager.save(CompletedPlan, completedPlan);

      await this.studentPlanRepository.manager.query(
        `UPDATE training_sessions 
         SET "completedPlanId" = $1 
         WHERE "studentId" = $2 AND ("assignedPlanId" = $3 OR "planId" = $4) AND "completedPlanId" IS NULL`,
        [savedCompletedPlan.id, assignment.student.id, assignedPlanId, legacyPlanId]
      );
    }

    assignment.isActive = false;
    assignment.progress = { exercises: {}, days: {} };
    assignment.startDate = null as any;

    await this.studentPlanRepository.save(assignment);
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
            relations: ['student', 'student.gym', 'plan', 'assignedPlan'],
          },
        );

        if (!oldAssignment) throw new NotFoundException('Assignment not found');
        if (oldAssignment.student.id !== userId)
          throw new ForbiddenException('Access denied');
          
        if (!oldAssignment.assignedPlan && !oldAssignment.plan) {
          throw new BadRequestException('Cannot restart a corrupted assignment without a valid plan structure.');
        }

        // 2. Archive the old one and generate CompletedPlan historical wrapper
        const originalPlanId = oldAssignment.assignedPlan?.originalPlanId || oldAssignment.plan?.id;
        const planNameSnapshot = oldAssignment.assignedPlan?.name || oldAssignment.plan?.name || 'Unknown Plan';

        const assignedPlanId = oldAssignment.assignedPlan?.id || null;
        const legacyPlanId = oldAssignment.plan?.id || null;

        // Clean up ghost/empty IN_PROGRESS sessions from DB physically
        await transactionalEntityManager.query(`
          DELETE FROM training_sessions
          WHERE id IN (
            SELECT ts.id FROM training_sessions ts
            WHERE ts."studentId" = $1 
              AND (ts."assignedPlanId" = $2 OR ts."planId" = $3) 
              AND ts."completedPlanId" IS NULL
              AND ts."status" = 'IN_PROGRESS'
              AND NOT EXISTS (
                SELECT 1 FROM session_exercises se 
                WHERE se."sessionId" = ts.id 
                  AND (se."isCompleted" = true 
                       OR (se."setsDone" IS NOT NULL AND se."setsDone" != '0')
                       OR (se."repsDone" IS NOT NULL AND se."repsDone" != '0')
                       OR (se."timeSpent" IS NOT NULL AND se."timeSpent" != '0')
                       OR (se."distanceCovered" IS NOT NULL AND se."distanceCovered" != 0)
                       OR (se."weightUsed" IS NOT NULL AND se."weightUsed" != '0'))
              )
          )
        `, [userId, assignedPlanId, legacyPlanId]);

        const countRes = await transactionalEntityManager.query(
          `SELECT COUNT(*) as count FROM training_sessions WHERE "studentId" = $1 AND ("assignedPlanId" = $2 OR "planId" = $3) AND "completedPlanId" IS NULL`,
          [userId, assignedPlanId, legacyPlanId]
        );
          
        const hasSessions = parseInt(countRes[0].count, 10) > 0;
        const progress = oldAssignment.progress || {};
        const hasLegacyProgress = Object.keys(progress.exercises || {}).length > 0 || Object.keys(progress.days || {}).length > 0;
        const hasEvidencia = hasSessions || hasLegacyProgress;

        if (hasEvidencia) {
          const completedPlan = new CompletedPlan();
          completedPlan.student = oldAssignment.student;
          completedPlan.gym = oldAssignment.student.gym;
          completedPlan.assignedPlanId = assignedPlanId;
          completedPlan.originalPlanId = originalPlanId;
          completedPlan.planNameSnapshot = planNameSnapshot;
          completedPlan.startedAt = oldAssignment.startDate;
          completedPlan.completedAt = new Date();
          completedPlan.completedReason = CompletedReason.RESTARTED;

          const savedCompletedPlan = await transactionalEntityManager.save(CompletedPlan, completedPlan);

          await transactionalEntityManager.query(
            `UPDATE training_sessions 
             SET "completedPlanId" = $1 
             WHERE "studentId" = $2 AND ("assignedPlanId" = $3 OR "planId" = $4) AND "completedPlanId" IS NULL`,
            [savedCompletedPlan.id, userId, assignedPlanId, legacyPlanId]
          );
        }

        // Ensure other assignments are inactive
        await transactionalEntityManager.query(
          `UPDATE student_plans SET "isActive" = false WHERE "studentId" = $1 AND "id" != $2`,
          [userId, oldAssignment.id]
        );

        // 3. Reset the current assignment instead of duplicating it using raw query to ensure JSONb reset
        await transactionalEntityManager.query(
          `UPDATE student_plans SET "isActive" = true, "startDate" = $1, "progress" = '{"exercises":{},"days":{}}'::jsonb WHERE "id" = $2`,
          [new Date().toISOString(), oldAssignment.id]
        );
        
        const updated = await transactionalEntityManager.findOne(StudentPlan, { where: { id: oldAssignment.id }, relations: ['student', 'student.gym', 'plan', 'assignedPlan'] });
        return updated as StudentPlan;
      },
    );
  }

  async getHistoricalPlans(studentId: string): Promise<CompletedPlan[]> {
    const plans = await this.studentPlanRepository.manager.find(CompletedPlan, {
      where: { student: { id: studentId } },
      relations: [
        'sessions',
        'sessions.exercises',
        'sessions.exercises.exercise',
        'sessions.assignedPlan' 
      ],
      order: {
        completedAt: 'DESC',
      },
    });

    return plans.map(plan => {
      if (plan.sessions) {
        plan.sessions = plan.sessions.filter(session => {
          // Include completed sessions
          if (session.status === 'COMPLETED') return true;
          
          // For IN_PROGRESS sessions, include only if they have actual progress
          const hasProgress = session.exercises?.some(ex => {
            return ex.isCompleted === true || 
                   (ex.setsDone && ex.setsDone !== '0') ||
                   (ex.repsDone && ex.repsDone !== '0') ||
                   (ex.timeSpent && ex.timeSpent !== '0') ||
                   (ex.distanceCovered && ex.distanceCovered !== 0) ||
                   (ex.weightUsed && ex.weightUsed !== '0');
          });
          
          return hasProgress;
        });
      }
      return plan;
    });
  }

  async finishAssignment(
    assignmentId: string,
    userId: string,
  ): Promise<void> {
    return this.studentPlanRepository.manager.transaction(
      async (transactionalEntityManager) => {
        const assignment = await transactionalEntityManager.findOne(
          StudentPlan,
          {
            where: { id: assignmentId },
            relations: ['student', 'student.gym', 'plan', 'assignedPlan'],
          },
        );

        if (!assignment) throw new NotFoundException('Assignment not found');
        if (assignment.student.id !== userId)
          throw new ForbiddenException('Access denied');

        const originalPlanId = assignment.assignedPlan?.originalPlanId || assignment.plan?.id;
        const planNameSnapshot = assignment.assignedPlan?.name || assignment.plan?.name || 'Unknown Plan';

        const assignedPlanId = assignment.assignedPlan?.id || null;
        const legacyPlanId = assignment.plan?.id || null;

        // Clean up ghost/empty IN_PROGRESS sessions from DB physically
        await transactionalEntityManager.query(`
          DELETE FROM training_sessions
          WHERE id IN (
            SELECT ts.id FROM training_sessions ts
            WHERE ts."studentId" = $1 
              AND (ts."assignedPlanId" = $2 OR ts."planId" = $3) 
              AND ts."completedPlanId" IS NULL
              AND ts."status" = 'IN_PROGRESS'
              AND NOT EXISTS (
                SELECT 1 FROM session_exercises se 
                WHERE se."sessionId" = ts.id 
                  AND (se."isCompleted" = true 
                       OR (se."setsDone" IS NOT NULL AND se."setsDone" != '0')
                       OR (se."repsDone" IS NOT NULL AND se."repsDone" != '0')
                       OR (se."timeSpent" IS NOT NULL AND se."timeSpent" != '0')
                       OR (se."distanceCovered" IS NOT NULL AND se."distanceCovered" != 0)
                       OR (se."weightUsed" IS NOT NULL AND se."weightUsed" != '0'))
              )
          )
        `, [userId, assignedPlanId, legacyPlanId]);

        const countRes = await transactionalEntityManager.query(
          `SELECT COUNT(*) as count FROM training_sessions WHERE "studentId" = $1 AND ("assignedPlanId" = $2 OR "planId" = $3) AND "completedPlanId" IS NULL`,
          [userId, assignedPlanId, legacyPlanId]
        );
          
        const hasSessions = parseInt(countRes[0].count, 10) > 0;
        const progress = assignment.progress || {};
        const hasLegacyProgress = Object.keys(progress.exercises || {}).length > 0 || Object.keys(progress.days || {}).length > 0;
        const hasEvidencia = hasSessions || hasLegacyProgress;

        if (!hasEvidencia) {
          throw new ConflictException('No se puede finalizar el plan: no hay sesiones registradas ni progreso para enviar al historial.');
        }

        const completedPlan = new CompletedPlan();
        completedPlan.student = assignment.student;
        completedPlan.gym = assignment.student.gym;
        completedPlan.assignedPlanId = assignedPlanId;
        completedPlan.originalPlanId = originalPlanId;
        completedPlan.planNameSnapshot = planNameSnapshot;
        completedPlan.startedAt = assignment.startDate;
        completedPlan.completedAt = new Date();
        completedPlan.completedReason = CompletedReason.COMPLETED;

        const savedCompletedPlan = await transactionalEntityManager.save(CompletedPlan, completedPlan);

        await transactionalEntityManager.query(
          `UPDATE training_sessions 
           SET "completedPlanId" = $1 
           WHERE "studentId" = $2 AND ("assignedPlanId" = $3 OR "planId" = $4) AND "completedPlanId" IS NULL`,
          [savedCompletedPlan.id, userId, assignedPlanId, legacyPlanId]
        );

        assignment.isActive = false;
        // Reiniciamos explícitamente el progreso y la fecha de inicio para que la asignación
        // base quede limpia y lista para ser reutilizada por el estudiante en un nuevo ciclo.
        assignment.progress = { exercises: {}, days: {} };
        assignment.startDate = null as any; 

        await transactionalEntityManager.save(assignment);
      },
    );
  }
}
