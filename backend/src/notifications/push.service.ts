import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from "@nestjs/common";
import { cert, getApps, initializeApp } from "firebase-admin/app";
import { getMessaging } from "firebase-admin/messaging";
import { PrismaService } from "../prisma/prisma.service";

@Injectable()
export class PushService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PushService.name);
  private timer?: NodeJS.Timeout;
  private running = false;
  private enabled = false;
  constructor(private readonly prisma: PrismaService) {}

  onModuleInit() {
    const credentials = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    if (!credentials) {
      this.logger.warn("Firebase push desactivado: faltan credenciales.");
      return;
    }
    try {
      if (!getApps().length)
        initializeApp({ credential: cert(JSON.parse(credentials)) });
      this.enabled = true;
      this.timer = setInterval(() => void this.process(), 10000);
      void this.process();
    } catch (error) {
      this.logger.error("No se pudo inicializar Firebase Admin", error);
    }
  }
  onModuleDestroy() {
    if (this.timer) clearInterval(this.timer);
  }

  async process() {
    if (!this.enabled || this.running) return;
    this.running = true;
    try {
      const expired = new Date(Date.now() - 120000);
      const pending = await this.prisma.notification.findMany({
        where: {
          pushProcessedAt: null,
          OR: [{ pushClaimedAt: null }, { pushClaimedAt: { lt: expired } }],
        },
        orderBy: { createdAt: "asc" },
        take: 50,
      });
      for (const notice of pending) {
        const now = new Date();
        const claim = await this.prisma.notification.updateMany({
          where: {
            id: notice.id,
            pushProcessedAt: null,
            OR: [{ pushClaimedAt: null }, { pushClaimedAt: { lt: expired } }],
          },
          data: { pushClaimedAt: now },
        });
        if (!claim.count) continue;
        try {
          const devices = await this.prisma.pushDevice.findMany({
            where: { userId: notice.userId },
          });
          let retry = false;
          for (let i = 0; i < devices.length; i += 500) {
            const batch = devices.slice(i, i + 500);
            const result = await getMessaging().sendEachForMulticast({
              tokens: batch.map((d) => d.token),
              notification: {
                title: "MaquiTrace",
                body: "Tienes una nueva notificacion. Abre la aplicacion para verla.",
              },
              data: { notificationId: notice.id },
              android: { priority: "high" },
            });
            for (let j = 0; j < result.responses.length; j++) {
              const response = result.responses[j];
              if (response.success) continue;
              const code = response.error?.code;
              if (
                code === "messaging/registration-token-not-registered" ||
                code === "messaging/invalid-registration-token"
              ) {
                await this.prisma.pushDevice.deleteMany({
                  where: { id: batch[j].id, token: batch[j].token },
                });
              } else {
                retry = true;
              }
            }
          }
          if (retry)
            throw new Error("Firebase no pudo entregar todos los mensajes");
          await this.prisma.notification.updateMany({
            where: { id: notice.id, pushClaimedAt: now },
            data: { pushProcessedAt: new Date(), pushClaimedAt: null },
          });
        } catch (error) {
          this.logger.warn(
            `No se pudo enviar el aviso ${notice.id}; se reintentara.`,
          );
          await this.prisma.notification.updateMany({
            where: { id: notice.id, pushClaimedAt: now },
            data: { pushClaimedAt: null },
          });
        }
      }
    } catch (error) {
      this.logger.error("Error procesando avisos push", error);
    } finally {
      this.running = false;
    }
  }
}
