import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  Post,
  Request,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiOperation,
  ApiParam,
  ApiTags,
} from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { EvidenceService, RegisterEvidenceDto } from './evidence.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { EvidenceType } from '@prisma/client';
import { UploadedFileDto } from './evidence.types';

@ApiTags('Evidence')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller()
export class EvidenceController {
  constructor(private readonly evidenceService: EvidenceService) {}

  /**
   * Subida de evidencia multimedia (foto/video) hacia Oracle Cloud Object Storage
   */
  @Post('machines/:machineId/evidence')
  @ApiOperation({
    summary: 'Subir archivo de evidencia fotográfica o video',
    description:
      'Recibe un archivo multimedia (hasta 25 MB), lo sube al bucket OCI y lo asocia a la máquina, fase y operario.',
  })
  @ApiParam({ name: 'machineId', description: 'ID o UUID de la máquina' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['file'],
      properties: {
        file: {
          type: 'string',
          format: 'binary',
          description: 'Archivo de imagen o video capturado en el dispositivo',
        },
        phaseId: {
          type: 'string',
          description: 'ID de la fase de alistamiento asociada (opcional)',
        },
        type: {
          type: 'string',
          enum: ['foto', 'video'],
          description: 'Tipo de evidencia (opcional, detectado por mimetype)',
        },
        observations: {
          type: 'string',
          description: 'Observaciones o notas del operario',
        },
      },
    },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      limits: {
        fileSize: 25 * 1024 * 1024, // 25 MB máximo
      },
      fileFilter: (req, file, callback) => {
        if (!file.mimetype.match(/\/(jpg|jpeg|png|webp|mp4|mov|quicktime|octet-stream)$/i)) {
          return callback(
            new BadRequestException(
              'Tipo de archivo no permitido. Solo se admiten imágenes (JPG, PNG, WEBP) o videos (MP4, MOV).',
            ),
            false,
          );
        }
        callback(null, true);
      },
    }),
  )
  async uploadForMachine(
    @Param('machineId') machineId: string,
    @UploadedFile() file: UploadedFileDto,
    @Body() body: { phaseId?: string; type?: EvidenceType; observations?: string },
    @Request() req: any,
  ) {
    if (!file) {
      throw new BadRequestException('El campo "file" es obligatorio.');
    }
    const userId = req.user?.sub || req.user?.id;
    return this.evidenceService.uploadEvidence(machineId, file, body, userId);
  }

  /**
   * Consulta de todas las evidencias registradas para una máquina
   */
  @Get('machines/:machineId/evidence')
  @ApiOperation({ summary: 'Obtener todas las evidencias de una máquina' })
  @ApiParam({ name: 'machineId', description: 'ID de la máquina' })
  async getForMachine(@Param('machineId') machineId: string) {
    return this.evidenceService.findByMachine(machineId);
  }

  /**
   * Consulta de evidencias por fase específica
   */
  @Get('machines/:machineId/phases/:phaseId/evidence')
  @ApiOperation({ summary: 'Obtener evidencias de una fase específica' })
  async getForPhase(
    @Param('machineId') _machineId: string,
    @Param('phaseId') phaseId: string,
  ) {
    return this.evidenceService.findByPhase(phaseId);
  }

  /**
   * Registro con URL directa (compatibilidad)
   */
  @Post('evidence')
  @ApiOperation({ summary: 'Registrar evidencia mediante URL previa' })
  async createGeneral(@Body() dto: RegisterEvidenceDto, @Request() req: any) {
    const userId = dto.uploadedBy || req.user?.sub || req.user?.id;
    return this.evidenceService.create({ ...dto, uploadedBy: userId });
  }
}
