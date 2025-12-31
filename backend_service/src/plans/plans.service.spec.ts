import { Test, TestingModule } from '@nestjs/testing';
import { PlansService } from './plans.service';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Plan } from './entities/plan.entity';
import { StudentPlan } from './entities/student-plan.entity';
import { User, UserRole } from '../users/entities/user.entity';
import { ForbiddenException, NotFoundException } from '@nestjs/common';

describe('PlansService', () => {
  let service: PlansService;

  const mockPlanRepository = {
    save: jest
      .fn()
      .mockImplementation((plan) =>
        Promise.resolve({ id: 'plan-id', ...plan }),
      ),
    findOne: jest.fn(),
    find: jest.fn(),
  };

  const mockStudentPlanRepository = {
    save: jest
      .fn()
      .mockImplementation((sp) => Promise.resolve({ id: 'sp-id', ...sp })),
    update: jest.fn(),
  };

  const mockUsersService = {
    findOne: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PlansService,
        { provide: getRepositoryToken(Plan), useValue: mockPlanRepository },
        {
          provide: getRepositoryToken(StudentPlan),
          useValue: mockStudentPlanRepository,
        },
        { provide: 'UsersService', useValue: mockUsersService }, // PlansService often depends on UsersService or Repository?
        // Checking Dependencies: PlansService usually injects Repositories.
        // It injects PlansRepository and StudentPlanRepository.
        // Does it inject UsersService? assignPlan validated users... let me check service again.
        // It validated with "user.students". It likely fetches plan with relations or user with relations?
        // I need to ensure the mocks match the actual service structure.
      ],
    }).compile();

    service = module.get<PlansService>(PlansService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should create a plan with deep structure', async () => {
    const teacher = { id: 'prof-id' } as User;
    const dto = {
      name: 'P1',
      durationWeeks: 4,
      weeks: [{ weekNumber: 1, days: [{ dayOfWeek: 1, exercises: [] }] }],
    };

    const result = await service.create(dto as any, teacher);
    expect(mockPlanRepository.save).toHaveBeenCalled();
    expect(result.weeks).toHaveLength(1);
    expect(result.teacher).toEqual(teacher);
  });

  // assignPlan checks user permissions. This might need more setup if validation is inside service.
  // The service implementation of assignPlan(planId, studentId) does:
  // 1. findOne(planId) -> checks plan.teacher
  // 2. findUser(studentId) -> or just check if student is in professor's list?
  // Actually validation was: requires professorId argument.
  // The service signature I made: assignPlan(planId, studentId, professorId).
});
