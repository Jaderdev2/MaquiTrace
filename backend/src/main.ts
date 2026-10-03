import 'dotenv/config';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Prefijo global de API
  app.setGlobalPrefix('api/v1');

  // Habilitar CORS para Web y Mobile
  app.enableCors({
    origin: '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });

  // Validaciones automáticas de DTOs
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  // Configuración de Swagger / OpenAPI
  const swaggerConfig = new DocumentBuilder()
    .setTitle('MaquiTrace API')
    .setDescription(
      'API REST para la plataforma MaquiTrace - Trazabilidad, supervisión y despacho de maquinaria pesada.',
    )
    .setVersion('1.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        name: 'Authorization',
        description: 'Ingresa tu token JWT para autenticarte',
        in: 'header',
      },
      'JWT-auth',
    )
    .addTag('Auth', 'Autenticación e inicio de sesión')
    .addTag('Users', 'Gestión de usuarios y roles')
    .addTag('Machines', 'Inventario y estados de maquinaria')
    .addTag('Preparation Phases', 'Fases de alistamiento (Limpieza, Mecánica, Pruebas)')
    .addTag('Evidence', 'Registro y consulta de evidencias fotográficas y en video')
    .addTag('Transport', 'Despacho, recepción y entrega de maquinaria')
    .addTag('Tracking', 'Tracking y registros GPS en tiempo real')
    .addTag('Incidents', 'Reporte y resolución de novedades en ruta')
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/docs', app, document, {
    swaggerOptions: {
      persistAuthorization: true,
    },
  });

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`[Server] MaquiTrace Backend API escuchando en: http://localhost:${port}/api/v1`);
  console.log(`[Swagger] Documentación interactiva disponible en: http://localhost:${port}/api/docs`);
}

bootstrap();
