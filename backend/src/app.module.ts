import { Module } from '@nestjs/common';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { MachinesModule } from './machines/machines.module';
import { PreparationPhasesModule } from './preparation-phases/preparation-phases.module';
import { EvidenceModule } from './evidence/evidence.module';
import { TransportModule } from './transport/transport.module';
import { TrackingModule } from './tracking/tracking.module';
import { IncidentsModule } from './incidents/incidents.module';
import { NotificationsModule } from './notifications/notifications.module';

@Module({
  imports: [
    PrismaModule,
    AuthModule,
    UsersModule,
    MachinesModule,
    PreparationPhasesModule,
    EvidenceModule,
    TransportModule,
    TrackingModule,
    IncidentsModule,
    NotificationsModule,
  ],
})
export class AppModule {}
