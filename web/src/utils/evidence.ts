import type { Machine, Evidence } from '../types';

/**
 * Obtiene la imagen principal representativa de una máquina.
 * Prioriza:
 * 1. Evidencia con etiqueta o URL de 'frontal' (ángulo frontal requerido en app)
 * 2. Cualquier evidencia de tipo 'foto'
 * 3. Primera evidencia disponible
 */
export function getMachinePrimaryPhoto(machine: Machine): string | null {
  if (!machine.evidence || machine.evidence.length === 0) return null;

  // 1. Priorizar foto frontal
  const frontal = machine.evidence.find((e) => {
    const isPhoto = e.type === 'foto' || !e.type;
    const urlMatches = e.url.toLowerCase().includes('frontal');
    const obsMatches = e.observations?.toLowerCase().includes('frontal');
    return isPhoto && (urlMatches || obsMatches);
  });
  if (frontal) return frontal.url;

  // 2. Cualquier foto
  const anyPhoto = machine.evidence.find((e) => e.type === 'foto' || !e.type);
  if (anyPhoto) return anyPhoto.url;

  // 3. Primer archivo multimedia registrado
  return machine.evidence[0]?.url || null;
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
