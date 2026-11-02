import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { OciStorageService } from '../evidence/oci-storage.service';
import { UploadedFileDto } from '../evidence/evidence.types';

export interface ReportIncidentDto {
  description: string;
  photoUrl?: string;
}

@Injectable()
export class IncidentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly ociStorage: OciStorageService,
  ) {}

  async reportIncident(
    tripId: string,
    dto: ReportIncidentDto,
    transporterId: string,
    file?: UploadedFileDto,
  ) {
    const assignedTrip = await this.prisma.transportTrip.findFirst({
      where: { id: tripId, transporterId },
      select: { id: true },
    });
    if (!assignedTrip) throw new NotFoundException('Viaje asignado no encontrado');

    let finalPhotoUrl = dto.photoUrl;

    if (file) {
      const { url } = await this.ociStorage.uploadFile(file, `incidencias/${tripId}`);
      finalPhotoUrl = url;
    }

    return this.prisma.incident.create({
      data: {
        tripId,
        description: dto.description,
        photoUrl: finalPhotoUrl || null,
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
