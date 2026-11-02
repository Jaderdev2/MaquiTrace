import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Request,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { RecordGpsDto, TrackingService } from './tracking.service';
import { TrackingGateway } from './tracking.gateway';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { Roles, RolesGuard } from '../auth/guards/roles.guard';

@ApiTags('Tracking')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('administrador')
@Controller('tracking')
export class TrackingController {
  constructor(
    private readonly trackingService: TrackingService,
    private readonly trackingGateway: TrackingGateway,
  ) {}

  @Post(':tripId/location')
  @Roles('transportador')
  async recordLocation(
    @Param('tripId') tripId: string,
    @Body() dto: RecordGpsDto,
    @Request() req: any,
  ) {
    const record = await this.trackingService.recordPosition(
      tripId,
      dto,
      this.getAuthenticatedUserId(req),
    );
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

  private getAuthenticatedUserId(req: any): string {
    const userId = req.user?.sub || req.user?.id;
    if (!userId) throw new UnauthorizedException('No se pudo identificar al usuario autenticado');
    return userId;
  }
}
