import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { IncidentsService, ReportIncidentDto } from './incidents.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('Incidents')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller('transport/:tripId/incidents')
export class IncidentsController {
  constructor(private readonly incidentsService: IncidentsService) {}

  @Post()
  async create(
    @Param('tripId') tripId: string,
    @Body() dto: ReportIncidentDto,
  ) {
    return this.incidentsService.reportIncident(tripId, dto);
  }

  @Get()
  async getByTrip(@Param('tripId') tripId: string) {
    return this.incidentsService.findByTrip(tripId);
  }
}
