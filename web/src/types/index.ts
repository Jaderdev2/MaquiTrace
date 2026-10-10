export interface Role {
  id: string;
  name: string;
}

export interface User {
  id: string;
  name: string;
  email: string;
  role?: string | { id?: string; name: string };
  roleId?: string;
  phone?: string;
  createdAt?: string;
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

export interface GpsRecord {
  id: string;
  tripId: string;
  latitude: number;
  longitude: number;
  recordedAt: string;
}

export interface Incident {
  id: string;
  tripId: string;
  description: string;
  photoUrl?: string;
  reportedAt: string;
}

export interface TransportTrip {
  id: string;
  machineId?: string;
  machine?: Machine;
  transporterId?: string;
  vehicle: string;
  destination: string;
  status: 'pendiente' | 'en_transito' | 'entregado';
  departureAt?: string;
  arrivalAt?: string;
  transporter?: {
    id?: string;
    name: string;
    email?: string;
    phone?: string;
  };
  gpsRecords?: GpsRecord[];
  incidents?: Incident[];
}

export interface Machine {
  id: string;
  category: string;
  serial: string;
  model: string;
  status: MachineStatus;
  imageUrl?: string | null;
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
  imageUrl?: string | null;
}

export interface CreateUserDto {
  name: string;
  email: string;
  roleId: string;
  password?: string;
  phone?: string;
}

export interface UpdateUserDto {
  name?: string;
  email?: string;
  roleId?: string;
  password?: string;
  phone?: string;
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
