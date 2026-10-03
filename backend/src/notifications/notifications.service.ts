import { Injectable, Logger } from '@nestjs/common';

export interface EmailNotificationDto {
  to: string;
  subject: string;
  htmlContent: string;
}

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  // Envío de correo transaccional (ej: con Nodemailer configurado con SMTP)
  async sendEmail(dto: EmailNotificationDto) {
    this.logger.log(`Enviando notificación por correo a ${dto.to}: ${dto.subject}`);
    // Aquí se conecta con el transportador SMTP de Nodemailer configurado en las variables de entorno
    return {
      success: true,
      recipient: dto.to,
      subject: dto.subject,
      timestamp: new Date(),
    };
  }

  // Notificación de inicio/fin de alistamiento de maquinaria
  async notifyPreparationStatusChange(machineSerial: string, phaseName: string, status: string, notifyEmails: string[]) {
    const subject = `[MaquiTrace] Actualización de alistamiento: Máquina ${machineSerial}`;
    const htmlContent = `
      <h2>Notificación de Alistamiento</h2>
      <p>La máquina con serial <strong>${machineSerial}</strong> ha actualizado la fase <strong>${phaseName}</strong> a estado <strong>${status}</strong>.</p>
    `;

    for (const email of notifyEmails) {
      await this.sendEmail({ to: email, subject, htmlContent });
    }
  }

  // Notificación de novedad/incidencia registrada en transporte
  async notifyIncidentAlert(tripId: string, description: string, notifyEmails: string[]) {
    const subject = `[ALERTA MaquiTrace] Novedad en ruta - Viaje ${tripId}`;
    const htmlContent = `
      <h2 style="color: #DC2626;">Incidencia reportada en ruta</h2>
      <p>Se ha registrado una novedad para el viaje de transporte ID: <strong>${tripId}</strong>.</p>
      <p><strong>Detalle:</strong> ${description}</p>
    `;

    for (const email of notifyEmails) {
      await this.sendEmail({ to: email, subject, htmlContent });
    }
  }
}
