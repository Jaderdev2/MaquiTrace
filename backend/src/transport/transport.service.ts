import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { MachineStatus, TripStatus } from '@prisma/client';

export interface ReceiveTransportDto {
  transporterId: string;
  vehicle: string;
  destination: string;
}

@Injectable()
export class TransportService {
  constructor(private readonly prisma: PrismaService) {}

  // 1. Recepción de máquina por el transportador
  async receiveMachine(machineId: string, dto: ReceiveTransportDto) {
    const trip = await this.prisma.transportTrip.create({
      data: {
        machineId,
        transporterId: dto.transporterId,
        vehicle: dto.vehicle,
        destination: dto.destination,
        status: TripStatus.pendiente,
      },
      include: { machine: true, transporter: true },
    });

    // Actualizar estado de la máquina a en_transito o pendiente según proceso
    await this.prisma.machine.update({
      where: { id: machineId },
      data: { status: MachineStatus.en_proceso },
    });

    return trip;
  }

  // 2. Salida en ruta
  async markDeparture(machineId: string) {
    const activeTrip = await this.prisma.transportTrip.findFirst({
      where: {
        machineId,
        status: TripStatus.pendiente,
      },
      orderBy: { id: 'desc' },
    });

    if (!activeTrip) {
      throw new NotFoundException(`No hay viaje pendiente de salida para la máquina ${machineId}`);
    }

    const updatedTrip = await this.prisma.transportTrip.update({
      where: { id: activeTrip.id },
      data: {
        status: TripStatus.en_transito,
        departureAt: new Date(),
      },
      include: { machine: true, transporter: true },
    });

    await this.prisma.machine.update({
      where: { id: machineId },
      data: { status: MachineStatus.en_transito },
    });

    return updatedTrip;
  }

  // 3. Confirmación de entrega
  async markDelivered(machineId: string) {
    const activeTrip = await this.prisma.transportTrip.findFirst({
      where: {
        machineId,
        status: TripStatus.en_transito,
      },
      orderBy: { id: 'desc' },
    });

    if (!activeTrip) {
      throw new NotFoundException(`No hay viaje en tránsito activo para la máquina ${machineId}`);
    }

    const updatedTrip = await this.prisma.transportTrip.update({
      where: { id: activeTrip.id },
      data: {
        status: TripStatus.entregado,
        arrivalAt: new Date(),
      },
      include: { machine: true, transporter: true },
    });

    await this.prisma.machine.update({
      where: { id: machineId },
      data: { status: MachineStatus.entregada },
    });

    return updatedTrip;
  }

  async getActiveTrips() {
    return this.prisma.transportTrip.findMany({
      where: {
        status: { in: [TripStatus.pendiente, TripStatus.en_transito] },
      },
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

  async getTripById(id: string) {
    const trip = await this.prisma.transportTrip.findUnique({
      where: { id },
      include: {
        machine: true,
        transporter: true,
        gpsRecords: { orderBy: { recordedAt: 'asc' } },
        incidents: true,
      },
    });
    if (!trip) throw new NotFoundException(`Viaje con ID ${id} no encontrado`);
    return trip;
  }
}
