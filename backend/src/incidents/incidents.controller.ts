import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Request,
  UnauthorizedException,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { ApiBearerAuth, ApiConsumes, ApiOperation, ApiTags } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { IncidentsService, ReportIncidentDto } from './incidents.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { Roles, RolesGuard } from '../auth/guards/roles.guard';
import { UploadedFileDto } from '../evidence/evidence.types';

@ApiTags('Incidents')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('administrador')
@Controller('transport/:tripId/incidents')
export class IncidentsController {
  constructor(private readonly incidentsService: IncidentsService) {}

  @Post()
  @Roles('transportador')
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
    @Request() req?: any,
  ) {
    return this.incidentsService.reportIncident(
      tripId,
      dto,
      this.getAuthenticatedUserId(req),
      file,
    );
  }

  @Get()
  @ApiOperation({ summary: 'Consultar incidencias de un viaje' })
  async getByTrip(@Param('tripId') tripId: string) {
    return this.incidentsService.findByTrip(tripId);
  }

  private getAuthenticatedUserId(req: any): string {
    const userId = req.user?.sub || req.user?.id;
    if (!userId) throw new UnauthorizedException('No se pudo identificar al usuario autenticado');
    return userId;
  }
}
