import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class NotificationsService {
    async send(userId: string, message: string) {
        // Mock implementation for FCM
        console.log(`Sending notification to ${userId}: ${message}`);
        return { sent: true };
    }
}
