import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ReceiveTransportDto, TransportService } from './transport.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('transport')
export class TransportController {
  constructor(private readonly transportService: TransportService) {}

  @Post('receive/:machineId')
  async receive(
    @Param('machineId') machineId: string,
    @Body() dto: ReceiveTransportDto,
  ) {
    return this.transportService.receiveMachine(machineId, dto);
  }

  @Post('depart/:machineId')
  async depart(@Param('machineId') machineId: string) {
    return this.transportService.markDeparture(machineId);
  }

  @Post('deliver/:machineId')
  async deliver(@Param('machineId') machineId: string) {
    return this.transportService.markDelivered(machineId);
  }

  @Get('active')
  async getActive() {
    return this.transportService.getActiveTrips();
  }

  @Get(':id')
  async getById(@Param('id') id: string) {
    return this.transportService.getTripById(id);
  }
}
