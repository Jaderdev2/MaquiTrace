import type { Machine, Evidence } from '../types';

/**
 * Obtiene la imagen de evidencia principal tomada por operarios y almacenada en el backend / OCI.
 * Retorna null si la máquina aún no tiene evidencias fotográficas registradas en el backend.
 */
export function getMachinePrimaryPhoto(machine: Machine): string | null {
  // 1. Priorizar URL oficial de avatar/foto configurada en la máquina
  if (machine.imageUrl && machine.imageUrl.trim().length > 0) {
    return machine.imageUrl;
  }

  if (!machine.evidence || machine.evidence.length === 0) return null;

  // 2. Priorizar foto de avatar guardada en evidencias
  const avatar = machine.evidence.find((e) => {
    const isPhoto = e.type === 'foto' || !e.type;
    const urlMatches = typeof e.url === 'string' && e.url.toLowerCase().includes('avatar');
    const obsMatches = typeof e.observations === 'string' && e.observations.toLowerCase().includes('avatar');
    return isPhoto && (urlMatches || obsMatches);
  });
  if (avatar?.url) return avatar.url;

  // 3. Priorizar foto frontal registrada desde la app móvil
  const frontal = machine.evidence.find((e) => {
    const isPhoto = e.type === 'foto' || !e.type;
    const urlMatches = typeof e.url === 'string' && e.url.toLowerCase().includes('frontal');
    const obsMatches = typeof e.observations === 'string' && e.observations.toLowerCase().includes('frontal');
    return isPhoto && (urlMatches || obsMatches);
  });
  if (frontal?.url) return frontal.url;

  // 3. Cualquier otra foto registrada
  const anyPhoto = machine.evidence.find((e) => (e.type === 'foto' || !e.type) && typeof e.url === 'string' && e.url.trim().length > 0);
  if (anyPhoto?.url) return anyPhoto.url;

  // 4. Primer archivo multimedia registrado en backend
  return machine.evidence[0]?.url || null;
}

/**
 * Obtiene una lista ordenada y sin duplicados de todas las URLs de fotografía
 * disponibles para una máquina (imageUrl oficial, evidencias de taller y fotos del viaje).
 * Permite hacer fallback automático si una URL falla al cargar.
 */
export function getMachineCandidatePhotos(
  machine?: Machine | null,
  extraUrls: (string | null | undefined)[] = []
): string[] {
  const candidates: string[] = [];
  const addUrl = (url?: string | null) => {
    const clean = url?.trim();
    if (clean && !candidates.includes(clean)) {
      candidates.push(clean);
    }
  };

  if (machine) {
    addUrl(machine.imageUrl);
    const primary = getMachinePrimaryPhoto(machine);
    addUrl(primary);
    if (machine.evidence && Array.isArray(machine.evidence)) {
      for (const ev of machine.evidence) {
        if (ev.type === 'foto' || !ev.type) {
          addUrl(ev.url);
        }
      }
    }
  }

  for (const extra of extraUrls) {
    addUrl(extra);
  }

  return candidates;
}

/**
 * Extrae una etiqueta o título corto representativo de la evidencia fotográfica
 * enviada por el conductor o registrada en alistamiento (ej: "Derrumbe", "Salida", "Control vial").
 */
export function getEvidenceShortTitle(ev: Evidence): string {
  const rawObs = (ev.observations || '').trim();

  if (rawObs) {
    // Si tiene etiqueta entre corchetes como [Vista Frontal] o [Salida]
    const bracketMatch = rawObs.match(/^\[(.*?)\]/);
    if (bracketMatch && bracketMatch[1]) {
      return bracketMatch[1].trim();
    }

    const lower = rawObs.toLowerCase();
    if (lower.startsWith('acta de entrega digital')) return 'Acta de Entrega (POD)';
    if (lower.startsWith('foto de entrega')) return 'Entrega en Destino';
    if (lower.includes('derrumbe') || lower.includes('cierre de vía') || lower.includes('cierre de via')) {
      return 'Cierre de vía / Derrumbe';
    }
    if (lower.includes('salida')) return 'Salida';
    if (lower.includes('retén') || lower.includes('reten') || lower.includes('control vial')) {
      return 'Retén / Control vial';
    }
    if (lower.includes('falla mecánica') || lower.includes('falla mecanica')) {
      return 'Falla mecánica';
    }
    if (lower.includes('clima') || lower.includes('lluvia')) {
      return 'Clima adverso / Lluvia';
    }

    // Si el conductor puso un texto corto (ej: "Derrumbe", "Salida", "Parada técnica"), mostrarlo directo
    const firstLine = rawObs.split('\n')[0].trim();
    const firstSegment = firstLine.split(/[•|—|-]/)[0].trim();
    if (firstSegment.length > 0 && firstSegment.length <= 36) {
      return firstSegment;
    }
    if (firstLine.length <= 42) {
      return firstLine;
    }
    return `${firstLine.slice(0, 39)}...`;
  }

  return getEvidenceAngleLabel(ev);
}

/**
 * Obtiene la foto de perfil de la máquina 100% proveniente del backend (Oracle Cloud).
 * Retorna null si no tiene fotos subidas por operarios.
 */
export function getMachineProfileImage(machine: Machine): string | null {
  return getMachinePrimaryPhoto(machine);
}

/**
 * Extrae un título descriptivo legible del ángulo de la evidencia.
 * Corresponde a los 4 ángulos oficiales del checklist de la app móvil:
 * - Vista Frontal
 * - Vista Lateral
 * - Cabina e Interior
 * - Serial y Plaqueta
 */
export function getEvidenceAngleLabel(ev: Evidence): string {
  if (typeof ev.observations === 'string' && ev.observations) {
    const bracketMatch = ev.observations.match(/^\[(.*?)\]/);
    if (bracketMatch && bracketMatch[1]) {
      return bracketMatch[1];
    }
  }

  const urlLower = typeof ev.url === 'string' ? ev.url.toLowerCase() : '';
  if (urlLower.includes('frontal')) return 'Vista Frontal';
  if (urlLower.includes('lateral')) return 'Vista Lateral';
  if (urlLower.includes('cabina')) return 'Cabina e Interior';
  if (urlLower.includes('serial')) return 'Serial y Plaqueta';

  return ev.type === 'video' ? 'Video de Inspección' : 'Foto de Inspección';
}

/**
 * Normaliza el nombre del rol del uploader sin importar si el backend devuelve un string o un objeto Role { id, name }.
 */
export function getEvidenceUploaderRole(ev?: Evidence | null): string {
  const rawRole = ev?.uploader?.role as any;
  if (!rawRole) return '';
  if (typeof rawRole === 'string') return rawRole;
  if (typeof rawRole === 'object' && typeof rawRole.name === 'string') {
    return rawRole.name;
  }
  return '';
}
