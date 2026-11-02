# MaquiTrace Mobile

## Configuración de Mapbox

La app recibe el token de Mapbox durante el build, no desde el código fuente.

1. Copia `mapbox.env.json.example` como `mapbox.env.json`.
2. Reemplaza el valor de `MAPBOX_ACCESS_TOKEN` por un token público de Mapbox.
3. Ejecuta `npm run dev:mobile` para desarrollo o `npm run build:mobile` para generar los APK.

El archivo `mapbox.env.json` está excluido de Git. No subas el token al repositorio. Los tokens incluidos en una app móvil pueden extraerse del APK; usa un token público con los permisos mínimos necesarios y revoca el token anterior si ya estuvo comprometido.
