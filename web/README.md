# MaquiTrace Web

Panel de supervisión para administradores, construido con React, TypeScript y Vite. La ruta pública `/descargar` comparte el APK móvil y no requiere iniciar sesión; el resto de la plataforma continúa protegida por rol de administrador.

## Desarrollo

```sh
npm install
npm run dev
```

Configura `VITE_API_URL` en un archivo `.env.local` para apuntar a la API. Las variables disponibles están documentadas en `.env.example`.

## Página pública de descarga

La página `/descargar` lee estas variables durante la compilación:

| Variable | Uso |
|---|---|
| `VITE_ANDROID_APK_URL` | URL HTTPS directa al APK publicado |
| `VITE_ANDROID_APK_VERSION` | Versión exacta del APK |
| `VITE_ANDROID_APK_SIZE` | Peso exacto mostrado junto al botón |

Si no hay una URL configurada, el botón de descarga permanece desactivado; la página no anuncia un APK que todavía no está publicado. Configura las tres variables en el entorno de producción de Cloudflare Pages y vuelve a desplegar para habilitar la descarga.

La URL para el QR de la presentación es `https://maquitrace.pages.dev/descargar`.

## Build y lint

```sh
npm run build
npm run lint
```
