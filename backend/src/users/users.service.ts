import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as bcrypt from 'bcrypt';

export interface CreateUserDto {
  email: string;
  name: string;
  password?: string;
  passwordHash?: string;
  roleId: string;
  phone?: string;
}

export interface UpdateUserDto {
  email?: string;
  name?: string;
  password?: string;
  roleId?: string;
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
    const passwordHash = dto.passwordHash || (dto.password ? await bcrypt.hash(dto.password, 10) : await bcrypt.hash('MaquiTrace2026!', 10));

    return this.prisma.user.create({
      data: {
        email: dto.email,
        name: dto.name,
        passwordHash,
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

  async update(id: string, dto: UpdateUserDto) {
    await this.findById(id);

    let passwordHash: string | undefined = undefined;
    if (dto.password) {
      passwordHash = await bcrypt.hash(dto.password, 10);
    }

    return this.prisma.user.update({
      where: { id },
      data: {
        ...(dto.name !== undefined ? { name: dto.name } : {}),
        ...(dto.email !== undefined ? { email: dto.email } : {}),
        ...(dto.phone !== undefined ? { phone: dto.phone } : {}),
        ...(dto.roleId !== undefined ? { roleId: dto.roleId } : {}),
        ...(passwordHash ? { passwordHash } : {}),
      },
      include: { role: true },
    });
  }

  async findRoles() {
    return this.prisma.role.findMany({
      orderBy: { name: 'asc' },
    });
  }

  async remove(id: string) {
    await this.findById(id);
    return this.prisma.user.delete({
      where: { id },
    });
  }
}

