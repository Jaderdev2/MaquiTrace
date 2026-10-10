import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiOperation, ApiTags } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { CreateMachineDto, MachinesService, UpdateMachineDto } from './machines.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { MachineStatus } from '@prisma/client';
import { UploadedFileDto } from '../evidence/evidence.types';

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

  @Post(':id/avatar')
  @UseInterceptors(FileInterceptor('file'))
  @ApiOperation({
    summary: 'Subir avatar / foto de perfil del equipo a Oracle Cloud',
    description:
      'Sube la imagen a OCI y actualiza el campo imageUrl de la máquina sin generar registros en la tabla Evidence.',
  })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['file'],
      properties: {
        file: {
          type: 'string',
          format: 'binary',
          description: 'Foto de perfil o avatar de la máquina',
        },
      },
    },
  })
  async uploadAvatar(
    @Param('id') id: string,
    @UploadedFile() file: UploadedFileDto,
  ) {
    return this.machinesService.updateAvatar(id, file);
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
