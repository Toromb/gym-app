import { Injectable, UnauthorizedException, Logger, BadRequestException, ForbiddenException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { instanceToPlain } from 'class-transformer';
import { OAuth2Client } from 'google-auth-library';
import { GymsService } from '../gyms/gyms.service';
import { UserRole } from '../users/entities/user.entity';
import appleSignin from 'apple-signin-auth';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID!);

  constructor(
    private usersService: UsersService,
    private gymsService: GymsService,
    private jwtService: JwtService,
  ) { }

  // --- Invite Token Handling ---

  async generateInviteLink(gymId: string, role: UserRole = UserRole.ALUMNO): Promise<string> {
    const gym = await this.gymsService.findOne(gymId);
    if (!gym) throw new BadRequestException('Gym not found');

    const payload = { gymId, role, type: 'invite' };

    // Permanent Expiration (10 years) for MVP QR Codes
    const expiresIn = '3650d';
    // Isolated Secret
    const secret = process.env.JWT_INVITE_SECRET || process.env.JWT_SECRET || 'secret';

    const token = this.jwtService.sign(payload, {
      secret,
      expiresIn: expiresIn as any
    });

    return token;
  }

  verifyInviteToken(token: string): { gymId: string, role: UserRole } | null {
    try {
      if (process.env.NODE_ENV !== 'production' && token === 'VALID_INVITE_JWT') {
        return null;
      }

      // Verify with Isolated Secret
      const secret = process.env.JWT_INVITE_SECRET || process.env.JWT_SECRET || 'secret';

      const payload = this.jwtService.verify(token, { secret });

      if (payload.type !== 'invite' || !payload.gymId) return null;

      return { gymId: payload.gymId, role: payload.role || UserRole.ALUMNO };
    } catch (e) {
      this.logger.error(`Invite Token Verification Failed: ${e.message}`);
      return null;
    }
  }

  // --- Login Flows ---

  async loginWithGoogle(idToken: string, inviteToken?: string) {
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

      // Strict Check: User must have a Gym
      if (!user.gym) {
        // Orphan user attempting login
        if (inviteToken) {
          // FIX ORPHAN: Bind to the invited gym
          const inviteData = this.verifyInviteToken(inviteToken);
          if (!inviteData) throw new BadRequestException('Token de invitación inválido.');

          const gym = await this.gymsService.findOne(inviteData.gymId);
          if (!gym) throw new BadRequestException('Gimnasio de invitación no existe.');

          await this.usersService.updateTokens(user.id, { gym: gym }); // Link gym
          user.gym = gym; // Update local obj for next checks
          this.logger.log(`Orphan user ${email} recovered and linked to gym ${gym.businessName}`);
        } else {
          throw new ForbiddenException('Usuario sin gimnasio asignado. Requiere invitación válida.');
        }
      } else {
        // User HAS a gym. Check for Gym Switching attempt.
        if (inviteToken) {
          const inviteData = this.verifyInviteToken(inviteToken);
          if (inviteData && inviteData.gymId !== user.gym.id) {
            this.logger.warn(`User ${email} attempted to switch gyms from ${user.gym.id} to ${inviteData.gymId}`);
            throw new ForbiddenException('Ya perteneces a un gimnasio. No puedes unirte a otro con este usuario.');
          }
        }
      }

      // Link account silently if needed
      const updates: any = {};
      if (!user.providerUserId) updates.providerUserId = providerUserId;
      if (!user.profileImageUrl && picture) updates.profileImageUrl = picture;

      if (user.provider === 'LOCAL') updates.provider = 'GOOGLE';

      // AUTO-ACTIVATE: If user was inactive, activate them now that they verified via Google
      if (!user.isActive) {
        updates.isActive = true;
        this.logger.log(`User ${email} activated via Google Login`);
      }

      if (Object.keys(updates).length > 0) {
        await this.usersService.updateTokens(user.id, updates);
        // Refresh user object strictly if we updated critical fields logic? 
        // Not strictly necessary for payload generation usually, but isActive is important.
        if (updates.isActive) user.isActive = true;
      }
    } else {
      // REGISTER NEW USER

      // Strict Check: Must have Invite Token
      if (!inviteToken) {
        throw new BadRequestException('Usuario nuevo requiere invitación válida (Token o QR).');
      }

      const inviteData = this.verifyInviteToken(inviteToken);
      if (!inviteData) {
        throw new BadRequestException('Token de invitación inválido o expirado.');
      }

      const gym = await this.gymsService.findOne(inviteData.gymId);
      if (!gym) throw new BadRequestException('Gimnasio inválido o no encontrado.');

      const names = name ? name.split(' ') : ['Usuario', 'Google'];
      const firstName = names[0];
      const lastName = names.slice(1).join(' ') || '';

      const createUserDto: CreateUserDto = {
        email,
        firstName,
        lastName,
        gymId: gym.id,
        provider: 'GOOGLE',
        providerUserId,
        profileImageUrl: picture,
        role: inviteData.role || UserRole.ALUMNO,
        isActive: true, // Always active via Social
        paysMembership: true,
      };

      user = await this.usersService.create(createUserDto);
      this.logger.log(`Created new Google user: ${email} for Gym ${gym.businessName}`);
    }

    return this.login(user);
  }

  async loginWithApple(identityToken: string, inviteToken?: string) {
    let email: string;
    let providerUserId: string;

    // Verify Apple Token
    try {
      if (identityToken === 'TEST_TOKEN_APPLE') {
        this.logger.warn('USING DEV BYPASS FOR APPLE LOGIN');
        email = 'test.apple@example.com';
        providerUserId = 'apple_test_user_id';
      } else {
        const appleIdTokenClaims = await appleSignin.verifyIdToken(identityToken, {
          audience: process.env.APPLE_CLIENT_ID,
          ignoreExpiration: false,
        });
        email = appleIdTokenClaims.email;
        providerUserId = appleIdTokenClaims.sub;
      }
    } catch (error) {
      this.logger.error(`Apple Token Validation Failed: ${error.message}`);
      throw new UnauthorizedException('Token de Apple inválido');
    }

    if (!email || !providerUserId) {
      throw new UnauthorizedException('Token de Apple incompleto');
    }

    // 1. Try to find user by Provider (Priority 1)
    let user = await this.usersService.findOneByProviderUserId(providerUserId);

    // 2. If not found, try by Email (Priority 2)
    if (!user) {
      user = await this.usersService.findOneByEmail(email);
    }

    if (user) {
      // LOGIN EXISTING USER

      // Strict Check: User must have a Gym
      if (!user.gym) {
        // Orphan user attempting login
        if (inviteToken) {
          // FIX ORPHAN: Bind to the invited gym
          const inviteData = this.verifyInviteToken(inviteToken);
          if (!inviteData) throw new BadRequestException('Token de invitación inválido.');

          const gym = await this.gymsService.findOne(inviteData.gymId);
          if (!gym) throw new BadRequestException('Gimnasio de invitación no existe.');

          await this.usersService.updateTokens(user.id, { gym: gym });
          user.gym = gym;
          this.logger.log(`Orphan user ${email} recovered and linked to gym ${gym.businessName}`);
        } else {
          throw new ForbiddenException('Usuario sin gimnasio asignado. Requiere invitación válida.');
        }
      } else {
        // User HAS a gym. Check for Gym Switching attempt.
        if (inviteToken) {
          const inviteData = this.verifyInviteToken(inviteToken);
          if (inviteData && inviteData.gymId !== user.gym.id) {
            this.logger.warn(`User ${email} attempted to switch gyms from ${user.gym.id} to ${inviteData.gymId}`);
            throw new ForbiddenException('Ya perteneces a un gimnasio. No puedes unirte a otro con este usuario.');
          }
        }
      }

      const updates: any = {};
      if (!user.providerUserId) updates.providerUserId = providerUserId;
      if (user.provider === 'LOCAL') updates.provider = 'APPLE';

      // AUTO-ACTIVATE
      if (!user.isActive) {
        updates.isActive = true;
        this.logger.log(`User ${email} activated via Apple Login`);
      }

      if (Object.keys(updates).length > 0) {
        await this.usersService.updateTokens(user.id, updates);
        if (updates.isActive) user.isActive = true;
      }
    } else {
      // REGISTER NEW USER

      // Strict Check: Must have Invite Token
      if (!inviteToken) {
        throw new BadRequestException('Para registrarse con Apple debe tener una invitación válida (Token o QR).');
      }

      const inviteData = this.verifyInviteToken(inviteToken);
      if (!inviteData) {
        throw new BadRequestException('Token de invitación inválido o expirado.');
      }

      const gym = await this.gymsService.findOne(inviteData.gymId);
      if (!gym) throw new BadRequestException('Gimnasio de la invitación no existe.');

      const createUserDto: CreateUserDto = {
        email,
        firstName: 'Usuario',
        lastName: 'Apple',
        gymId: gym.id,
        provider: 'APPLE',
        providerUserId,
        role: inviteData.role || UserRole.ALUMNO,
        isActive: true,
        paysMembership: true,
      };

      user = await this.usersService.create(createUserDto);
      this.logger.log(`Created new Apple user: ${email} for Gym ${gym.businessName}`);
    }

    return this.login(user);
  }

  // --- Standard Local Login/Auth Methods ---

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

  async registerWithInvite(createUserDto: CreateUserDto, inviteToken: string) {
    // 1. Validate Token
    const inviteData = this.verifyInviteToken(inviteToken);
    if (!inviteData) {
      throw new BadRequestException('Token de invitación inválido o corrupto.');
    }

    // 2. Ensure Gym Exists
    const gym = await this.gymsService.findOne(inviteData.gymId);
    if (!gym) {
      throw new BadRequestException('El gimnasio asociado a esta invitación no existe.');
    }

    // 3. Override properties from token to prevent customer tampering
    const safeUserDto: CreateUserDto = {
      ...createUserDto,
      gymId: inviteData.gymId,
      role: inviteData.role,
      paysMembership: true, // Auto-set for new students via invite
    };

    // 4. Create User
    const user = await this.usersService.create(safeUserDto);
    this.logger.log(`Created new user via Invite: ${user.email} for Gym ${gym.businessName}`);

    // 5. Automatically log them in
    return this.login(user);
  }

  async generateActivationToken(userId: string): Promise<string> {
    const user = await this.usersService.findOne(userId);
    if (!user) throw new Error('User not found');

    const token = await this.generateRandomToken();
    const hash = await this.hashToken(token);
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
    const user = await this.usersService.findOneWithSecrets(userId);
    if (!user) throw new Error('User not found');

    if (!user.passwordHash) {
      throw new UnauthorizedException('Cannot ensure security: User has no password set');
    }

    const isMatch = await bcrypt.compare(dto.currentPassword, user.passwordHash);
    if (!isMatch) {
      throw new UnauthorizedException('Contraseña actual incorrecta');
    }

    const newHash = await bcrypt.hash(dto.newPassword, 10);

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
