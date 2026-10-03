import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PhaseName, PhaseStatus } from '@prisma/client';

export interface UpdatePhaseDto {
  status: PhaseStatus;
  observations?: string;
}

export interface CreatePhaseDto {
  machineId: string;
  name: PhaseName;
  operatorId: string;
  observations?: string;
}

@Injectable()
export class PreparationPhasesService {
  constructor(private readonly prisma: PrismaService) {}

  async findByMachine(machineId: string) {
    return this.prisma.preparationPhase.findMany({
      where: { machineId },
      include: { operator: true, evidence: true },
      orderBy: { name: 'asc' },
    });
  }

  async createPhase(dto: CreatePhaseDto) {
    return this.prisma.preparationPhase.create({
      data: {
        machineId: dto.machineId,
        name: dto.name,
        operatorId: dto.operatorId,
        observations: dto.observations,
        status: PhaseStatus.pendiente,
      },
    });
  }

  async updatePhaseStatus(phaseId: string, dto: UpdatePhaseDto) {
    const phase = await this.prisma.preparationPhase.findUnique({
      where: { id: phaseId },
    });

    if (!phase) {
      throw new NotFoundException(`Fase con ID ${phaseId} no encontrada`);
    }

    const completedAt =
      dto.status === PhaseStatus.completada ? new Date() : phase.completedAt;
    const startedAt =
      dto.status === PhaseStatus.en_proceso && !phase.startedAt ? new Date() : phase.startedAt;

    return this.prisma.preparationPhase.update({
      where: { id: phaseId },
      data: {
        status: dto.status,
        observations: dto.observations ?? phase.observations,
        startedAt,
        completedAt,
      },
    });
  }
}
