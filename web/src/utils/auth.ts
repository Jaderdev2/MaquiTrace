import type { User } from '../types';

/**
 * Extrae y normaliza el nombre del rol del usuario.
 */
export function getRoleName(user: User | null | undefined): string {
  if (!user || !user.role) return '';
  if (typeof user.role === 'object' && user.role !== null) {
    return user.role.name || '';
  }
  return String(user.role);
}

/**
 * Valida si el usuario cuenta con rol de Administrador.
 * En la plataforma web de MaquiTrace, el acceso está reservado exclusivamente
 * para Administradores. Los operarios y transportadores operan desde la app móvil.
 */
export function isAdminUser(user: User | null | undefined): boolean {
  if (!user) return false;
  const roleName = getRoleName(user).trim().toLowerCase();
  return roleName === 'administrador' || roleName === 'admin';
}
