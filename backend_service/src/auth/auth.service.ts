import { Injectable, UnauthorizedException, Logger } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { CreateUserDto } from '../users/dto/create-user.dto';

@Injectable()
export class AuthService {
    private readonly logger = new Logger(AuthService.name);

    constructor(
        private usersService: UsersService,
        private jwtService: JwtService,
    ) { }

    async validateUser(email: string, pass: string): Promise<any> {
        const user = await this.usersService.findOneByEmail(email);
        if (user && (await bcrypt.compare(pass, user.passwordHash))) {

            // Suspended Gym Check
            if (user.gym && user.gym.status === 'suspended') {
                // Check if user is Super Admin (exempt?)
                // Assuming Super Admin role is 'super_admin' or similar, OR they don't have a gym assigned (gym is null).
                // If they have a gym and it is suspended, they are blocked. 
                // Unless we explicitly exempt 'admin' role? NO, user request said "dichas cuentas vinculadas... no deberian tener acceso".
                // So even the Gym Admin should be blocked if Gym is suspended.
                throw new UnauthorizedException('CUENTA/GYM SUSPENDIDO/A');
            }

            const { passwordHash, ...result } = user;
            return result;
        }
        return null;
    }

    async login(user: any) {
        const payload = { email: user.email, sub: user.id, role: user.role };

        // Return full user object (ensure paymentStatus, dates, etc are included)
        // 'user' here comes from validateUser which comes from findOneByEmail, so it HAS the fields.
        const { passwordHash, ...userInfo } = user;

        return {
            access_token: this.jwtService.sign(payload),
            user: userInfo,
        };
    }

    async register(createUserDto: CreateUserDto) {
        const user = await this.usersService.create(createUserDto);
        const { passwordHash, ...result } = user;
        return result;
    }
}
