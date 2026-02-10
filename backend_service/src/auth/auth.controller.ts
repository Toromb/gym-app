import {
  Controller,
  Post,
  Body,
  UseGuards,
  Get,
  Request,
  UnauthorizedException,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { LoginDto } from './dto/login.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { AuthGuard } from '@nestjs/passport';
import { Throttle } from '@nestjs/throttler';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) { }

  @Post('register')
  async register(@Body() createUserDto: CreateUserDto) {
    return this.authService.register(createUserDto);
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
  async googleLogin(@Body() body: { idToken: string; gymId?: string }) {
    if (!body.idToken) {
      throw new UnauthorizedException('ID Token requerido');
    }
    return this.authService.loginWithGoogle(body.idToken, body.gymId);
  }

  @Post('apple')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  async appleLogin(@Body() body: { identityToken: string; inviteToken?: string; firstName?: string; lastName?: string }) {
    if (!body.identityToken) {
      throw new UnauthorizedException('Identity Token requerido');
    }
    // Apple only sends name on first login, so we might want to pass it to service if needed for user creation.
    // For now, service uses default, but we could enhance it later. 
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
