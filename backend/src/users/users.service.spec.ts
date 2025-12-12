import { Test, TestingModule } from '@nestjs/testing';
import { UsersService } from './users.service';
import { getRepositoryToken } from '@nestjs/typeorm';
import { User, UserRole } from './entities/user.entity';

describe('UsersService', () => {
  let service: UsersService;
  // Mock Repository
  const mockUsersRepository = {
    create: jest.fn().mockImplementation((dto) => dto),
    save: jest.fn().mockImplementation((user) => Promise.resolve({ id: 'uuid', ...user })),
    find: jest.fn(),
    findOne: jest.fn(),
    delete: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        {
          provide: getRepositoryToken(User),
          useValue: mockUsersRepository,
        },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should create a user with hashed password', async () => {
    const dto = { email: 'test@test.com', password: 'pass', firstName: 'T', lastName: 'U', role: UserRole.ADMIN };
    const result = await service.create(dto);
    expect(mockUsersRepository.create).toHaveBeenCalled();
    expect(mockUsersRepository.save).toHaveBeenCalled();
    expect(result.passwordHash).toBeDefined();
    expect(result.passwordHash).not.toBe('pass');
  });

  it('should assign professor when provided', async () => {
    const professor = { id: 'prof-id', role: UserRole.PROFE } as User;
    const dto = { email: 'stud@test.com', firstName: 'S', lastName: 'T', role: UserRole.ALUMNO, password: '123' };
    const result = await service.create(dto, professor);
    expect(result.professor).toEqual(professor);
  });

  it('should findAllStudents filtering by professor', async () => {
    await service.findAllStudents('prof-id');
    expect(mockUsersRepository.find).toHaveBeenCalledWith(expect.objectContaining({
      where: expect.objectContaining({
        professor: { id: 'prof-id' },
        role: UserRole.ALUMNO
      })
    }));
  });
});
