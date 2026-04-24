import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Request,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { PaymentsService } from './payments.service';
import { RegisterPaymentDto } from './dto/register-payment.dto';
import { UserRole } from '../users/entities/user.entity';

@Controller('payments')
@UseGuards(AuthGuard('jwt'))
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  /**
   * POST /payments/user/:userId
   * Registers one or more monthly payments for a user.
   * Only ADMIN and SUPER_ADMIN can call this endpoint.
   */
  @Post('user/:userId')
  async registerPayment(
    @Param('userId') userId: string,
    @Body() dto: RegisterPaymentDto,
    @Request() req: any,
  ) {
    const requestor = req.user;

    if (
      requestor.role !== UserRole.ADMIN &&
      requestor.role !== UserRole.SUPER_ADMIN
    ) {
      throw new ForbiddenException('Only Admins can register payments');
    }

    return this.paymentsService.registerPayment(userId, dto, requestor);
  }

  /**
   * GET /payments/user/:userId
   * Returns the payment history for a user.
   * Accessible by ADMIN, SUPER_ADMIN, or the user themselves.
   */
  @Get('user/:userId')
  async getPaymentHistory(
    @Param('userId') userId: string,
    @Request() req: any,
  ) {
    const requestor = req.user;

    const isAdmin =
      requestor.role === UserRole.ADMIN ||
      requestor.role === UserRole.SUPER_ADMIN;
    const isSelf = requestor.id === userId;

    if (!isAdmin && !isSelf) {
      throw new ForbiddenException(
        'You can only view your own payment history',
      );
    }

    return this.paymentsService.getPaymentHistory(userId);
  }
}
