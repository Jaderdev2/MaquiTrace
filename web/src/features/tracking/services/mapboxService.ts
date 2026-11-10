/**
 * Servicio y utilidades de Mapbox para MaquiTrace Web.
 * Idéntico y alineado a la lógica de `mobile/lib/core/services/mapbox_service.dart`.
 */

export const MAPBOX_ACCESS_TOKEN =
  (import.meta as any).env?.VITE_MAPBOX_ACCESS_TOKEN || '';

export const MAPBOX_STYLES = {
  navigationDay: 'mapbox/navigation-day-v1',
  navigationNight: 'mapbox/navigation-night-v1',
  satelliteStreets: 'mapbox/satellite-streets-v12',
  streets: 'mapbox/streets-v12',
};

// Generador de URLs de teselas Mapbox Retina (256px @2x)
export function getMapboxTileUrl(styleId: string, token: string = MAPBOX_ACCESS_TOKEN): string {
  if (!token) {
    // Si no hay token de Mapbox configurado, usar capa satelital/topográfica abierta de alta fidelidad
    if (styleId.includes('satellite')) {
      return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
    if (styleId.includes('night')) {
      return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
    }
    return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
  }
  return `https://api.mapbox.com/styles/v1/${styleId}/tiles/256/{z}/{x}/{y}@2x?access_token=${token}`;
}

export interface MapboxRouteResult {
  points: [number, number][]; // [lat, lng]
  distanceKm: number;
  durationMinutes: number;
  summary: string;
}

/**
 * Consulta la ruta de conducción real por carretera entre dos puntos
 * utilizando la API de Mapbox Directions (idéntico a Flutter).
 */
export async function getDrivingRoute(
  origin: [number, number], // [lat, lng]
  destination: [number, number], // [lat, lng]
  token: string = MAPBOX_ACCESS_TOKEN
): Promise<MapboxRouteResult | null> {
  if (!token) return null;

  try {
    const originStr = `${origin[1]},${origin[0]}`; // lng,lat
    const destStr = `${destination[1]},${destination[0]}`; // lng,lat
    const url = `https://api.mapbox.com/directions/v5/mapbox/driving/${originStr};${destStr}?geometries=geojson&overview=full&steps=true&language=es&access_token=${token}`;

    const res = await fetch(url);
    if (!res.ok) return null;

    const data = await res.json();
    if (!data.routes || data.routes.length === 0) return null;

    const route = data.routes[0];
    const coords = route.geometry?.coordinates || [];

    // Mapbox devuelve [lng, lat], convertimos a [lat, lng] para Leaflet
    const points: [number, number][] = coords.map((c: [number, number]) => [c[1], c[0]]);
    const distanceKm = (route.distance || 0) / 1000;
    const durationMinutes = (route.duration || 0) / 60;
    const summary = route.legs?.[0]?.summary || 'Vía terrestre';

    return {
      points,
      distanceKm,
      durationMinutes,
      summary,
    };
  } catch (err) {
    console.warn('Detalle al consultar Mapbox Directions:', err);
    return null;
  }
}

