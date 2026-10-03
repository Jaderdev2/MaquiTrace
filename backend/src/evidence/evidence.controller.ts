import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { EvidenceService, RegisterEvidenceDto } from './evidence.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('Evidence')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller()
export class EvidenceController {
  constructor(private readonly evidenceService: EvidenceService) {}

  @Post('machines/:machineId/evidence')
  async uploadForMachine(
    @Param('machineId') machineId: string,
    @Body() dto: Omit<RegisterEvidenceDto, 'machineId'>,
  ) {
    return this.evidenceService.create({ ...dto, machineId });
  }

  @Get('machines/:machineId/evidence')
  async getForMachine(@Param('machineId') machineId: string) {
    return this.evidenceService.findByMachine(machineId);
  }

  @Post('evidence')
  async createGeneral(@Body() dto: RegisterEvidenceDto) {
    return this.evidenceService.create(dto);
  }
}
