import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { MachineStatus } from '@prisma/client';
import { OciStorageService } from '../evidence/oci-storage.service';
import { UploadedFileDto } from '../evidence/evidence.types';

export interface CreateMachineDto {
  category: string;
  serial: string;
  model: string;
  status?: MachineStatus;
  imageUrl?: string;
}

export interface UpdateMachineDto {
  category?: string;
  serial?: string;
  model?: string;
  status?: MachineStatus;
  imageUrl?: string;
}

@Injectable()
export class MachinesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly ociStorage: OciStorageService,
  ) {}

  private async attachFreshUrls(machine: any) {
    if (!machine) return machine;
    if (machine.imageUrl) {
      machine.imageUrl = await this.ociStorage.ensureFreshUrl(machine.imageUrl);
    }
    if (machine.evidence && Array.isArray(machine.evidence)) {
      for (const ev of machine.evidence) {
        if (ev.url) {
          ev.url = await this.ociStorage.ensureFreshUrl(ev.url);
        }
      }
    }
    if (machine.phases && Array.isArray(machine.phases)) {
      for (const ph of machine.phases) {
        if (ph.evidence && Array.isArray(ph.evidence)) {
          for (const ev of ph.evidence) {
            if (ev.url) {
              ev.url = await this.ociStorage.ensureFreshUrl(ev.url);
            }
          }
        }
      }
    }
    return machine;
  }

  async findAll(category?: string, status?: MachineStatus, serial?: string) {
    const list = await this.prisma.machine.findMany({
      where: {
        category: category || undefined,
        status: status || undefined,
        serial: serial ? { contains: serial, mode: 'insensitive' } : undefined,
      },
      include: {
        phases: {
          include: { operator: true },
          orderBy: { name: 'asc' },
        },
        evidence: true,
        trips: {
          take: 1,
          orderBy: { departureAt: 'desc' },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
    return Promise.all(list.map((m) => this.attachFreshUrls(m)));
  }

  async findBySerial(serial: string) {
    const machine = await this.prisma.machine.findUnique({
      where: { serial },
      include: {
        phases: {
          include: { operator: true, evidence: true },
        },
        evidence: true,
        trips: {
          include: { transporter: true, gpsRecords: true, incidents: true },
          orderBy: { departureAt: 'desc' },
        },
      },
    });

    if (!machine) {
      throw new NotFoundException(`Máquina con serial ${serial} no encontrada`);
    }
    return this.attachFreshUrls(machine);
  }

  async findById(id: string) {
    const machine = await this.prisma.machine.findUnique({
      where: { id },
      include: {
        phases: {
          include: { operator: true, evidence: true },
        },
        evidence: true,
        trips: {
          include: { transporter: true },
          orderBy: { departureAt: 'desc' },
        },
      },
    });

    if (!machine) {
      throw new NotFoundException(`Máquina con ID ${id} no encontrada`);
    }
    return this.attachFreshUrls(machine);
  }

  async create(dto: CreateMachineDto) {
    return this.prisma.machine.create({
      data: {
        category: dto.category,
        serial: dto.serial,
        model: dto.model,
        status: dto.status || MachineStatus.pendiente,
        imageUrl: dto.imageUrl || null,
      },
    });
  }

  async update(id: string, dto: UpdateMachineDto) {
    await this.findById(id);
    return this.prisma.machine.update({
      where: { id },
      data: {
        category: dto.category,
        serial: dto.serial,
        model: dto.model,
        status: dto.status,
        imageUrl: dto.imageUrl !== undefined ? dto.imageUrl : undefined,
      },
    });
  }

  /**
   * Sube o actualiza la foto de avatar de la maquinaria directamente a Oracle Cloud.
   * Actualiza el campo `imageUrl` de la máquina SIN insertar ningún registro en la tabla Evidence.
   */
  async updateAvatar(id: string, file: UploadedFileDto) {
    if (!file) {
      throw new BadRequestException('Se requiere adjuntar un archivo de imagen para el avatar.');
    }
    await this.findById(id);

    const { key, url } = await this.ociStorage.uploadFile(file, `avatars/${id}`);

    const machine = await this.prisma.machine.update({
      where: { id },
      data: { imageUrl: url },
      include: {
        phases: { include: { operator: true } },
        evidence: { include: { uploader: true } },
      },
    });

    return {
      message: 'Avatar de maquinaria actualizado exitosamente',
      imageUrl: url,
      storageKey: key,
      machine,
    };
  }

  async remove(id: string) {
    await this.findById(id);

    return this.prisma.$transaction(async (tx) => {
      // 1. Encontrar viajes asociados
      const trips = await tx.transportTrip.findMany({
        where: { machineId: id },
        select: { id: true },
      });
      const tripIds = trips.map((t) => t.id);

      if (tripIds.length > 0) {
        await tx.gpsRecord.deleteMany({
          where: { tripId: { in: tripIds } },
        });
        await tx.incident.deleteMany({
          where: { tripId: { in: tripIds } },
        });
        await tx.transportTrip.deleteMany({
          where: { id: { in: tripIds } },
        });
      }

      // 2. Eliminar evidencias vinculadas a la máquina
      await tx.evidence.deleteMany({
        where: { machineId: id },
      });

      // 3. Eliminar fases de alistamiento
      await tx.preparationPhase.deleteMany({
        where: { machineId: id },
      });

      // 4. Eliminar la maquinaria
      return tx.machine.delete({
        where: { id },
      });
    });
  }

  async getHistory(id: string) {
    const machine = await this.findById(id);
    return {
      machineId: machine.id,
      serial: machine.serial,
      model: machine.model,
      phases: machine.phases,
      trips: machine.trips,
      evidence: machine.evidence,
    };
  }
}
