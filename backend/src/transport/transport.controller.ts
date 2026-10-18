import { Body, Controller, Delete, Get, Param, Patch, Post, Request, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiParam, ApiTags } from '@nestjs/swagger';
import { ReceiveTransportDto, TransportService } from './transport.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('Transport')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller('transport')
export class TransportController {
  constructor(private readonly transportService: TransportService) {}

  @Post('receive/:machineId')
  @ApiOperation({
    summary: 'Registrar recepción de maquinaria por el transportador',
    description: 'Crea el viaje de transporte en estado pendiente asociando conductor, vehículo y destino.',
  })
  @ApiParam({ name: 'machineId', description: 'UUID o identificador de la máquina' })
  async receive(
    @Param('machineId') machineId: string,
    @Body() dto: ReceiveTransportDto,
    @Request() req: any,
  ) {
    const userId = req.user?.sub || req.user?.id;
    return this.transportService.receiveMachine(machineId, dto, userId);
  }

  @Post('depart/:machineId')
  @ApiOperation({
    summary: 'Registrar salida e inicio de ruta de transporte',
    description: 'Cambia el estado del viaje y de la máquina a en_transito e inicia cronometraje de salida.',
  })
  @ApiParam({ name: 'machineId', description: 'UUID o identificador de la máquina' })
  async depart(@Param('machineId') machineId: string) {
    return this.transportService.markDeparture(machineId);
  }

  @Post('deliver/:machineId')
  @ApiOperation({
    summary: 'Registrar entrega final en destino',
    description: 'Cambia el estado del viaje a entregado y de la máquina a entregada.',
  })
  @ApiParam({ name: 'machineId', description: 'UUID o identificador de la máquina' })
  async deliver(@Param('machineId') machineId: string) {
    return this.transportService.markDelivered(machineId);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Actualizar detalles de ruta o datos del viaje (destino, vehículo, conductor, estado)' })
  @ApiParam({ name: 'id', description: 'ID del viaje de transporte' })
  async updateTrip(
    @Param('id') id: string,
    @Body() dto: { destination?: string; vehicle?: string; transporterId?: string; status?: any },
  ) {
    return this.transportService.updateTrip(id, dto);
  }

  @Get('active')
  @ApiOperation({ summary: 'Listar todos los viajes de transporte en curso o activos' })
  async getActive() {
    return this.transportService.getActiveTrips();
  }

  @Get('my-trips')
  @ApiOperation({ summary: 'Listar viajes asignados al transportador autenticado' })
  async getMyTrips(@Request() req: any) {
    const userId = req.user?.sub || req.user?.id;
    return this.transportService.getTransporterTrips(userId);
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
}
