export type UserRole = 'ADMIN' | 'SUPERVISOR' | 'OPERATOR' | 'administrador' | 'supervisor' | 'operario' | 'transportador';

export interface User {
  id: string;
  name: string;
  email: string;
  role: UserRole | { name: string };
  phone?: string;
}

export type MachineStatus = 'pendiente' | 'en_proceso' | 'completada' | 'en_transito' | 'entregada';
export type PhaseName = 'ensamblaje' | 'pintura' | 'lavado';
export type PhaseStatus = 'pendiente' | 'en_proceso' | 'completada';

export interface PreparationPhase {
  id: string;
  name: PhaseName;
  status: PhaseStatus;
  observations?: string;
  operatorId?: string;
  operator?: {
    id?: string;
    name: string;
    email?: string;
  };
  startedAt?: string;
  completedAt?: string;
}

export interface Evidence {
  id: string;
  type: 'foto' | 'video';
  url: string;
  createdAt: string;
  machineId?: string;
  phaseId?: string;
  uploadedBy?: string;
  uploader?: {
    id?: string;
    name?: string;
    email?: string;
    role?: string;
  };
  observations?: string;
}

export interface TransportTrip {
  id: string;
  vehicle: string;
  destination: string;
  status: 'pendiente' | 'en_transito' | 'entregado';
  departureAt?: string;
  arrivalAt?: string;
  transporter?: {
    name: string;
  };
}

export interface Machine {
  id: string;
  category: string;
  serial: string;
  model: string;
  status: MachineStatus;
  phases?: PreparationPhase[];
  evidence?: Evidence[];
  trips?: TransportTrip[];
  createdAt?: string;
}

export interface CreateMachineDto {
  category: string;
  serial: string;
  model: string;
  status?: MachineStatus;
}

export interface LoginResponse {
  accessToken: string;
  user: User;
}

export interface AuthContextType {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  loading: boolean;
  login: (token: string, user: User) => void;
  logout: () => void;
}
