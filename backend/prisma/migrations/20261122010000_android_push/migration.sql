ALTER TABLE "notificaciones" ADD COLUMN "pushProcessedAt" TIMESTAMP(3), ADD COLUMN "pushClaimedAt" TIMESTAMP(3);
UPDATE "notificaciones" SET "pushProcessedAt" = CURRENT_TIMESTAMP;
CREATE TABLE "dispositivos_push" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "token" TEXT NOT NULL,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "dispositivos_push_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "dispositivos_push_token_key" ON "dispositivos_push"("token");
CREATE INDEX "dispositivos_push_userId_idx" ON "dispositivos_push"("userId");
ALTER TABLE "dispositivos_push" ADD CONSTRAINT "dispositivos_push_userId_fkey" FOREIGN KEY ("userId") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;
