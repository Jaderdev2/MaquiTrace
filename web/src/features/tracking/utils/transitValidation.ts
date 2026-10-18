import type { Machine, PreparationPhase, TransportTrip } from '../../../types';

export interface TransitReadinessResult {
  canDepart: boolean;
  status: 'ready' | 'in_preparation' | 'pending_preparation' | 'already_in_transit' | 'already_delivered';
  currentPhaseName?: string;
  badgeLabel: string;
  badgeType: 'success' | 'warning' | 'danger' | 'info';
  reason: string;
  completedPhasesCount: number;
  totalPhasesCount: number;
}

/**
 * Evalúa si una máquina ha concluido satisfactoriamente su proceso de alistamiento
 * (Ensamblaje, Pintura, Lavado) y está autorizada para salir a carretera.
 */
export function checkMachineTransitReadiness(machine?: Machine | null): TransitReadinessResult {
  if (!machine) {
    return {
      canDepart: true,
      status: 'ready',
      badgeLabel: 'Sin restricción técnica',
      badgeType: 'info',
      reason: 'No hay ficha de alistamiento registrada para este equipo.',
      completedPhasesCount: 3,
      totalPhasesCount: 3,
    };
  }

  // Si la máquina ya fue despachada y está rodando
  if (machine.status === 'en_transito') {
    return {
      canDepart: false,
      status: 'already_in_transit',
      badgeLabel: 'Ya en Tránsito',
      badgeType: 'info',
      reason: 'La maquinaria ya se encuentra en carretera.',
      completedPhasesCount: 3,
      totalPhasesCount: 3,
    };
  }

  // Si la máquina ya fue entregada en obra
  if (machine.status === 'entregada') {
    return {
      canDepart: false,
      status: 'already_delivered',
      badgeLabel: 'Entregada en Obra',
      badgeType: 'success',
      reason: 'La maquinaria ya fue recibida en destino.',
      completedPhasesCount: 3,
      totalPhasesCount: 3,
    };
  }

  const phases = machine.phases || [];
  const totalPhases = phases.length;

  // Si tiene fases registradas en base de datos
  if (totalPhases > 0) {
    const completedPhases = phases.filter((p: PreparationPhase) => p.status === 'completada').length;
    const allCompleted = completedPhases === totalPhases;

    if (allCompleted || machine.status === 'completada') {
      return {
        canDepart: true,
        status: 'ready',
        badgeLabel: 'Alistamiento Aprobado (3/3)',
        badgeType: 'success',
        reason: 'Todas las etapas de alistamiento en taller fueron aprobadas con éxito.',
        completedPhasesCount: completedPhases,
        totalPhasesCount: totalPhases,
      };
    }

    const inProcess = phases.find((p: PreparationPhase) => p.status === 'en_proceso');
    const pending = phases.find((p: PreparationPhase) => p.status === 'pendiente');
    const activePhaseName = inProcess?.name || pending?.name || 'taller';
    const capitalized = activePhaseName.charAt(0).toUpperCase() + activePhaseName.slice(1);

    return {
      canDepart: false,
      status: 'in_preparation',
      currentPhaseName: capitalized,
      badgeLabel: `En Taller: ${capitalized} (${completedPhases}/${totalPhases})`,
      badgeType: 'warning',
      reason: `El equipo aún tiene pendiente la fase de "${capitalized}". Debe completarse el alistamiento físico antes de autorizar la salida a carretera.`,
      completedPhasesCount: completedPhases,
      totalPhasesCount: totalPhases,
    };
  }

  // Si no tiene fases pero su status es 'completada'
  if (machine.status === 'completada') {
    return {
      canDepart: true,
      status: 'ready',
      badgeLabel: 'Alistamiento Aprobado',
      badgeType: 'success',
      reason: 'El equipo se encuentra marcado como completado y listo para despacho.',
      completedPhasesCount: 3,
      totalPhasesCount: 3,
    };
  }

  // Status 'en_proceso' o 'pendiente'
  const isProcess = machine.status === 'en_proceso';
  return {
    canDepart: false,
    status: isProcess ? 'in_preparation' : 'pending_preparation',
    currentPhaseName: isProcess ? 'Alistamiento Activo' : 'Pendiente de Inicio',
    badgeLabel: isProcess ? 'Alistamiento en Proceso' : 'Alistamiento Pendiente',
    badgeType: 'warning',
    reason: isProcess
      ? 'La maquinaria está siendo intervenida en taller central. Requiere aprobación final para salir a tránsito.'
      : 'La maquinaria no ha iniciado su ciclo de alistamiento técnico en taller.',
    completedPhasesCount: 0,
    totalPhasesCount: 3,
  };
}

/**
 * Valida si una máquina ya está asignada a un viaje activo en curso
 */
export function isMachineInActiveTrip(machineId: string, trips: TransportTrip[], excludeTripId?: string): boolean {
  return trips.some((t) => {
    if (excludeTripId && t.id === excludeTripId) return false;
    const sameMachine = t.machineId === machineId || t.machine?.id === machineId;
    const isOngoing = t.status === 'pendiente' || t.status === 'en_transito';
    return sameMachine && isOngoing;
  });
}
