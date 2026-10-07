import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EvidenceType } from '@prisma/client';
import { OciStorageService } from './oci-storage.service';
import { UploadedFileDto } from './evidence.types';

export interface RegisterEvidenceDto {
  machineId: string;
  phaseId?: string;
  type?: EvidenceType;
  url?: string;
  uploadedBy?: string;
  observations?: string;
}

@Injectable()
export class EvidenceService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly ociStorage: OciStorageService,
  ) {}

  /**
   * Sube un archivo a OCI y crea el registro de evidencia en la BD
   */
  async uploadEvidence(
    machineId: string,
    file: UploadedFileDto,
    dto: { phaseId?: string; type?: EvidenceType; observations?: string },
    userId: string,
  ) {
    if (!file) {
      throw new BadRequestException('Se requiere adjuntar un archivo de evidencia (foto o video).');
    }

    // Verificar que la máquina exista
    const machine = await this.prisma.machine.findUnique({
      where: { id: machineId },
    });
    if (!machine) {
      throw new NotFoundException(`La maquinaria con ID ${machineId} no existe.`);
    }

    // Determinar el tipo (foto o video) automáticamente si no viene especificado
    let evidenceType: EvidenceType = dto.type || EvidenceType.foto;
    if (file.mimetype && file.mimetype.startsWith('video/')) {
      evidenceType = EvidenceType.video;
    }

    // Subir archivo binario a Oracle Cloud Object Storage
    const { key, url } = await this.ociStorage.uploadFile(file, `evidencias/${machineId}`);

    // Si viene asociada a una fase y trae observaciones, opcionalmente actualizar observaciones de la fase
    if (dto.phaseId && dto.observations) {
      await this.prisma.preparationPhase
        .update({
          where: { id: dto.phaseId },
          data: { observations: dto.observations },
        })
        .catch(() => {});
    }

    // Guardar registro de evidencia en PostgreSQL
    const evidence = await this.prisma.evidence.create({
      data: {
        machineId,
        phaseId: dto.phaseId || null,
        type: evidenceType,
        url,
        uploadedBy: userId,
      },
      include: {
        uploader: {
          select: { id: true, name: true, email: true, role: true },
        },
        phase: true,
      },
    });

    return {
      message: 'Evidencia multimedia subida y registrada exitosamente en OCI',
      evidence,
      storageKey: key,
    };
  }

  /**
   * Registra una evidencia con URL existente (compatibilidad hacia atrás)
   */
  async create(dto: RegisterEvidenceDto) {
    return this.prisma.evidence.create({
      data: {
        machineId: dto.machineId,
        phaseId: dto.phaseId,
        type: dto.type || EvidenceType.foto,
        url: dto.url || '',
        uploadedBy: dto.uploadedBy!,
      },
      include: { uploader: true, phase: true },
    });
  }

  /**
   * Consulta todas las evidencias de una máquina
   */
  async findByMachine(machineId: string) {
    return this.prisma.evidence.findMany({
      where: { machineId },
      include: {
        uploader: {
          select: { id: true, name: true, email: true, role: true },
        },
        phase: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Consulta evidencias de una fase específica
   */
  async findByPhase(phaseId: string) {
    return this.prisma.evidence.findMany({
      where: { phaseId },
      include: {
        uploader: {
          select: { id: true, name: true, email: true, role: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}
