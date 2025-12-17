import { UsersService } from '../users/users.service';
import { PaymentStatus } from '../users/entities/user.entity';
export declare class PaymentsController {
    private readonly usersService;
    constructor(usersService: UsersService);
    updateStatus(userId: string, status: PaymentStatus): Promise<{
        message: string;
    }>;
}
