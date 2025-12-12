export declare class NotificationsService {
    send(userId: string, message: string): Promise<{
        sent: boolean;
    }>;
}
