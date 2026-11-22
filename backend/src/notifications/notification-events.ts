import { Prisma } from "@prisma/client";

type Notice = {
  type: string;
  title: string;
  message: string;
  machineId?: string;
  tripId?: string;
};
export async function notifyAdmins(
  tx: Prisma.TransactionClient,
  notice: Notice,
) {
  const users = await tx.user.findMany({
    where: { role: { name: "administrador" } },
    select: { id: true },
  });
  if (users.length)
    await tx.notification.createMany({
      data: users.map(({ id }) => ({ userId: id, ...notice })),
    });
}
