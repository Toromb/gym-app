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
    try {
      const user = await this.usersService.findOneByEmail(email);

      if (user) {
        if (!user.passwordHash) {
          this.logger.error(`User ${user.email} has no passwordHash loaded!`);
          return null;
        }

        const isMatch = await bcrypt.compare(pass, user.passwordHash);

        if (isMatch) {
          // Suspended Gym Check
          if (user.gym && user.gym.status === 'suspended') {
            throw new UnauthorizedException('CUENTA/GYM SUSPENDIDO/A');
          }

          const { passwordHash, ...result } = user;
          return result;
        }
      }
      return null;
    } catch (error) {
      this.logger.error('ValidateUser Error:', error);
      throw error;
    }
  }

  async login(user: any) {
    try {
      const payload = { email: user.email, sub: user.id, role: user.role };
      console.log('DEBUG: Signing JWT for', payload);
      const token = this.jwtService.sign(payload);
      console.log('DEBUG: Token signed successfully');
      return {
        access_token: token,
        user: user,
      };
    } catch (e) {
      console.error('LOGIN ERROR:', e);
      throw e;
    }
  }

  async register(createUserDto: CreateUserDto) {
    const user = await this.usersService.create(createUserDto);
    const { passwordHash, ...result } = user;
    return result;
  }
}
