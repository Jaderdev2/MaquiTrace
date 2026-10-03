import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export interface ReportIncidentDto {
  description: string;
  photoUrl?: string;
}

@Injectable()
export class IncidentsService {
  constructor(private readonly prisma: PrismaService) {}

  async reportIncident(tripId: string, dto: ReportIncidentDto) {
    return this.prisma.incident.create({
      data: {
        tripId,
        description: dto.description,
        photoUrl: dto.photoUrl,
      },
      include: { trip: { include: { machine: true, transporter: true } } },
    });
  }

  async findByTrip(tripId: string) {
    return this.prisma.incident.findMany({
      where: { tripId },
      orderBy: { reportedAt: 'desc' },
    });
  }
}
