import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { MachineStatus, PhaseName, PhaseStatus } from '@prisma/client';

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
    const machine = await this.prisma.machine.findUnique({
      where: { id: machineId },
    });
    if (!machine) {
      throw new NotFoundException(`Máquina con id ${machineId} no encontrada`);
    }

    let phases = await this.prisma.preparationPhase.findMany({
      where: { machineId },
      include: { operator: true, evidence: true },
    });

    // Si la máquina no tiene fases aún, inicializar automáticamente las 3 oficiales
    if (phases.length === 0) {
      const defaultOperator = await this.prisma.user.findFirst({
        where: { role: { name: 'operario' } },
      });

      if (defaultOperator) {
        await this.prisma.preparationPhase.createMany({
          data: [
            { machineId, name: PhaseName.lavado, status: PhaseStatus.pendiente, operatorId: defaultOperator.id },
            { machineId, name: PhaseName.ensamblaje, status: PhaseStatus.pendiente, operatorId: defaultOperator.id },
            { machineId, name: PhaseName.pintura, status: PhaseStatus.pendiente, operatorId: defaultOperator.id },
          ],
        });

        phases = await this.prisma.preparationPhase.findMany({
          where: { machineId },
          include: { operator: true, evidence: true },
        });
      }
    }

    // Ordenar siempre en el orden secuencial de alistamiento: 1. lavado -> 2. ensamblaje -> 3. pintura
    const orderMap: Record<PhaseName, number> = {
      [PhaseName.lavado]: 1,
      [PhaseName.ensamblaje]: 2,
      [PhaseName.pintura]: 3,
    };

    return phases.sort((a, b) => (orderMap[a.name] ?? 99) - (orderMap[b.name] ?? 99));
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

    // Regla de Negocio: Restricción de avance secuencial
    if (dto.status === PhaseStatus.en_proceso || dto.status === PhaseStatus.completada) {
      if (phase.name === PhaseName.ensamblaje) {
        const lavado = await this.prisma.preparationPhase.findFirst({
          where: { machineId: phase.machineId, name: PhaseName.lavado },
        });
        if (lavado && lavado.status !== PhaseStatus.completada) {
          throw new BadRequestException(
            'Restricción de avance: La fase de Lavado debe estar completada antes de iniciar o completar Ensamblaje.',
          );
        }
      } else if (phase.name === PhaseName.pintura) {
        const ensamblaje = await this.prisma.preparationPhase.findFirst({
          where: { machineId: phase.machineId, name: PhaseName.ensamblaje },
        });
        if (ensamblaje && ensamblaje.status !== PhaseStatus.completada) {
          throw new BadRequestException(
            'Restricción de avance: La fase de Ensamblaje debe estar completada antes de iniciar o completar Pintura.',
          );
        }
      }
    }

    const completedAt =
      dto.status === PhaseStatus.completada ? new Date() : phase.completedAt;
    const startedAt =
      dto.status === PhaseStatus.en_proceso && !phase.startedAt ? new Date() : phase.startedAt;

    const updated = await this.prisma.preparationPhase.update({
      where: { id: phaseId },
      data: {
        status: dto.status,
        observations: dto.observations !== undefined ? dto.observations : phase.observations,
        startedAt,
        completedAt,
      },
      include: { operator: true, evidence: true },
    });

    // Actualizar estado general de la máquina si todas las fases quedan completadas
    if (dto.status === PhaseStatus.completada) {
      const pendingCount = await this.prisma.preparationPhase.count({
        where: {
          machineId: phase.machineId,
          status: { not: PhaseStatus.completada },
        },
      });

      if (pendingCount === 0) {
        await this.prisma.machine.update({
          where: { id: phase.machineId },
          data: { status: MachineStatus.completada },
        });
      }
    } else if (dto.status === PhaseStatus.en_proceso) {
      await this.prisma.machine.update({
        where: { id: phase.machineId },
        data: { status: MachineStatus.en_proceso },
      });
    }

    return updated;
  }
}
