import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EvidenceType } from '@prisma/client';

export interface RegisterEvidenceDto {
  machineId: string;
  phaseId?: string;
  type: EvidenceType;
  url: string;
  uploadedBy: string;
}

@Injectable()
export class EvidenceService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: RegisterEvidenceDto) {
    return this.prisma.evidence.create({
      data: {
        machineId: dto.machineId,
        phaseId: dto.phaseId,
        type: dto.type,
        url: dto.url,
        uploadedBy: dto.uploadedBy,
      },
      include: { uploader: true, phase: true },
    });
  }

  async findByMachine(machineId: string) {
    return this.prisma.evidence.findMany({
      where: { machineId },
      include: { uploader: true, phase: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findByPhase(phaseId: string) {
    return this.prisma.evidence.findMany({
      where: { phaseId },
      include: { uploader: true },
      orderBy: { createdAt: 'desc' },
    });
  }
}
