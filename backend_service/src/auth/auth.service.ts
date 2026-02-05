import { Injectable, UnauthorizedException, Logger, BadRequestException } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { instanceToPlain } from 'class-transformer';
import { OAuth2Client } from 'google-auth-library';
import { GymsService } from '../gyms/gyms.service';
import { UserRole } from '../users/entities/user.entity';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID!);

  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
    private gymsService: GymsService,
  ) { }

  async loginWithGoogle(idToken: string, gymId?: string) {
    let payload;
    try {
      const ticket = await this.googleClient.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID!,
      });
      payload = ticket.getPayload();
    } catch (error) {
      this.logger.error(`Google Token Validation Failed: ${error.message}`);
      throw new UnauthorizedException('Token de Google inválido');
    }

    if (!payload) throw new UnauthorizedException('Token de Google inválido');
    const { email, sub: providerUserId, name, picture } = payload;

    if (!email || !providerUserId) {
      throw new UnauthorizedException('Token de Google incompleto (falta email o sub)');
    }

    // 1. Try to find user
    let user = await this.usersService.findOneByEmail(email);
    if (!user) {
      user = await this.usersService.findOneByProviderUserId(providerUserId);
    }

    if (user) {
      // LOGIN EXISTING USER
      // Link account silently if needed
      const updates: any = {};
      if (!user.providerUserId) updates.providerUserId = providerUserId;
      if (!user.profileImageUrl && picture) updates.profileImageUrl = picture;
      // Optional: Update provider to GOOGLE if it was LOCAL? 
      // Let's assume we allow hybrid, but we mark them if they logged with Google.
      if (user.provider === 'LOCAL') updates.provider = 'GOOGLE';

      if (Object.keys(updates).length > 0) {
        await this.usersService.updateTokens(user.id, updates);
      }
    } else {
      // REGISTER NEW USER
      // Strict Check: Must have Gym ID
      if (!gymId) {
        throw new BadRequestException('El usuario no pertenece a ningún gimnasio. Solicite un enlace o QR de invitación a su gimnasio.');
      }

      const gym = await this.gymsService.findOne(gymId);
      if (!gym) throw new BadRequestException('Gimnasio inválido o no encontrado.');

      const names = name ? name.split(' ') : ['Usuario', 'Google'];
      const firstName = names[0];
      const lastName = names.slice(1).join(' ') || '';

      const createUserDto: CreateUserDto = {
        email,
        firstName,
        lastName,
        gymId, // Important
        provider: 'GOOGLE',
        providerUserId,
        profileImageUrl: picture,
        role: UserRole.ALUMNO,
        isActive: true,
        paysMembership: true,
      };

      user = await this.usersService.create(createUserDto);
      this.logger.log(`Created new Google user: ${email} for Gym ${gym.businessName}`);
    }

    return this.login(user);
  }

  async validateUser(email: string, pass: string): Promise<any> {
    const user = await this.usersService.findOneByEmail(email);
    if (!user) {
      this.logger.warn(`Login failed: User not found for email ${email}`);
      return null;
    }

    if (!user.passwordHash) {
      this.logger.warn(`Login failed: User ${email} has no password hash`);
      return null;
    }

    const isMatch = await bcrypt.compare(pass, user.passwordHash);
    if (isMatch) {
      this.logger.log(`Login successful for user ${email}`);

      // Suspended Gym Check
      if (user.gym && user.gym.status === 'suspended') {
        this.logger.warn(`Login blocked: Gym suspended for user ${email}`);
        throw new UnauthorizedException('CUENTA/GYM SUSPENDIDO/A');
      }

      const { passwordHash, ...result } = user;
      return result;
    } else {
      this.logger.warn(`Login failed: Password mismatch for user ${email}`);
      return null;
    }
  }

  async login(user: any) {
    const payload = {
      email: user.email,
      sub: user.id,
      role: user.role,
      tokenVersion: user.tokenVersion
    };

    // Force transformation to respect @Exclude() decorators (e.g. Gym.users, passwordHash)
    // unwrap the TypeORM entity to a plain object using class-transformer rules
    const safeUser = instanceToPlain(user);

    return {
      access_token: this.jwtService.sign(payload),
      user: safeUser,
    };
  }

  async register(createUserDto: CreateUserDto) {
    const user = await this.usersService.create(createUserDto);
    const { passwordHash, ...result } = user;
    return result;
  }

  async generateActivationToken(userId: string): Promise<string> {
    const user = await this.usersService.findOne(userId);
    if (!user) throw new Error('User not found');

    // Generate random token
    const token = await this.generateRandomToken();
    const hash = await this.hashToken(token);

    // 24 hours expiry
    const expires = new Date();
    expires.setHours(expires.getHours() + 24);

    await this.usersService.updateTokens(userId, { activationTokenHash: hash, activationTokenExpires: expires });

    return token;
  }

  async activateAccount(token: string, password: string): Promise<void> {
    this.logger.log(`Attempting to activate account with token: ${token}`);
    const hash = await this.hashToken(token);
    const user = await this.usersService.findOneByActivationTokenHash(hash);

    if (!user) {
      this.logger.error(`Activation failed: Invalid token hash query. Hash: ${hash}`);
      throw new UnauthorizedException('Invalid token');
    }

    this.logger.log(`Found user for activation: ${user.email} (ID: ${user.id})`);

    if (user.activationTokenExpires && user.activationTokenExpires < new Date()) {
      this.logger.error(`Activation failed: Token expired for user ${user.email}`);
      throw new UnauthorizedException('Token expired');
    }

    const passwordHash = await bcrypt.hash(password, 10);
    this.logger.log(`Generated password hash for user ${user.id}: ${passwordHash.substring(0, 10)}...`);

    await this.usersService.updateTokens(user.id, {
      activationTokenHash: null,
      activationTokenExpires: null,
      passwordHash: passwordHash,
      isActive: true
    });

    this.logger.log(`Account successfully activated for user ${user.email}`);
  }

  async generateResetToken(userId: string): Promise<string> {
    const user = await this.usersService.findOne(userId);
    if (!user) throw new Error('User not found');

    const token = await this.generateRandomToken();
    const hash = await this.hashToken(token);

    // 30 mins expiry
    const expires = new Date();
    expires.setMinutes(expires.getMinutes() + 30);

    await this.usersService.updateTokens(userId, { resetTokenHash: hash, resetTokenExpires: expires });
    return token;
  }

  async resetPassword(token: string, password: string): Promise<void> {
    const hash = await this.hashToken(token);
    const user = await this.usersService.findOneByResetTokenHash(hash);

    if (!user) {
      throw new UnauthorizedException('Invalid token');
    }

    if (user.resetTokenExpires && user.resetTokenExpires < new Date()) {
      throw new UnauthorizedException('Token expired');
    }

    const passwordHash = await bcrypt.hash(password, 10);

    await this.usersService.updateTokens(user.id, {
      resetTokenHash: null,
      resetTokenExpires: null,
      passwordHash: passwordHash,
      tokenVersion: (user.tokenVersion || 0) + 1
    });
  }

  async changePassword(userId: string, dto: ChangePasswordDto): Promise<void> {
    // Use findOneWithSecrets to ensure we get the passwordHash
    const user = await this.usersService.findOneWithSecrets(userId);
    if (!user) throw new Error('User not found');

    if (!user.passwordHash) {
      throw new UnauthorizedException('Cannot ensure security: User has no password set');
    }

    // Verify current password
    const isMatch = await bcrypt.compare(dto.currentPassword, user.passwordHash);
    if (!isMatch) {
      throw new UnauthorizedException('Contraseña actual incorrecta');
    }

    // Hash new password
    const newHash = await bcrypt.hash(dto.newPassword, 10);

    // Update user
    await this.usersService.updateTokens(user.id, {
      passwordHash: newHash,
      tokenVersion: (user.tokenVersion || 0) + 1
    });

    this.logger.log(`Password changed for user ${user.email}`);
  }

  async logout(userId: string): Promise<void> {
    const user = await this.usersService.findOne(userId);
    if (user) {
      await this.usersService.updateTokens(userId, {
        tokenVersion: (user.tokenVersion || 0) + 1
      });
      this.logger.log(`User ${user.email} logged out (Token invalidated)`);
    }
  }

  private async generateRandomToken(): Promise<string> {
    const { randomBytes } = await import('crypto');
    return randomBytes(32).toString('hex');
  }

  private async hashToken(token: string): Promise<string> {
    const { createHash } = await import('crypto');
    return createHash('sha256').update(token).digest('hex');
  }
}
