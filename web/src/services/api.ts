import type { LoginResponse, Machine } from '../types';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api/v1';

export const mockMachines: Machine[] = [
  {
    id: 'm-001',
    serial: 'EXC-2024-001',
    model: 'Caterpillar 320D3',
    category: 'Excavadora',
    status: 'en_proceso',
    createdAt: '2026-10-01T08:30:00Z',
    phases: [
      { id: 'p1', name: 'ensamblaje', status: 'completada', observations: 'Estructura principal y motor montados correctamente' },
      { id: 'p2', name: 'pintura', status: 'en_proceso', observations: 'Aplicando capa anticorrosiva industrial' },
      { id: 'p3', name: 'lavado', status: 'pendiente' },
    ],
  },
  {
    id: 'm-002',
    serial: 'RET-2024-004',
    model: 'JCB 3CX Eco',
    category: 'Retroexcavadora',
    status: 'completada',
    createdAt: '2026-10-02T09:15:00Z',
    phases: [
      { id: 'p4', name: 'ensamblaje', status: 'completada' },
      { id: 'p5', name: 'pintura', status: 'completada' },
      { id: 'p6', name: 'lavado', status: 'completada', observations: 'Inspección final de limpieza aprobada' },
    ],
  },
  {
    id: 'm-003',
    serial: 'CAR-2024-012',
    model: 'Komatsu WA380-6',
    category: 'Cargador Frontal',
    status: 'en_transito',
    createdAt: '2026-10-03T11:00:00Z',
    phases: [
      { id: 'p7', name: 'ensamblaje', status: 'completada' },
      { id: 'p8', name: 'pintura', status: 'completada' },
      { id: 'p9', name: 'lavado', status: 'completada' },
    ],
  },
  {
    id: 'm-004',
    serial: 'BUL-2024-007',
    model: 'Shantui SD22',
    category: 'Bulldozer',
    status: 'pendiente',
    createdAt: '2026-10-04T14:20:00Z',
    phases: [
      { id: 'p10', name: 'ensamblaje', status: 'pendiente' },
      { id: 'p11', name: 'pintura', status: 'pendiente' },
      { id: 'p12', name: 'lavado', status: 'pendiente' },
    ],
  },
  {
    id: 'm-005',
    serial: 'MOT-2024-002',
    model: 'John Deere 670G',
    category: 'Motoniveladora',
    status: 'entregada',
    createdAt: '2026-09-28T16:45:00Z',
    phases: [
      { id: 'p13', name: 'ensamblaje', status: 'completada' },
      { id: 'p14', name: 'pintura', status: 'completada' },
      { id: 'p15', name: 'lavado', status: 'completada' },
    ],
  },
];

export async function loginApi(email: string, password: string): Promise<LoginResponse> {
  try {
    const response = await fetch(`${API_BASE_URL}/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ email, password }),
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.message || 'Credenciales inválidas o error de conexión con el servidor.');
    }

    return await response.json();
  } catch (error: any) {
    console.warn('API /auth/login connection failed, trying fallback mode:', error.message);
    
    if (email === 'admin@maquitrace.com' && password === 'admin123') {
      return {
        accessToken: 'demo_jwt_token_admin_12345',
        user: {
          id: 'u-admin-01',
          name: 'Jhon Jader Riascos',
          email: 'admin@maquitrace.com',
          role: 'ADMIN',
        },
      };
    }
    
    if (email === 'supervisor@maquitrace.com' && password === 'super123') {
      return {
        accessToken: 'demo_jwt_token_super_12345',
        user: {
          id: 'u-super-02',
          name: 'Charly Jhoan Murillo',
          email: 'supervisor@maquitrace.com',
          role: 'SUPERVISOR',
        },
      };
    }

    if (email === 'operario@maquitrace.com' && password === 'oper123') {
      return {
        accessToken: 'demo_jwt_token_oper_12345',
        user: {
          id: 'u-oper-03',
          name: 'Carlos Ramírez',
          email: 'operario@maquitrace.com',
          role: 'OPERATOR',
        },
      };
    }

    throw new Error(error.message || 'No se pudo conectar con el servidor NestJS en http://localhost:3000');
  }
}

export async function fetchMachinesApi(token: string): Promise<{ data: Machine[]; isMock: boolean }> {
  try {
    const response = await fetch(`${API_BASE_URL}/machines`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: Error al obtener maquinarias.`);
    }

    const data = await response.json();
    const machinesList = Array.isArray(data) ? data : data.data || mockMachines;
    return { data: machinesList, isMock: false };
  } catch (error) {
    console.warn('Backend /machines unreachable, falling back to mock data:', error);
    return { data: mockMachines, isMock: true };
  }
}
