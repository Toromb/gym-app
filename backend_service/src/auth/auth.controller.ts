import {
  Controller,
  Post,
  Body,
  UseGuards,
  Get,
  Request,
  UnauthorizedException,
  Query,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { LoginDto } from './dto/login.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { AuthGuard } from '@nestjs/passport';
import { Throttle } from '@nestjs/throttler';
import { UserRole } from '../users/entities/user.entity';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) { }

  @Post('register')
  async register(@Body() createUserDto: CreateUserDto) {
    return this.authService.register(createUserDto);
  }

  @Post('register-with-invite')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  async registerWithInvite(@Body() body: { user: CreateUserDto; inviteToken: string }) {
    if (!body.inviteToken) {
      throw new UnauthorizedException('Token de invitación requerido');
    }
    return this.authService.registerWithInvite(body.user, body.inviteToken);
  }

  @Post('login')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  async login(@Body() loginDto: LoginDto) {
    const user = await this.authService.validateUser(
      loginDto.email,
      loginDto.password,
    );
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }
    return this.authService.login(user);
  }

  @Post('google')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  async googleLogin(@Body() body: { idToken: string; inviteToken?: string }) {
    if (!body.idToken) {
      throw new UnauthorizedException('ID Token requerido');
    }
    return this.authService.loginWithGoogle(body.idToken, body.inviteToken);
  }

  @Post('apple')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  async appleLogin(@Body() body: { identityToken: string; inviteToken?: string; firstName?: string; lastName?: string }) {
    if (!body.identityToken) {
      throw new UnauthorizedException('Identity Token requerido');
    }
    return this.authService.loginWithApple(body.identityToken, body.inviteToken);
  }

  @UseGuards(AuthGuard('jwt'))
  @Post('logout')
  async logout(@Request() req: any) {
    await this.authService.logout(req.user.id);
    return { message: 'Logged out successfully' };
  }

  @UseGuards(AuthGuard('jwt'))
  @Get('profile')
  getProfile(@Request() req: any) {
    return req.user;
  }

  @UseGuards(AuthGuard('jwt'))
  @Post('change-password')
  async changePassword(@Body() dto: ChangePasswordDto, @Request() req: any) {
    const userId = req.user.id;
    await this.authService.changePassword(userId, dto);
    return { message: 'Password updated successfully' };
  }

  @UseGuards(AuthGuard('jwt'))
  @Post('generate-activation-link')
  async generateActivationLink(@Body('userId') userId: string) {
    const token = await this.authService.generateActivationToken(userId);
    return { token };
  }

  @UseGuards(AuthGuard('jwt'))
  @Post('generate-invite-link')
  async generateInviteLink(
    @Body('gymId') gymId: string,
    @Body('role') role?: UserRole
  ) {
    // Only Admin/SuperAdmin should call this
    const token = await this.authService.generateInviteLink(gymId, role);
    return { token };
  }

  @Post('activate-account') // Public
  async activateAccount(@Body() body: any) {
    await this.authService.activateAccount(body.token, body.password);
    return { message: 'Account activated' };
  }

  @UseGuards(AuthGuard('jwt'))
  @Post('generate-reset-link')
  async generateResetLink(@Body('userId') userId: string) {
    const token = await this.authService.generateResetToken(userId);
    return { token };
  }

  @Post('reset-password') // Public
  async resetPassword(@Body() body: any) {
    await this.authService.resetPassword(body.token, body.password);
    return { message: 'Password reset successful' };
  }
}
