/**
 * Tipos de dominio centrales de MaquiTrace.
 * Alineados con el esquema de base de datos y la aplicación móvil.
 */

export type UserRole = 'OPERATOR' | 'SUPERVISOR' | 'TRANSPORTER' | 'ADMIN';

export type MachineCategory =
  | 'Excavadoras'
  | 'Cargadores frontales'
  | 'Retroexcavadoras'
  | 'Volquetas'
  | 'Motoniveladoras';

export type OverallState =
  | 'pending'
  | 'in_progress'
  | 'completed'
  | 'in_transit'
  | 'delivered';

export type PhaseState = 'pending' | 'in_progress' | 'completed';

export interface Headquarters {
  id: string;
  name: string;
  department: string;
  facilityAddress: string;
  supervisorName: string;
}

export interface UserProfile {
  id: string;
  name: string;
  nationalId: string;
  operatorCode: string;
  role: UserRole;
  headquartersId: string;
  certTitle?: string;
  certExpiresAt?: string;
}

export interface Machine {
  id: string;
  name: string;
  serial: string;
  category: MachineCategory;
  modelYear: string;
  overallState: OverallState;
  yardLocation: string;
  operatingHours: string;
  fuelPercent: number;
  batteryVoltage: string;
  headquartersId: string;
  assignedOperator?: string;
  imageUrl?: string;
  notes?: string;
}

export interface PreparationPhase {
  phaseNumber: number;
  name: string;
  status: PhaseState;
  completedAt?: string;
  notes?: string;
}

export interface EvidencePhoto {
  id: string;
  preparationId: string;
  angle: 'frente' | 'oruga_izq' | 'cabina' | 'motor';
  url: string;
  takenAt: string;
}

export interface Preparation {
  id: string;
  machineId: string;
  operatorId: string;
  supervisorId?: string;
  status: OverallState;
  startedAt: string;
  closedAt?: string;
  durationMinutes?: number;
  phases: PreparationPhase[];
  photos: EvidencePhoto[];
  notes?: string;
}
