import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CreateUserDto, UpdateUserDto, UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('Users')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  @ApiOperation({ summary: 'Obtener lista de usuarios' })
  async getAll(@Query('role') role?: string) {
    return this.usersService.findAll(role);
  }

  @Post()
  @ApiOperation({ summary: 'Crear un nuevo usuario' })
  async create(@Body() dto: CreateUserDto) {
    return this.usersService.create(dto);
  }

  @Get('operators')
  @ApiOperation({ summary: 'Obtener operarios' })
  async getOperators() {
    return this.usersService.findByRole('operario');
  }

  @Get('transporters')
  @ApiOperation({ summary: 'Obtener transportadores' })
  async getTransporters() {
    return this.usersService.findByRole('transportador');
  }

  @Get(':id')
  @ApiOperation({ summary: 'Obtener usuario por ID' })
  async getById(@Param('id') id: string) {
    return this.usersService.findById(id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Actualizar datos de un usuario por ID' })
  async update(@Param('id') id: string, @Body() dto: UpdateUserDto) {
    return this.usersService.update(id, dto);
  }
}

