import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { ApiBearerAuth, ApiConsumes, ApiOperation, ApiTags } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { IncidentsService, ReportIncidentDto } from './incidents.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UploadedFileDto } from '../evidence/evidence.types';

@ApiTags('Incidents')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller('transport/:tripId/incidents')
export class IncidentsController {
  constructor(private readonly incidentsService: IncidentsService) {}

  @Post()
  @UseInterceptors(FileInterceptor('file'))
  @ApiOperation({
    summary: 'Reportar incidencia en carretera',
    description: 'Permite registrar un incidente con descripción y adjuntar foto directamente a Oracle Cloud.',
  })
  @ApiConsumes('multipart/form-data', 'application/json')
  async create(
    @Param('tripId') tripId: string,
    @Body() dto: ReportIncidentDto,
    @UploadedFile() file?: UploadedFileDto,
  ) {
    return this.incidentsService.reportIncident(tripId, dto, file);
  }

  @Get()
  @ApiOperation({ summary: 'Consultar incidencias de un viaje' })
  async getByTrip(@Param('tripId') tripId: string) {
    return this.incidentsService.findByTrip(tripId);
  }
}
