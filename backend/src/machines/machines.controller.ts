import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CreateMachineDto, MachinesService, UpdateMachineDto } from './machines.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { MachineStatus } from '@prisma/client';

@ApiTags('Machines')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller('machines')
export class MachinesController {
  constructor(private readonly machinesService: MachinesService) {}

  @Get()
  async getAll(
    @Query('category') category?: string,
    @Query('status') status?: MachineStatus,
    @Query('serial') serial?: string,
  ) {
    return this.machinesService.findAll(category, status, serial);
  }

  @Post()
  async create(@Body() dto: CreateMachineDto) {
    return this.machinesService.create(dto);
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() dto: UpdateMachineDto) {
    return this.machinesService.update(id, dto);
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    return this.machinesService.remove(id);
  }

  @Get(':id')
  async getById(@Param('id') id: string) {
    return this.machinesService.findById(id);
  }

  @Get('by-serial/:serial')
  async getBySerial(@Param('serial') serial: string) {
    return this.machinesService.findBySerial(serial);
  }

  @Get(':id/history')
  async getHistory(@Param('id') id: string) {
    return this.machinesService.getHistory(id);
  }
}
