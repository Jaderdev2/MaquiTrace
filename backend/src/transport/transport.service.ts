import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { MachineStatus, TripStatus } from '@prisma/client';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class ReceiveTransportDto {
  @IsString()
  @IsNotEmpty()
  transporterId!: string;

  @IsString()
  @IsNotEmpty()
  vehicle!: string;

  @IsString()
  @IsNotEmpty()
  destination!: string;
}

export class UpdateTransportDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  transporterId?: string;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  vehicle?: string;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  destination?: string;
}

@Injectable()
export class TransportService {
  constructor(private readonly prisma: PrismaService) {}

  // El administrador asigna un conductor y programa el despacho.
  async receiveMachine(machineId: string, dto: ReceiveTransportDto) {
    if (!dto.transporterId?.trim()) {
      throw new BadRequestException('Debes asignar un transportador al viaje');
    }

    const transporter = await this.prisma.user.findFirst({
      where: { id: dto.transporterId, role: { name: 'transportador' } },
    });
    if (!transporter) {
      throw new BadRequestException('El usuario seleccionado no tiene el rol de transportador');
    }

    return this.prisma.$transaction(async (transaction) => {
      const machine = await transaction.machine.findUnique({ where: { id: machineId } });
      if (!machine) throw new NotFoundException(`Máquina con ID ${machineId} no encontrada`);

      const existingTrip = await transaction.transportTrip.findFirst({
        where: {
          machineId,
          status: { in: [TripStatus.pendiente, TripStatus.en_transito] },
        },
      });
      if (existingTrip) {
        throw new ConflictException('La máquina ya tiene un viaje activo asignado');
      }

      const trip = await transaction.transportTrip.create({
        data: {
          machineId,
          transporterId: dto.transporterId,
          vehicle: dto.vehicle,
          destination: dto.destination,
          status: TripStatus.pendiente,
        },
        include: { machine: true, transporter: true },
      });

      await transaction.machine.update({
        where: { id: machineId },
        data: { status: MachineStatus.en_proceso },
      });

      return trip;
    });
  }

  // El conductor solo puede iniciar un viaje que le fue asignado.
  async markDeparture(machineId: string, transporterId: string) {
    if (!transporterId) throw new UnauthorizedException('No se pudo identificar al conductor');

    return this.prisma.$transaction(async (transaction) => {
      const activeTrip = await transaction.transportTrip.findFirst({
        where: {
          machineId,
          transporterId,
          status: TripStatus.pendiente,
        },
        orderBy: { id: 'desc' },
      });

      if (!activeTrip) {
        throw new NotFoundException(`No hay viaje pendiente asignado para la máquina ${machineId}`);
      }

      const transition = await transaction.transportTrip.updateMany({
        where: {
          id: activeTrip.id,
          transporterId,
          status: TripStatus.pendiente,
        },
        data: {
          status: TripStatus.en_transito,
          departureAt: new Date(),
        },
      });
      if (!transition.count) {
        throw new ConflictException('El viaje ya fue iniciado o cambió de asignación');
      }

      await transaction.machine.update({
        where: { id: machineId },
        data: { status: MachineStatus.en_transito },
      });

      return transaction.transportTrip.findUnique({
        where: { id: activeTrip.id },
        include: { machine: true, transporter: true },
      });
    });
  }

  // El conductor solo puede cerrar un viaje que le fue asignado.
  async markDelivered(machineId: string, transporterId: string) {
    if (!transporterId) throw new UnauthorizedException('No se pudo identificar al conductor');

    return this.prisma.$transaction(async (transaction) => {
      const activeTrip = await transaction.transportTrip.findFirst({
        where: {
          machineId,
          transporterId,
          status: TripStatus.en_transito,
        },
        orderBy: { id: 'desc' },
      });

      if (!activeTrip) {
        throw new NotFoundException(`No hay viaje en tránsito asignado para la máquina ${machineId}`);
      }

      const transition = await transaction.transportTrip.updateMany({
        where: {
          id: activeTrip.id,
          transporterId,
          status: TripStatus.en_transito,
        },
        data: {
          status: TripStatus.entregado,
          arrivalAt: new Date(),
        },
      });
      if (!transition.count) {
        throw new ConflictException('El viaje ya fue entregado o cambió de asignación');
      }

      await transaction.machine.update({
        where: { id: machineId },
        data: { status: MachineStatus.entregada },
      });

      return transaction.transportTrip.findUnique({
        where: { id: activeTrip.id },
        include: { machine: true, transporter: true },
      });
    });
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

  async getTransporterTrips(transporterId: string) {
    return this.prisma.transportTrip.findMany({
      where: { transporterId },
      include: {
        machine: true,
        transporter: true,
        gpsRecords: {
          take: 1,
          orderBy: { recordedAt: 'desc' },
        },
        incidents: true,
      },
      orderBy: { id: 'desc' },
    });
  }

  async getActiveTripByMachine(machineId: string) {
    return this.prisma.transportTrip.findFirst({
      where: {
        machineId,
        status: { in: [TripStatus.pendiente, TripStatus.en_transito] },
      },
      include: {
        machine: true,
        transporter: true,
        gpsRecords: {
          take: 1,
          orderBy: { recordedAt: 'desc' },
        },
        incidents: true,
      },
      orderBy: { id: 'desc' },
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

  // Listar todos los viajes sin restricción de estado para CRUD completo
  async getAllTrips() {
    return this.prisma.transportTrip.findMany({
      include: {
        machine: true,
        transporter: true,
        gpsRecords: {
          orderBy: { recordedAt: 'asc' },
        },
        incidents: true,
      },
      orderBy: { id: 'desc' },
    });
  }

  // Solo el administrador actualiza la asignación y los datos de ruta.
  async updateTrip(
    id: string,
    dto: UpdateTransportDto,
  ) {
    const trip = await this.prisma.transportTrip.findUnique({ where: { id } });
    if (!trip) throw new NotFoundException(`Viaje con ID ${id} no encontrado`);

    if (dto.transporterId !== undefined) {
      const transporter = await this.prisma.user.findFirst({
        where: { id: dto.transporterId, role: { name: 'transportador' } },
      });
      if (!transporter) {
        throw new BadRequestException('El usuario seleccionado no tiene el rol de transportador');
      }
    }

    return this.prisma.transportTrip.update({
      where: { id },
      data: {
        ...(dto.destination !== undefined ? { destination: dto.destination } : {}),
        ...(dto.vehicle !== undefined ? { vehicle: dto.vehicle } : {}),
        ...(dto.transporterId !== undefined ? { transporterId: dto.transporterId } : {}),
      },
      include: {
        machine: true,
        transporter: true,
        gpsRecords: { orderBy: { recordedAt: 'asc' } },
        incidents: true,
      },
    });
  }

  // Eliminar un viaje de transporte
  async deleteTrip(id: string) {
    const trip = await this.prisma.transportTrip.findUnique({ where: { id } });
    if (!trip) throw new NotFoundException(`Viaje con ID ${id} no encontrado`);

    // Eliminar registros satelitales e incidencias asociados
    await this.prisma.gpsRecord.deleteMany({ where: { tripId: id } });
    await this.prisma.incident.deleteMany({ where: { tripId: id } });

    return this.prisma.transportTrip.delete({
      where: { id },
    });
  }
}
