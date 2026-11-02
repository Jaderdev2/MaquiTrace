import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Request,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiParam, ApiTags } from '@nestjs/swagger';
import { ReceiveTransportDto, TransportService, UpdateTransportDto } from './transport.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { Roles, RolesGuard } from '../auth/guards/roles.guard';

@ApiTags('Transport')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('administrador')
@Controller('transport')
export class TransportController {
  constructor(private readonly transportService: TransportService) {}

  @Post('receive/:machineId')
  @ApiOperation({
    summary: 'Asignar un viaje de transporte desde administración',
    description: 'Crea un viaje pendiente asociando maquinaria, conductor, vehículo y destino.',
  })
  @ApiParam({ name: 'machineId', description: 'UUID o identificador de la máquina' })
  async receive(
    @Param('machineId') machineId: string,
    @Body() dto: ReceiveTransportDto,
  ) {
    return this.transportService.receiveMachine(machineId, dto);
  }

  @Post('depart/:machineId')
  @Roles('transportador')
  @ApiOperation({
    summary: 'El conductor asignado registra la salida e inicia la ruta',
    description: 'Solo el transportador asignado puede cambiar el viaje y la máquina a en_transito.',
  })
  @ApiParam({ name: 'machineId', description: 'UUID o identificador de la máquina' })
  async depart(@Param('machineId') machineId: string, @Request() req: any) {
    return this.transportService.markDeparture(machineId, this.getAuthenticatedUserId(req));
  }

  @Post('deliver/:machineId')
  @Roles('transportador')
  @ApiOperation({
    summary: 'El conductor asignado confirma la entrega final',
    description: 'Solo el transportador asignado puede cerrar el viaje y marcar la máquina como entregada.',
  })
  @ApiParam({ name: 'machineId', description: 'UUID o identificador de la máquina' })
  async deliver(@Param('machineId') machineId: string, @Request() req: any) {
    return this.transportService.markDelivered(machineId, this.getAuthenticatedUserId(req));
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Actualizar destino, vehículo o conductor asignado al viaje' })
  @ApiParam({ name: 'id', description: 'ID del viaje de transporte' })
  async updateTrip(
    @Param('id') id: string,
    @Body() dto: UpdateTransportDto,
  ) {
    return this.transportService.updateTrip(id, dto);
  }

  @Get('active')
  @ApiOperation({ summary: 'Listar todos los viajes de transporte en curso o activos' })
  async getActive() {
    return this.transportService.getActiveTrips();
  }

  @Get('my-trips')
  @Roles('transportador')
  @ApiOperation({ summary: 'Listar viajes asignados al transportador autenticado' })
  async getMyTrips(@Request() req: any) {
    return this.transportService.getTransporterTrips(this.getAuthenticatedUserId(req));
  }

  @Get('by-machine/:machineId')
  @ApiOperation({ summary: 'Consultar viaje activo asociado a una maquinaria' })
  async getActiveByMachine(@Param('machineId') machineId: string) {
    return this.transportService.getActiveTripByMachine(machineId);
  }

  @Get()
  @ApiOperation({ summary: 'Listar todos los viajes de transporte registrados' })
  async getAll() {
    return this.transportService.getAllTrips();
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Eliminar un viaje de transporte' })
  async delete(@Param('id') id: string) {
    return this.transportService.deleteTrip(id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Obtener detalle de un viaje específico por ID' })
  async getById(@Param('id') id: string) {
    return this.transportService.getTripById(id);
  }

  private getAuthenticatedUserId(req: any): string {
    const userId = req.user?.sub || req.user?.id;
    if (!userId) throw new UnauthorizedException('No se pudo identificar al usuario autenticado');
    return userId;
  }
}
