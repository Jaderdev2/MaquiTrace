import { PushService } from './push.service';
import { Module } from '@nestjs/common';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';

@Module({
  controllers: [NotificationsController],
  providers: [NotificationsService, PushService],
  exports: [NotificationsService],
})
export class NotificationsModule {}
