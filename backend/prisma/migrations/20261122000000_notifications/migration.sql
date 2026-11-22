CREATE TABLE "notificaciones" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "type" TEXT NOT NULL,
  "title" TEXT NOT NULL,
  "message" TEXT NOT NULL,
  "machineId" TEXT,
  "tripId" TEXT,
  "readAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "notificaciones_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "notificaciones_userId_createdAt_idx" ON "notificaciones"("userId", "createdAt");
CREATE INDEX "notificaciones_userId_readAt_idx" ON "notificaciones"("userId", "readAt");
ALTER TABLE "notificaciones" ADD CONSTRAINT "notificaciones_userId_fkey" FOREIGN KEY ("userId") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;
