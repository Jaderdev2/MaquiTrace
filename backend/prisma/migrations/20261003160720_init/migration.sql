-- CreateEnum
CREATE TYPE "MachineStatus" AS ENUM ('pendiente', 'en_proceso', 'completada', 'en_transito', 'entregada');

-- CreateEnum
CREATE TYPE "PhaseName" AS ENUM ('ensamblaje', 'pintura', 'lavado');

-- CreateEnum
CREATE TYPE "PhaseStatus" AS ENUM ('pendiente', 'en_proceso', 'completada');

-- CreateEnum
CREATE TYPE "EvidenceType" AS ENUM ('foto', 'video');

-- CreateEnum
CREATE TYPE "TripStatus" AS ENUM ('pendiente', 'en_transito', 'entregado');

-- CreateTable
CREATE TABLE "usuarios" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "phone" TEXT,
    "roleId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "usuarios_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "roles" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "roles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "maquinarias" (
    "id" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "serial" TEXT NOT NULL,
    "model" TEXT NOT NULL,
    "status" "MachineStatus" NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "maquinarias_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "fases_alistamiento" (
    "id" TEXT NOT NULL,
    "machineId" TEXT NOT NULL,
    "name" "PhaseName" NOT NULL,
    "status" "PhaseStatus" NOT NULL,
    "observations" TEXT,
    "operatorId" TEXT NOT NULL,
    "startedAt" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),

    CONSTRAINT "fases_alistamiento_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "evidencias" (
    "id" TEXT NOT NULL,
    "machineId" TEXT NOT NULL,
    "phaseId" TEXT,
    "type" "EvidenceType" NOT NULL,
    "url" TEXT NOT NULL,
    "uploadedBy" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "evidencias_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "viajes_transporte" (
    "id" TEXT NOT NULL,
    "machineId" TEXT NOT NULL,
    "transporterId" TEXT NOT NULL,
    "vehicle" TEXT NOT NULL,
    "destination" TEXT NOT NULL,
    "status" "TripStatus" NOT NULL,
    "departureAt" TIMESTAMP(3),
    "arrivalAt" TIMESTAMP(3),

    CONSTRAINT "viajes_transporte_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "registros_gps" (
    "id" TEXT NOT NULL,
    "tripId" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "recordedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "registros_gps_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "incidencias" (
    "id" TEXT NOT NULL,
    "tripId" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "photoUrl" TEXT,
    "reportedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "incidencias_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "usuarios_email_key" ON "usuarios"("email");

-- CreateIndex
CREATE UNIQUE INDEX "roles_name_key" ON "roles"("name");

-- CreateIndex
CREATE UNIQUE INDEX "maquinarias_serial_key" ON "maquinarias"("serial");

-- AddForeignKey
ALTER TABLE "usuarios" ADD CONSTRAINT "usuarios_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES "roles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fases_alistamiento" ADD CONSTRAINT "fases_alistamiento_machineId_fkey" FOREIGN KEY ("machineId") REFERENCES "maquinarias"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fases_alistamiento" ADD CONSTRAINT "fases_alistamiento_operatorId_fkey" FOREIGN KEY ("operatorId") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "evidencias" ADD CONSTRAINT "evidencias_machineId_fkey" FOREIGN KEY ("machineId") REFERENCES "maquinarias"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "evidencias" ADD CONSTRAINT "evidencias_phaseId_fkey" FOREIGN KEY ("phaseId") REFERENCES "fases_alistamiento"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "evidencias" ADD CONSTRAINT "evidencias_uploadedBy_fkey" FOREIGN KEY ("uploadedBy") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "viajes_transporte" ADD CONSTRAINT "viajes_transporte_machineId_fkey" FOREIGN KEY ("machineId") REFERENCES "maquinarias"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "viajes_transporte" ADD CONSTRAINT "viajes_transporte_transporterId_fkey" FOREIGN KEY ("transporterId") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "registros_gps" ADD CONSTRAINT "registros_gps_tripId_fkey" FOREIGN KEY ("tripId") REFERENCES "viajes_transporte"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "incidencias" ADD CONSTRAINT "incidencias_tripId_fkey" FOREIGN KEY ("tripId") REFERENCES "viajes_transporte"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
