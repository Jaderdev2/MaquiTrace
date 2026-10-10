import type {
  CreateMachineDto,
  CreateUserDto,
  Evidence,
  LoginResponse,
  Machine,
  PreparationPhase,
  Role,
  TransportTrip,
  UpdateUserDto,
  User,
} from '../types';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://maquitrace-backend.onrender.com/api/v1';

/**
 * Petición de autenticación al backend NestJS.
 * Endpoint: POST /api/v1/auth/login
 */
export async function loginApi(email: string, password: string): Promise<LoginResponse> {
  const response = await fetch(`${API_BASE_URL}/auth/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ email, password }),
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    const message = Array.isArray(errorData.message)
      ? errorData.message.join(', ')
      : errorData.message || 'Credenciales inválidas o error en el servidor backend.';
    throw new Error(message);
  }

  return await response.json();
}

/**
 * Consulta de maquinarias registradas al backend NestJS.
 * Endpoint: GET /api/v1/machines (requiere Bearer Token)
 */
export async function fetchMachinesApi(token: string): Promise<Machine[]> {
  const response = await fetch(`${API_BASE_URL}/machines`, {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(
      errorData.message || `Error ${response.status}: no se pudo cargar la información de maquinaria.`
    );
  }

  const data = await response.json();
  return Array.isArray(data) ? data : data.data || [];
}

/**
 * Consulta de evidencias multimedia de una máquina en OCI.
 * Endpoint: GET /api/v1/machines/:machineId/evidence (requiere Bearer Token)
 */
export async function fetchMachineEvidenceApi(machineId: string, token: string): Promise<Evidence[]> {
  const response = await fetch(`${API_BASE_URL}/machines/${machineId}/evidence`, {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    return [];
  }

  const data = await response.json();
  return Array.isArray(data) ? data : [];
}

/**
 * Registro de nueva maquinaria en el backend NestJS (Neon PostgreSQL).
 * Endpoint: POST /api/v1/machines (requiere Bearer Token)
 */
export async function createMachineApi(
  payload: CreateMachineDto,
  token: string
): Promise<Machine> {
  const response = await fetch(`${API_BASE_URL}/machines`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    const message = Array.isArray(errorData.message)
      ? errorData.message.join(', ')
      : errorData.message || `Error ${response.status}: no se pudo registrar la máquina.`;
    throw new Error(message);
  }

  return await response.json();
}

/**
 * Actualización de maquinaria en el backend NestJS (Neon PostgreSQL).
 * Endpoint: PATCH /api/v1/machines/:id (requiere Bearer Token)
 */
export async function updateMachineApi(
  id: string,
  payload: Partial<CreateMachineDto>,
  token: string
): Promise<Machine> {
  const response = await fetch(`${API_BASE_URL}/machines/${id}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    const message = Array.isArray(errorData.message)
      ? errorData.message.join(', ')
      : errorData.message || `Error ${response.status}: no se pudo actualizar la máquina.`;
    throw new Error(message);
  }

  return await response.json();
}

/**
 * Eliminación de maquinaria en el backend NestJS (Neon PostgreSQL).
 * Endpoint: DELETE /api/v1/machines/:id (requiere Bearer Token)
 */
export async function deleteMachineApi(id: string, token: string): Promise<boolean> {
  const response = await fetch(`${API_BASE_URL}/machines/${id}`, {
    method: 'DELETE',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    const message = Array.isArray(errorData.message)
      ? errorData.message.join(', ')
      : errorData.message || `Error ${response.status}: no se pudo eliminar la máquina.`;
    throw new Error(message);
  }

  return true;
}

/**
 * Subida de foto de avatar / perfil hacia Oracle Cloud Infrastructure (OCI) a través del backend.
 * Endpoint: POST /api/v1/machines/:machineId/evidence (requiere Bearer Token)
 */
export async function uploadMachineAvatarApi(
  machineId: string,
  file: File,
  token: string
): Promise<Evidence | null> {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('type', 'foto');
  formData.append('observations', '[Avatar] Foto de perfil oficial de la máquina');

  const response = await fetch(`${API_BASE_URL}/machines/${machineId}/evidence`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
    },
    body: formData,
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    const message = Array.isArray(errorData.message)
      ? errorData.message.join(', ')
      : errorData.message || 'Error al subir foto de perfil a Oracle Cloud.';
    throw new Error(message);
  }

  const result = await response.json();
  return result.evidence || result;
}

/**
 * Consulta de fases de alistamiento de una máquina.
 * Endpoint: GET /api/v1/machines/:machineId/phases
 */
export async function fetchMachinePhasesApi(
  machineId: string,
  token: string
): Promise<PreparationPhase[]> {
  const response = await fetch(`${API_BASE_URL}/machines/${machineId}/phases`, {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    return [];
  }

  const data = await response.json();
  return Array.isArray(data) ? data : [];
}

/**
 * Actualización del estado u observaciones de una fase de alistamiento.
 * Endpoint: PATCH /api/v1/machines/:machineId/phases/:phaseId
 */
export async function updatePhaseStatusApi(
  machineId: string,
  phaseId: string,
  payload: { status: string; observations?: string },
  token: string
): Promise<PreparationPhase> {
  const response = await fetch(`${API_BASE_URL}/machines/${machineId}/phases/${phaseId}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    const message = Array.isArray(errorData.message)
      ? errorData.message.join(', ')
      : errorData.message || 'Error al actualizar la fase de alistamiento.';
    throw new Error(message);
  }

  return await response.json();
}

/**
 * Consulta de viajes de transporte activos.
 * Endpoint: GET /api/v1/transport/active
 */
export async function fetchActiveTripsApi(token: string): Promise<TransportTrip[]> {
  const response = await fetch(`${API_BASE_URL}/transport/active`, {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    return [];
  }

  const data = await response.json();
  return Array.isArray(data) ? data : [];
}

/**
 * Consulta de historial de posiciones GPS e incidentes de un viaje.
 * Endpoint: GET /api/v1/tracking/:tripId/history
 */
export async function fetchTripHistoryApi(tripId: string, token: string): Promise<any> {
  const response = await fetch(`${API_BASE_URL}/tracking/${tripId}/history`, {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    throw new Error('Error al obtener el historial de ruta del viaje.');
  }

  return await response.json();
}

/**
 * Marcar salida de transporte.
 * Endpoint: POST /api/v1/transport/depart/:machineId
 */
export async function departTransportApi(machineId: string, token: string): Promise<any> {
  const response = await fetch(`${API_BASE_URL}/transport/depart/${machineId}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.message || 'Error al registrar la salida de transporte.');
  }

  return await response.json();
}

/**
 * Marcar entrega de transporte.
 * Endpoint: POST /api/v1/transport/deliver/:machineId
 */
export async function deliverTransportApi(machineId: string, token: string): Promise<any> {
  const response = await fetch(`${API_BASE_URL}/transport/deliver/${machineId}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.message || 'Error al registrar la entrega de maquinaria.');
  }

  return await response.json();
}

/**
 * Listado de usuarios del sistema con filtro opcional por rol.
 * Endpoint: GET /api/v1/users
 */
export async function fetchUsersApi(role?: string, token?: string): Promise<User[]> {
  const url = role && role !== 'todos'
    ? `${API_BASE_URL}/users?role=${encodeURIComponent(role)}`
    : `${API_BASE_URL}/users`;

  const headers: HeadersInit = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const response = await fetch(url, { method: 'GET', headers });

  if (!response.ok) {
    return [];
  }

  const data = await response.json();
  return Array.isArray(data) ? data : [];
}

/**
 * Obtener roles oficiales del sistema.
 * Endpoint: GET /api/v1/users/roles
 */
export async function fetchRolesApi(token?: string): Promise<Role[]> {
  const headers: HeadersInit = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const response = await fetch(`${API_BASE_URL}/users/roles`, {
    method: 'GET',
    headers,
  });

  if (!response.ok) {
    return [
      { id: '1', name: 'operario' },
      { id: '2', name: 'transportador' },
      { id: '3', name: 'administrador' },
    ];
  }

  const data = await response.json();
  return Array.isArray(data) ? data : [];
}

/**
 * Crear un nuevo usuario en el sistema.
 * Endpoint: POST /api/v1/users
 */
export async function createUserApi(payload: CreateUserDto, token: string): Promise<User> {
  const response = await fetch(`${API_BASE_URL}/users`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    const message = Array.isArray(errorData.message)
      ? errorData.message.join(', ')
      : errorData.message || 'Error al crear el usuario en el backend.';
    throw new Error(message);
  }

  return await response.json();
}

/**
 * Actualizar datos o rol de un usuario.
 * Endpoint: PATCH /api/v1/users/:id
 */
export async function updateUserApi(
  id: string,
  payload: UpdateUserDto,
  token: string
): Promise<User> {
  const response = await fetch(`${API_BASE_URL}/users/${id}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    const message = Array.isArray(errorData.message)
      ? errorData.message.join(', ')
      : errorData.message || 'Error al actualizar el usuario.';
    throw new Error(message);
  }

  return await response.json();
}

/**
 * Eliminar usuario.
 * Endpoint: DELETE /api/v1/users/:id
 */
export async function deleteUserApi(id: string, token: string): Promise<boolean> {
  const response = await fetch(`${API_BASE_URL}/users/${id}`, {
    method: 'DELETE',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.message || 'Error al eliminar el usuario.');
  }

  return true;
}
