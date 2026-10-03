import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CreatePhaseDto, PreparationPhasesService, UpdatePhaseDto } from './preparation-phases.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('Preparation Phases')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller('machines/:machineId/phases')
export class PreparationPhasesController {
  constructor(private readonly phasesService: PreparationPhasesService) {}

  @Get()
  async getPhases(@Param('machineId') machineId: string) {
    return this.phasesService.findByMachine(machineId);
  }

  @Post()
  async createPhase(
    @Param('machineId') machineId: string,
    @Body() dto: Omit<CreatePhaseDto, 'machineId'>,
  ) {
    return this.phasesService.createPhase({ ...dto, machineId });
  }

  @Patch(':phaseId')
  async updatePhase(
    @Param('phaseId') phaseId: string,
    @Body() dto: UpdatePhaseDto,
  ) {
    return this.phasesService.updatePhaseStatus(phaseId, dto);
  }
}
