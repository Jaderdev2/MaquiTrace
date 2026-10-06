import type { LoginResponse, Machine } from '../types';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api/v1';

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
