import { Module } from '@nestjs/common';
import { PaymentsController } from './payments.controller';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [UsersModule],
  controllers: [PaymentsController],
})
export class PaymentsModule {}
