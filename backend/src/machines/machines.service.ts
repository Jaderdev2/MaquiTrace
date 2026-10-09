import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { MachineStatus } from '@prisma/client';

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
  constructor(private readonly prisma: PrismaService) {}

  async findAll(category?: string, status?: MachineStatus, serial?: string) {
    return this.prisma.machine.findMany({
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
    return machine;
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
    return machine;
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
