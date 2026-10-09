import type { Machine, Evidence } from '../types';

/**
 * Obtiene la imagen de evidencia principal tomada por operarios y almacenada en el backend / OCI.
 * Retorna null si la máquina aún no tiene evidencias fotográficas registradas en el backend.
 */
export function getMachinePrimaryPhoto(machine: Machine): string | null {
  if (!machine.evidence || machine.evidence.length === 0) return null;

  // 1. Priorizar foto frontal registrada desde la app móvil
  const frontal = machine.evidence.find((e) => {
    const isPhoto = e.type === 'foto' || !e.type;
    const urlMatches = e.url.toLowerCase().includes('frontal');
    const obsMatches = e.observations?.toLowerCase().includes('frontal');
    return isPhoto && (urlMatches || obsMatches);
  });
  if (frontal) return frontal.url;

  // 2. Cualquier otra foto registrada
  const anyPhoto = machine.evidence.find((e) => e.type === 'foto' || !e.type);
  if (anyPhoto) return anyPhoto.url;

  // 3. Primer archivo multimedia registrado en backend
  return machine.evidence[0]?.url || null;
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
  if (ev.observations) {
    const bracketMatch = ev.observations.match(/^\[(.*?)\]/);
    if (bracketMatch && bracketMatch[1]) {
      return bracketMatch[1];
    }
  }

  const urlLower = ev.url.toLowerCase();
  if (urlLower.includes('frontal')) return 'Vista Frontal';
  if (urlLower.includes('lateral')) return 'Vista Lateral';
  if (urlLower.includes('cabina')) return 'Cabina e Interior';
  if (urlLower.includes('serial')) return 'Serial y Plaqueta';

  return ev.type === 'video' ? 'Video de Inspección' : 'Foto de Inspección';
}
