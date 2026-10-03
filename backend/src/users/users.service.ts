import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export interface CreateUserDto {
  email: string;
  name: string;
  passwordHash: string;
  roleId: string;
  phone?: string;
}

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(roleName?: string) {
    return this.prisma.user.findMany({
      where: roleName ? { role: { name: roleName } } : undefined,
      include: { role: true },
      orderBy: { name: 'asc' },
    });
  }

  async findById(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: { role: true },
    });
    if (!user) throw new NotFoundException(`Usuario con ID ${id} no encontrado`);
    return user;
  }

  async create(dto: CreateUserDto) {
    return this.prisma.user.create({
      data: {
        email: dto.email,
        name: dto.name,
        passwordHash: dto.passwordHash,
        roleId: dto.roleId,
        phone: dto.phone,
      },
      include: { role: true },
    });
  }

  async findByRole(roleName: string) {
    return this.prisma.user.findMany({
      where: { role: { name: roleName } },
      include: { role: true },
    });
  }
}
