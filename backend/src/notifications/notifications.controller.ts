import {
  Controller,
  Get,
  Param,
  Patch,
  Request,
  UseGuards,
} from "@nestjs/common";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { PrismaService } from "../prisma/prisma.service";

@Controller("notifications")
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async list(@Request() req: any) {
    const userId = req.user.sub;
    const [items, unreadCount] = await Promise.all([
      this.prisma.notification.findMany({
        where: { userId },
        orderBy: [{ createdAt: "desc" }, { id: "desc" }],
        take: 50,
      }),
      this.prisma.notification.count({ where: { userId, readAt: null } }),
    ]);
    return { items, unreadCount };
  }

  @Patch("read-all")
  async readAll(@Request() req: any) {
    await this.prisma.notification.updateMany({
      where: { userId: req.user.sub, readAt: null },
      data: { readAt: new Date() },
    });
    return { success: true };
  }

  @Patch(":id/read")
  async read(@Request() req: any, @Param("id") id: string) {
    const result = await this.prisma.notification.updateMany({
      where: { id, userId: req.user.sub, readAt: null },
      data: { readAt: new Date() },
    });
    return { updated: result.count > 0 };
  }
}
