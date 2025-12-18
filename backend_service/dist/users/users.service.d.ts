import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { GymsService } from '../gyms/gyms.service';
export declare class UsersService {
    private usersRepository;
    private gymsService;
    private readonly logger;
    constructor(usersRepository: Repository<User>, gymsService: GymsService);
    create(createUserDto: CreateUserDto, creator?: User): Promise<User>;
    findAllStudents(professorId?: string, roleFilter?: string, gymId?: string): Promise<User[]>;
    findOneByEmail(email: string): Promise<User | null>;
    findOne(id: string): Promise<User | null>;
    update(id: string, updateUserDto: UpdateUserDto): Promise<User>;
    remove(id: string): Promise<void>;
    countAll(): Promise<number>;
    markAsPaid(id: string): Promise<User>;
    calculatePaymentStatus(expirationDate: Date | string): 'paid' | 'overdue' | 'pending';
}
