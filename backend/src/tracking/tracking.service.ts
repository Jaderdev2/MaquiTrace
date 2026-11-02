import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { TripStatus } from '@prisma/client';

export interface RecordGpsDto {
  latitude: number;
  longitude: number;
}

@Injectable()
export class TrackingService {
  constructor(private readonly prisma: PrismaService) {}

  async recordPosition(tripId: string, dto: RecordGpsDto, transporterId: string) {
    const trip = await this.prisma.transportTrip.findFirst({
      where: { id: tripId, transporterId },
      select: { status: true },
    });
    if (!trip) throw new NotFoundException(`Viaje asignado no encontrado`);
    if (trip.status !== TripStatus.en_transito) {
      throw new ConflictException('Solo se puede reportar ubicación durante un viaje en tránsito');
    }

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
