import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { RecordGpsDto, TrackingService } from './tracking.service';
import { TrackingGateway } from './tracking.gateway';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('Tracking')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller('tracking')
export class TrackingController {
  constructor(
    private readonly trackingService: TrackingService,
    private readonly trackingGateway: TrackingGateway,
  ) {}

  @Post(':tripId/location')
  async recordLocation(
    @Param('tripId') tripId: string,
    @Body() dto: RecordGpsDto,
  ) {
    const record = await this.trackingService.recordPosition(tripId, dto);
    // Emite el evento location:update por WebSocket en tiempo real
    this.trackingGateway.broadcastLocationUpdate(tripId, record);
    return record;
  }

  @Get('active')
  async getActive() {
    return this.trackingService.getActiveMachinesInTransit();
  }

  @Get(':tripId/history')
  async getHistory(@Param('tripId') tripId: string) {
    return this.trackingService.getTripHistory(tripId);
  }
}
