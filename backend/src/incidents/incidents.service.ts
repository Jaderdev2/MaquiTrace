import { notifyAdmins } from "../notifications/notification-events";
import { Injectable, NotFoundException } from "@nestjs/common";
import { PrismaService } from "../prisma/prisma.service";
import { OciStorageService } from "../evidence/oci-storage.service";
import { UploadedFileDto } from "../evidence/evidence.types";

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
    if (!assignedTrip)
      throw new NotFoundException("Viaje asignado no encontrado");

    let finalPhotoUrl = dto.photoUrl;

    if (file) {
      const { url } = await this.ociStorage.uploadFile(
        file,
        `incidencias/${tripId}`,
      );
      finalPhotoUrl = url;
    }

    return this.prisma.$transaction(async (transaction) => {
      const incident = await transaction.incident.create({
        data: {
          tripId,
          description: dto.description,
          photoUrl: finalPhotoUrl || null,
        },
        include: { trip: { include: { machine: true, transporter: true } } },
      });
      await notifyAdmins(transaction, {
        type: "incident_reported",
        title: "Novedad en ruta",
        message: `Se reportó una novedad para la máquina ${incident.trip.machine.serial}: ${incident.description}`,
        machineId: incident.trip.machineId,
        tripId,
      });
      return incident;
    });
  }

  async findByTrip(tripId: string) {
    const list = await this.prisma.incident.findMany({
      where: { tripId },
      orderBy: { reportedAt: "desc" },
    });
    return Promise.all(
      list.map(async (inc) => {
        if (inc.photoUrl) {
          inc.photoUrl =
            (await this.ociStorage.ensureFreshUrl(inc.photoUrl)) || inc.photoUrl;
        }
        return inc;
      }),
    );
  }
}
