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
  startedAt?: string;
  completedAt?: string;
}

export interface Evidence {
  id: string;
  type: 'foto' | 'video';
  url: string;
  createdAt: string;
}

export interface Machine {
  id: string;
  category: string;
  serial: string;
  model: string;
  status: MachineStatus;
  phases?: PreparationPhase[];
  evidence?: Evidence[];
  createdAt?: string;
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
