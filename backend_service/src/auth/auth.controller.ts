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
import { AuthGuard } from '@nestjs/passport';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) { }

  @Post('register')
  async register(@Body() createUserDto: CreateUserDto) {
    return this.authService.register(createUserDto);
  }

  @Post('login')
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

<<<<<<< HEAD
    @UseGuards(AuthGuard('jwt'))
    @Get('profile')
    getProfile(@Request() req: any) {
        return req.user;
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
=======
  @UseGuards(AuthGuard('jwt'))
  @Get('profile')
  getProfile(@Request() req: any) {
    return req.user;
  }
>>>>>>> origin/main
}
