import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { TripStatus } from '@prisma/client';

export interface RecordGpsDto {
  latitude: number;
  longitude: number;
}

@Injectable()
export class TrackingService {
  constructor(private readonly prisma: PrismaService) {}

  async recordPosition(tripId: string, dto: RecordGpsDto) {
    return this.prisma.gpsRecord.create({
      data: {
        tripId,
        latitude: dto.latitude,
        longitude: dto.longitude,
      },
    });
  }

  async getActiveMachinesInTransit() {
    return this.prisma.transportTrip.findMany({
      where: { status: TripStatus.en_transito },
      include: {
        machine: true,
        transporter: true,
        gpsRecords: {
          take: 1,
          orderBy: { recordedAt: 'desc' },
        },
      },
    });
  }

  async getTripHistory(tripId: string) {
    return this.prisma.gpsRecord.findMany({
      where: { tripId },
      orderBy: { recordedAt: 'asc' },
    });
  }
}
