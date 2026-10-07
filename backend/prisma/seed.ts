import { PrismaClient, MachineStatus, PhaseName, PhaseStatus } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('[Seed] Iniciando sembrado de base de datos MaquiTrace...');

  // 1. Roles del sistema (los 3 roles oficiales)
  console.log('[Seed] Registrando roles...');
  const roleAdmin = await prisma.role.upsert({
    where: { name: 'administrador' },
    update: {},
    create: { name: 'administrador' },
  });

  const roleOperario = await prisma.role.upsert({
    where: { name: 'operario' },
    update: {},
    create: { name: 'operario' },
  });

  const roleTransportador = await prisma.role.upsert({
    where: { name: 'transportador' },
    update: {},
    create: { name: 'transportador' },
  });

  console.log(`[Seed] Roles creados: ${roleAdmin.name}, ${roleOperario.name}, ${roleTransportador.name}`);

  // 2. Hash de contraseñas de prueba
  const saltRounds = 10;
  const adminPasswordHash = await bcrypt.hash('Admin1234!', saltRounds);
  const operarioPasswordHash = await bcrypt.hash('Operario1234!', saltRounds);
  const transportadorPasswordHash = await bcrypt.hash('Transporte1234!', saltRounds);

  // 3. Usuarios iniciales (Admin, Operario 1: Itadori, Operario 2: Charly, Transportador)
  console.log('[Seed] Registrando usuarios iniciales...');

  // Actualizar usuario previo con nombre real si existía
  await prisma.user.deleteMany({
    where: { name: { contains: 'Jhon' } },
  }).catch(() => {});

  const admin = await prisma.user.upsert({
    where: { email: 'admin@maquitrace.com' },
    update: { passwordHash: adminPasswordHash },
    create: {
      name: 'Supervisor General',
      email: 'admin@maquitrace.com',
      passwordHash: adminPasswordHash,
      phone: '+57 300 0000000',
      roleId: roleAdmin.id,
    },
  });

  // Operario 1: Yuji Itadori
  const operario1 = await prisma.user.upsert({
    where: { email: 'itadori@maquitrace.com' },
    update: {
      name: 'Yuji Itadori',
      passwordHash: operarioPasswordHash,
      roleId: roleOperario.id,
    },
    create: {
      name: 'Yuji Itadori',
      email: 'itadori@maquitrace.com',
      passwordHash: operarioPasswordHash,
      phone: '+57 310 8492001',
      roleId: roleOperario.id,
    },
  });

  // Operario 2: Charly Murillo
  const operario2 = await prisma.user.upsert({
    where: { email: 'charly@maquitrace.com' },
    update: {
      name: 'Charly Murillo',
      passwordHash: operarioPasswordHash,
      roleId: roleOperario.id,
    },
    create: {
      name: 'Charly Murillo',
      email: 'charly@maquitrace.com',
      passwordHash: operarioPasswordHash,
      phone: '+57 311 5556677',
      roleId: roleOperario.id,
    },
  });

  // Transportador
  const transportador = await prisma.user.upsert({
    where: { email: 'transportador@maquitrace.com' },
    update: { passwordHash: transportadorPasswordHash },
    create: {
      name: 'Carlos Transporte',
      email: 'transportador@maquitrace.com',
      passwordHash: transportadorPasswordHash,
      phone: '+57 320 9876543',
      roleId: roleTransportador.id,
    },
  });

  console.log('[Seed] Usuarios registrados exitosamente:');
  console.log('   - Administrador: admin@maquitrace.com / Admin1234!');
  console.log('   - Operario 1 (Itadori): itadori@maquitrace.com / Operario1234!');
  console.log('   - Operario 2 (Charly): charly@maquitrace.com / Operario1234!');
  console.log('   - Transportador: transportador@maquitrace.com / Transporte1234!');

  // 4. Maquinaria de prueba para las categorías oficiales
  console.log('[Seed] Registrando maquinaria de prueba...');

  const m1 = await prisma.machine.upsert({
    where: { serial: 'ABC123' },
    update: {},
    create: {
      serial: 'ABC123',
      model: 'CAT 320D',
      category: 'Excavadoras',
      status: MachineStatus.en_proceso,
    },
  });

  await prisma.machine.upsert({
    where: { serial: 'DEF789' },
    update: {},
    create: {
      serial: 'DEF789',
      model: 'CAT 950M',
      category: 'Cargadores frontales',
      status: MachineStatus.pendiente,
    },
  });

  await prisma.machine.upsert({
    where: { serial: 'GHI456' },
    update: {},
    create: {
      serial: 'GHI456',
      model: 'CAT 420F2',
      category: 'Retroexcavadoras',
      status: MachineStatus.completada,
    },
  });

  await prisma.machine.upsert({
    where: { serial: 'MOT552' },
    update: {},
    create: {
      serial: 'MOT552',
      model: 'CAT 140M3 AWD',
      category: 'Motoniveladoras',
      status: MachineStatus.en_proceso,
    },
  });

  await prisma.machine.upsert({
    where: { serial: 'VOL883' },
    update: {},
    create: {
      serial: 'VOL883',
      model: 'Volvo A40G Articulada',
      category: 'Volquetas',
      status: MachineStatus.pendiente,
    },
  });

  await prisma.machine.upsert({
    where: { serial: 'VOL104' },
    update: {},
    create: {
      serial: 'VOL104',
      model: 'CAT 745 Dumper',
      category: 'Volquetas',
      status: MachineStatus.completada,
    },
  });

  await prisma.machine.upsert({
    where: { serial: 'CRG701' },
    update: {},
    create: {
      serial: 'CRG701',
      model: 'Komatsu WA380-8',
      category: 'Cargadores frontales',
      status: MachineStatus.en_proceso,
    },
  });

  // 5. Fases de alistamiento de prueba para CAT 320D (ABC123)
  const existingPhases = await prisma.preparationPhase.count({
    where: { machineId: m1.id },
  });

  if (existingPhases === 0) {
    await prisma.preparationPhase.createMany({
      data: [
        {
          machineId: m1.id,
          name: PhaseName.ensamblaje,
          status: PhaseStatus.completada,
          observations: 'Acople de brazo hidráulico y ajuste de pasadores completado con torque certificado.',
          operatorId: operario2.id,
          startedAt: new Date(Date.now() - 3600000 * 4),
          completedAt: new Date(Date.now() - 3600000 * 2),
        },
        {
          machineId: m1.id,
          name: PhaseName.lavado,
          status: PhaseStatus.en_proceso,
          observations: 'Lavado a presión de chasis y orugas en progreso para remover grasa de montaje.',
          operatorId: operario1.id,
          startedAt: new Date(Date.now() - 3600000),
        },
        {
          machineId: m1.id,
          name: PhaseName.pintura,
          status: PhaseStatus.pendiente,
          observations: 'Pendiente inspección tras finalizar lavado.',
          operatorId: operario1.id,
        },
      ],
    });
    console.log('[Seed] Fases de alistamiento (Ensamblaje -> Lavado -> Pintura) registradas.');
  }

  console.log('[Seed] Sembrado completado exitosamente.');
}

main()
  .catch((e) => {
    console.error('[Seed] Error ejecutando seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
