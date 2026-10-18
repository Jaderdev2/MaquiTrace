import { Injectable, Logger } from '@nestjs/common';
import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import * as path from 'path';
import * as crypto from 'crypto';

import { UploadedFileDto } from './evidence.types';

@Injectable()
export class OciStorageService {
  private readonly logger = new Logger(OciStorageService.name);
  private readonly s3Client: S3Client | null = null;
  private readonly bucketName: string;
  private readonly bucketPublicUrl: string;

  constructor() {
    this.bucketName = process.env.OCI_BUCKET_NAME || 'maquitrace-evidencias';
    this.bucketPublicUrl =
      process.env.OCI_BUCKET_PUBLIC_URL ||
      `https://objectstorage.${process.env.OCI_S3_REGION || 'sa-bogota-1'}.oraclecloud.com/n/${process.env.OCI_NAMESPACE || 'axtyteuui5m6'}/b/${this.bucketName}/o`;

    const endpoint = process.env.OCI_S3_ENDPOINT;
    const region = process.env.OCI_S3_REGION || 'sa-bogota-1';
    const accessKeyId = process.env.OCI_S3_ACCESS_KEY_ID;
    const secretAccessKey = process.env.OCI_S3_SECRET_ACCESS_KEY;

    if (endpoint && accessKeyId && secretAccessKey) {
      this.s3Client = new S3Client({
        region,
        endpoint,
        credentials: {
          accessKeyId,
          secretAccessKey,
        },
        forcePathStyle: true,
      });
      this.logger.log(`[OCI] Cliente S3 inicializado para el bucket: ${this.bucketName}`);
    } else {
      this.logger.warn(
        '[OCI] Credenciales OCI no configuradas completamente en .env. Se usará modo fallback.',
      );
    }
  }

  /**
   * Sube un archivo a Oracle Cloud Object Storage y retorna la clave y URL accesible
   */
  async uploadFile(
    file: UploadedFileDto,
    folder: string = 'evidencias',
  ): Promise<{ key: string; url: string }> {
    const ext = path.extname(file.originalname).toLowerCase() || '.jpg';
    const randomHex = crypto.randomBytes(6).toString('hex');
    const safeBaseName = path
      .basename(file.originalname, ext)
      .replace(/[^a-zA-Z0-9_-]/g, '_');
    const key = `${folder}/${Date.now()}_${randomHex}_${safeBaseName}${ext}`;

    if (!this.s3Client) {
      this.logger.warn(`[Fallback] OCI S3 inactivo, retornando URL simulada para: ${key}`);
      return {
        key,
        url: `https://fake-storage.maquitrace.com/${key}`,
      };
    }

    try {
      await this.s3Client.send(
        new PutObjectCommand({
          Bucket: this.bucketName,
          Key: key,
          Body: file.buffer,
          ContentType: file.mimetype || 'image/jpeg',
        }),
      );

      // Generar URL firmada con vigencia de 7 días (604800 segundos)
      const presignedUrl = await getSignedUrl(
        this.s3Client,
        new GetObjectCommand({
          Bucket: this.bucketName,
          Key: key,
        }),
        { expiresIn: 604800 },
      );

      this.logger.log(`[OCI] Archivo subido exitosamente a: ${key}`);

      return {
        key,
        url: presignedUrl,
      };
    } catch (error: any) {
      this.logger.error(`[OCI] Error al subir archivo ${key}: ${error.message}`);
      throw error;
    }
  }

  /**
   * Genera una nueva URL firmada temporal para acceder a un objeto privado
   */
  async getPresignedUrl(key: string, expiresInSeconds: number = 604800): Promise<string> {
    if (!this.s3Client) {
      return `https://fake-storage.maquitrace.com/${key}`;
    }

    try {
      return await getSignedUrl(
        this.s3Client,
        new GetObjectCommand({
          Bucket: this.bucketName,
          Key: key,
        }),
        { expiresIn: expiresInSeconds },
      );
    } catch (error: any) {
      this.logger.error(`[OCI] Error generando URL firmada para ${key}: ${error.message}`);
      return `${this.bucketPublicUrl}/${key}`;
    }
  }

  /**
   * Verifica y regenera automáticamente una URL firmada si tiene más de 3 días de emitida
   * evitando que imágenes en web y móvil den 403 por vencimiento.
   */
  async ensureFreshUrl(url: string | null | undefined): Promise<string | null> {
    if (!url) return null;
    const match = url.match(/maquitrace-evidencias\/([^?]+)/);
    if (!match || !this.s3Client) {
      return url;
    }
    const key = decodeURIComponent(match[1]);

    const dateMatch = url.match(/X-Amz-Date=(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z/);
    if (dateMatch) {
      const year = parseInt(dateMatch[1], 10);
      const month = parseInt(dateMatch[2], 10) - 1;
      const day = parseInt(dateMatch[3], 10);
      const hour = parseInt(dateMatch[4], 10);
      const min = parseInt(dateMatch[5], 10);
      const sec = parseInt(dateMatch[6], 10);
      const signedAt = Date.UTC(year, month, day, hour, min, sec);
      const ageMs = Date.now() - signedAt;
      // Si fue firmada hace menos de 3 días (259200000 ms), sigue fresca y vigente
      if (ageMs < 259200000 && ageMs >= 0) {
        return url;
      }
    }

    try {
      return await getSignedUrl(
        this.s3Client,
        new GetObjectCommand({
          Bucket: this.bucketName,
          Key: key,
        }),
        { expiresIn: 604800 },
      );
    } catch {
      return url;
    }
  }
}
