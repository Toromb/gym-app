import { Controller, Patch, Param, Body, UseGuards } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { AuthGuard } from '@nestjs/passport';
import { PaymentStatus } from '../users/entities/user.entity';

@Controller('payments')
@UseGuards(AuthGuard('jwt'))
export class PaymentsController {
  constructor(private readonly usersService: UsersService) {}

  @Patch(':userId')
  async updateStatus(
    @Param('userId') userId: string,
    @Body('status') status: PaymentStatus,
  ) {
    // In a real app, we would update this via UsersService method that updates specific fields
    // For MVP, assuming we can add a method to UsersService or use update
    // return this.usersService.updatePaymentStatus(userId, status);
    return { message: 'Payment status updated (mock)' };
  }
}
