import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  async send(userId: string, message: string) {
    // Mock implementation for FCM
    this.logger.log(`[MOCK FCM] Sending notification to ${userId}: ${message}`);
    return { sent: true };
  }
}
