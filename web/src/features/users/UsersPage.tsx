import React, { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../../context/AuthContext';
import {
  fetchUsersApi,
  fetchRolesApi,
  createUserApi,
  updateUserApi,
  deleteUserApi,
} from '../../services/api';
import type { User, Role, CreateUserDto, UpdateUserDto } from '../../types';
import { Sidebar } from '../../components/Sidebar';
import { Navbar } from '../../components/Navbar';
import {
  Users,
  UserPlus,
  Search,
  RefreshCw,
  Mail,
  Phone,
  Shield,
  Edit,
  Trash2,
  AlertCircle,
  CheckCircle2,
  Loader2,
  X,
  Check,
  LayoutGrid,
  List,
  Wrench,
  Truck,
  ShieldCheck,
} from 'lucide-react';
import '../../styles/machines.css';
import '../../styles/users.css';

export const UsersPage: React.FC = () => {
  const { token, user: currentUser } = useAuth();
  const [users, setUsers] = useState<User[]>([]);
  const [roles, setRoles] = useState<Role[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [successBanner, setSuccessBanner] = useState<string | null>(null);
  const [sidebarOpen, setSidebarOpen] = useState<boolean>(false);
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [roleFilter, setRoleFilter] = useState<string>('todos');
  const [viewMode, setViewMode] = useState<'grid' | 'table'>('table');

  // Modal Crear Usuario
  const [createModalOpen, setCreateModalOpen] = useState<boolean>(false);
  const [newName, setNewName] = useState<string>('');
  const [newEmail, setNewEmail] = useState<string>('');
  const [newPhone, setNewPhone] = useState<string>('');
  const [newRoleId, setNewRoleId] = useState<string>('');
  const [newPassword, setNewPassword] = useState<string>('');
  const [createLoading, setCreateLoading] = useState<boolean>(false);
  const [createError, setCreateError] = useState<string | null>(null);

  // Modal Editar Usuario
  const [editingUser, setEditingUser] = useState<User | null>(null);
  const [editName, setEditName] = useState<string>('');
  const [editEmail, setEditEmail] = useState<string>('');
  const [editPhone, setEditPhone] = useState<string>('');
  const [editRoleId, setEditRoleId] = useState<string>('');
  const [editLoading, setEditLoading] = useState<boolean>(false);
  const [editError, setEditError] = useState<string | null>(null);

  // Modal Eliminar Usuario
  const [deletingUser, setDeletingUser] = useState<User | null>(null);
  const [deleteLoading, setDeleteLoading] = useState<boolean>(false);

  const loadData = useCallback(async () => {
    if (!token) return;
    try {
      setLoading(true);
      setError(null);
      const [usersData, rolesData] = await Promise.all([
        fetchUsersApi(roleFilter !== 'todos' ? roleFilter : undefined, token),
        fetchRolesApi(token),
      ]);
      setUsers(usersData);
      setRoles(rolesData);
      if (rolesData.length > 0 && !newRoleId) {
        setNewRoleId(rolesData[0].id);
      }
    } catch (err: any) {
      setError(err.message || 'Error al conectar con el servidor.');
    } finally {
      setLoading(false);
    }
  }, [token, roleFilter, newRoleId]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Manejo de Creación de Usuario
  const handleCreateUser = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!token) return;
    setCreateError(null);

    if (!newName.trim() || !newEmail.trim() || !newRoleId) {
      setCreateError('Nombre, correo electrónico y rol son obligatorios.');
      return;
    }

    try {
      setCreateLoading(true);
      const payload: CreateUserDto = {
        name: newName.trim(),
        email: newEmail.trim(),
        roleId: newRoleId,
        phone: newPhone.trim() || undefined,
        password: newPassword.trim() || 'MaquiTrace2026!',
      };

      const created = await createUserApi(payload, token);
      setUsers((prev) => [created, ...prev]);
      setSuccessBanner(`¡Usuario ${created.name} registrado con éxito!`);
      setTimeout(() => setSuccessBanner(null), 5000);
      setCreateModalOpen(false);
      // Reset form
      setNewName('');
      setNewEmail('');
      setNewPhone('');
      setNewPassword('');
    } catch (err: any) {
      setCreateError(err.message || 'Error al crear usuario.');
    } finally {
      setCreateLoading(false);
    }
  };

  // Abrir modal de edición
  const handleOpenEdit = (user: User) => {
    setEditingUser(user);
    setEditName(user.name);
    setEditEmail(user.email);
    setEditPhone(user.phone || '');
    const currentRoleId = typeof user.role === 'object' && user.role ? (user.role as any).id : user.roleId || '';
    setEditRoleId(currentRoleId);
    setEditError(null);
  };

  // Manejo de Actualización de Usuario
  const handleUpdateUser = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingUser || !token) return;
    setEditError(null);

    try {
      setEditLoading(true);
      const payload: UpdateUserDto = {
        name: editName.trim(),
        email: editEmail.trim(),
        phone: editPhone.trim() || undefined,
        roleId: editRoleId || undefined,
      };

      const updated = await updateUserApi(editingUser.id, payload, token);
      setUsers((prev) => prev.map((u) => (u.id === updated.id ? updated : u)));
      setSuccessBanner(`¡Usuario ${updated.name} actualizado con éxito!`);
      setTimeout(() => setSuccessBanner(null), 5000);
      setEditingUser(null);
    } catch (err: any) {
      setEditError(err.message || 'Error al actualizar usuario.');
    } finally {
      setEditLoading(false);
    }
  };

  // Manejo de Eliminación
  const handleConfirmDelete = async () => {
    if (!deletingUser || !token) return;
    try {
      setDeleteLoading(true);
      await deleteUserApi(deletingUser.id, token);
      setUsers((prev) => prev.filter((u) => u.id !== deletingUser.id));
      setSuccessBanner(`Usuario ${deletingUser.name} eliminado del sistema.`);
      setTimeout(() => setSuccessBanner(null), 5000);
      setDeletingUser(null);
    } catch (err: any) {
      setError(err.message || 'Error al eliminar usuario.');
    } finally {
      setDeleteLoading(false);
    }
  };

  const getRoleName = (user: User): string => {
    if (typeof user.role === 'object' && user.role) {
      return (user.role as any).name || 'Usuario';
    }
    return (user.role as string) || 'Usuario';
  };

  const getInitials = (name: string): string => {
    const parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
    }
    return name.slice(0, 2).toUpperCase();
  };

  // Métricas
  const totalCount = users.length;
  const operariosCount = users.filter((u) => getRoleName(u).toLowerCase().includes('operario')).length;
  const transportadoresCount = users.filter((u) => getRoleName(u).toLowerCase().includes('transportador')).length;
  const adminsCount = users.filter((u) => getRoleName(u).toLowerCase().includes('admin')).length;

  // Filtro reactivo
  const filteredUsers = users.filter((u) => {
    if (!searchTerm.trim()) return true;
    const q = searchTerm.toLowerCase();
    const roleName = getRoleName(u).toLowerCase();
    return (
      u.name.toLowerCase().includes(q) ||
      u.email.toLowerCase().includes(q) ||
      (u.phone && u.phone.toLowerCase().includes(q)) ||
      roleName.includes(q)
    );
  });

  return (
    <div className="machines-page-layout">
      <Sidebar
        currentTab="usuarios"
        onSelectTab={() => {}}
        isOpen={sidebarOpen}
        onCloseMobile={() => setSidebarOpen(false)}
      />

      <div className="machines-main-wrapper">
        <Navbar
          onToggleSidebar={() => setSidebarOpen((prev) => !prev)}
          searchValue={searchTerm}
          onSearchChange={setSearchTerm}
        />

        <main className="machines-content-area">
          <div className="machines-header-row">
            <div className="machines-title-box">
              <h1>Control y Gestión de Usuarios</h1>
              <span className="machines-title-sub">
                Administración de cuentas oficiales, permisos de acceso y asignación de roles operativos.
              </span>
            </div>

            <div className="machines-actions-group">
              <button
                type="button"
                className="btn-refresh-data"
                onClick={loadData}
                disabled={loading}
                title="Actualizar datos desde el servidor"
              >
                <RefreshCw size={15} className={loading ? 'spinner' : ''} />
                <span>Actualizar</span>
              </button>

              <button
                type="button"
                className="btn-create-machine"
                onClick={() => setCreateModalOpen(true)}
              >
                <UserPlus size={18} />
                <span>Nuevo Usuario</span>
              </button>
            </div>
          </div>

          {successBanner && (
            <div className="register-alert success">
              <CheckCircle2 size={18} />
              <span>{successBanner}</span>
            </div>
          )}

          {error && (
            <div className="register-alert error">
              <AlertCircle size={18} />
              <span>{error}</span>
            </div>
          )}

          {/* Tarjetas KPI */}
          <div className="machines-kpi-grid">
            <div className="machine-kpi-card">
              <div className="machine-kpi-icon icon-blue">
                <Users size={22} />
              </div>
              <div className="machine-kpi-data">
                <span className="machine-kpi-num">{loading ? '...' : totalCount}</span>
                <span className="machine-kpi-label">Usuarios Registrados</span>
              </div>
            </div>

            <div className="machine-kpi-card">
              <div className="machine-kpi-icon icon-amber">
                <Wrench size={22} />
              </div>
              <div className="machine-kpi-data">
                <span className="machine-kpi-num">{loading ? '...' : operariosCount}</span>
                <span className="machine-kpi-label">Operarios de Taller</span>
              </div>
            </div>

            <div className="machine-kpi-card">
              <div className="machine-kpi-icon icon-blue">
                <Truck size={22} />
              </div>
              <div className="machine-kpi-data">
                <span className="machine-kpi-num">{loading ? '...' : transportadoresCount}</span>
                <span className="machine-kpi-label">Transportadores en Ruta</span>
              </div>
            </div>

            <div className="machine-kpi-card">
              <div className="machine-kpi-icon icon-emerald">
                <ShieldCheck size={22} />
              </div>
              <div className="machine-kpi-data">
                <span className="machine-kpi-num">{loading ? '...' : adminsCount}</span>
                <span className="machine-kpi-label">Administradores</span>
              </div>
            </div>
          </div>

          {/* Filtros */}
          <div className="machines-filters-bar">
            <div className="filter-search-box">
              <Search size={16} className="filter-search-icon" />
              <input
                type="text"
                placeholder="Buscar usuario por nombre, email o teléfono..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>

            <div className="filters-group">
              <select
                className="filter-select"
                value={roleFilter}
                onChange={(e) => setRoleFilter(e.target.value)}
              >
                <option value="todos">Todos los roles</option>
                <option value="operario">Operarios</option>
                <option value="transportador">Transportadores</option>
                <option value="administrador">Administradores</option>
              </select>

              <div className="view-mode-toggle">
                <button
                  type="button"
                  className={`view-btn ${viewMode === 'table' ? 'active' : ''}`}
                  onClick={() => setViewMode('table')}
                  title="Vista en tabla"
                >
                  <List size={16} />
                </button>
                <button
                  type="button"
                  className={`view-btn ${viewMode === 'grid' ? 'active' : ''}`}
                  onClick={() => setViewMode('grid')}
                  title="Vista en tarjetas"
                >
                  <LayoutGrid size={16} />
                </button>
              </div>
            </div>
          </div>

          {/* Vista Tabla o Tarjetas */}
          {filteredUsers.length === 0 ? (
            <div className="empty-machines-banner">
              <Users size={36} />
              <span className="empty-machines-title">No se encontraron usuarios</span>
              <p className="empty-machines-sub">Ajusta los filtros de búsqueda o registra un nuevo usuario.</p>
            </div>
          ) : viewMode === 'table' ? (
            <div className="card-section" style={{ padding: '0', overflow: 'hidden' }}>
              <div className="table-scroll-wrapper">
                <table className="modern-data-table">
                  <thead>
                    <tr>
                      <th>Usuario</th>
                      <th>Rol Oficial</th>
                      <th>Contacto</th>
                      <th>Fecha de Ingreso</th>
                      <th style={{ textAlign: 'right' }}>Acciones</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredUsers.map((u) => {
                      const roleName = getRoleName(u);
                      const isCurrentUser = currentUser?.id === u.id;

                      return (
                        <tr key={u.id}>
                          <td>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                              <div className={`user-avatar-circle role-${roleName.toLowerCase()}`}>
                                {getInitials(u.name)}
                              </div>
                              <div>
                                <span style={{ fontWeight: 700, color: '#0F172A', display: 'block' }}>
                                  {u.name} {isCurrentUser && <span style={{ fontSize: '10px', color: '#0284C7' }}>(Tú)</span>}
                                </span>
                                <span style={{ fontSize: '12px', color: '#64748B' }}>
                                  <Mail size={11} style={{ display: 'inline', marginRight: '3px' }} />
                                  {u.email}
                                </span>
                              </div>
                            </div>
                          </td>
                          <td>
                            <span className={`user-role-badge ${roleName.toLowerCase()}`}>
                              <Shield size={11} /> {roleName}
                            </span>
                          </td>
                          <td>
                            <span style={{ fontSize: '12px', color: '#475569' }}>
                              <Phone size={11} style={{ display: 'inline', marginRight: '3px' }} />
                              {u.phone || 'Sin registrar'}
                            </span>
                          </td>
                          <td>
                            <span style={{ fontSize: '12px', color: '#64748B' }}>
                              {u.createdAt ? new Date(u.createdAt).toLocaleDateString('es-CO') : 'Reciente'}
                            </span>
                          </td>
                          <td>
                            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: '6px' }}>
                              <button
                                type="button"
                                className="btn-card-edit"
                                onClick={() => handleOpenEdit(u)}
                                title="Editar usuario"
                                style={{ padding: '6px 8px' }}
                              >
                                <Edit size={14} />
                              </button>

                              {!isCurrentUser && (
                                <button
                                  type="button"
                                  className="btn-card-delete"
                                  onClick={() => setDeletingUser(u)}
                                  title="Eliminar usuario"
                                  style={{ padding: '6px 8px' }}
                                >
                                  <Trash2 size={14} />
                                </button>
                              )}
                            </div>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          ) : (
            <div className="machines-card-grid">
              {filteredUsers.map((u) => {
                const roleName = getRoleName(u);
                const isCurrentUser = currentUser?.id === u.id;

                return (
                  <div key={u.id} className="machine-card-item" style={{ padding: '20px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '14px', marginBottom: '14px' }}>
                      <div className={`user-avatar-circle role-${roleName.toLowerCase()}`} style={{ width: '48px', height: '48px', fontSize: '16px' }}>
                        {getInitials(u.name)}
                      </div>
                      <div>
                        <h3 style={{ fontSize: '15px', fontWeight: 700, color: '#0F172A', margin: 0 }}>
                          {u.name}
                        </h3>
                        <span className={`user-role-badge ${roleName.toLowerCase()}`} style={{ marginTop: '4px' }}>
                          <Shield size={11} /> {roleName}
                        </span>
                      </div>
                    </div>

                    <div className="card-meta-list" style={{ borderTop: '1px solid #F1F5F9', paddingTop: '12px' }}>
                      <div className="card-meta-row">
                        <span className="card-meta-label">Correo:</span>
                        <span className="card-meta-val">{u.email}</span>
                      </div>
                      <div className="card-meta-row">
                        <span className="card-meta-label">Teléfono:</span>
                        <span className="card-meta-val">{u.phone || 'Sin registrar'}</span>
                      </div>
                    </div>

                    <div className="card-action-footer mt-3">
                      <div className="card-actions-row">
                        <button
                          type="button"
                          className="btn-card-edit"
                          style={{ flex: 1, padding: '7px 12px' }}
                          onClick={() => handleOpenEdit(u)}
                        >
                          <Edit size={14} /> Editar
                        </button>
                        {!isCurrentUser && (
                          <button
                            type="button"
                            className="btn-card-delete"
                            onClick={() => setDeletingUser(u)}
                            title="Eliminar usuario"
                          >
                            <Trash2 size={14} />
                          </button>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </main>
      </div>

      {/* Modal Crear Usuario */}
      {createModalOpen && (
        <div className="modal-backdrop" onClick={() => !createLoading && setCreateModalOpen(false)}>
          <div className="modal-content register-machine-modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <div className="modal-header-title">
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <div className="register-modal-icon-badge">
                    <UserPlus size={20} />
                  </div>
                  <div>
                    <h3>Registrar Nuevo Usuario</h3>
                    <span className="modal-header-sub">Alta de cuenta oficial y asignación de rol</span>
                  </div>
                </div>
              </div>
              <button className="btn-close" onClick={() => setCreateModalOpen(false)} disabled={createLoading}>
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleCreateUser}>
              <div className="modal-body">
                {createError && (
                  <div className="register-alert error">
                    <AlertCircle size={18} />
                    <span>{createError}</span>
                  </div>
                )}

                <div className="form-grid">
                  <div className="form-group">
                    <label className="form-label">Nombre Completo <span className="req-star">*</span></label>
                    <input
                      type="text"
                      className="form-input"
                      placeholder="Ej: Carlos Mendoza"
                      value={newName}
                      onChange={(e) => setNewName(e.target.value)}
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Correo Electrónico <span className="req-star">*</span></label>
                    <input
                      type="email"
                      className="form-input"
                      placeholder="ejemplo@maquitrace.com"
                      value={newEmail}
                      onChange={(e) => setNewEmail(e.target.value)}
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Rol Oficial <span className="req-star">*</span></label>
                    <select
                      className="form-select"
                      value={newRoleId}
                      onChange={(e) => setNewRoleId(e.target.value)}
                      required
                    >
                      {roles.map((r) => (
                        <option key={r.id} value={r.id}>
                          {r.name.toUpperCase()}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Teléfono Móvil</label>
                    <input
                      type="text"
                      className="form-input"
                      placeholder="Ej: +57 310 123 4567"
                      value={newPhone}
                      onChange={(e) => setNewPhone(e.target.value)}
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Contraseña de Acceso</label>
                    <input
                      type="password"
                      className="form-input"
                      placeholder="Por defecto: MaquiTrace2026!"
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                    />
                    <span className="form-help-text">Si se deja en blanco se asignará la contraseña temporal MaquiTrace2026!</span>
                  </div>
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn-secondary" onClick={() => setCreateModalOpen(false)} disabled={createLoading}>
                  Cancelar
                </button>
                <button type="submit" className="btn-primary-register" disabled={createLoading}>
                  {createLoading ? (
                    <>
                      <Loader2 size={16} className="spinner" />
                      <span>Registrando...</span>
                    </>
                  ) : (
                    <>
                      <UserPlus size={16} />
                      <span>Crear Usuario</span>
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Editar Usuario */}
      {editingUser && (
        <div className="modal-backdrop" onClick={() => !editLoading && setEditingUser(null)}>
          <div className="modal-content register-machine-modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <div className="modal-header-title">
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <div className="register-modal-icon-badge">
                    <Edit size={20} />
                  </div>
                  <div>
                    <h3>Editar Usuario</h3>
                    <span className="modal-header-sub">{editingUser.name} · {editingUser.email}</span>
                  </div>
                </div>
              </div>
              <button className="btn-close" onClick={() => setEditingUser(null)} disabled={editLoading}>
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleUpdateUser}>
              <div className="modal-body">
                {editError && (
                  <div className="register-alert error">
                    <AlertCircle size={18} />
                    <span>{editError}</span>
                  </div>
                )}

                <div className="form-grid">
                  <div className="form-group">
                    <label className="form-label">Nombre Completo <span className="req-star">*</span></label>
                    <input
                      type="text"
                      className="form-input"
                      value={editName}
                      onChange={(e) => setEditName(e.target.value)}
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Correo Electrónico <span className="req-star">*</span></label>
                    <input
                      type="email"
                      className="form-input"
                      value={editEmail}
                      onChange={(e) => setEditEmail(e.target.value)}
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Rol Oficial <span className="req-star">*</span></label>
                    <select
                      className="form-select"
                      value={editRoleId}
                      onChange={(e) => setEditRoleId(e.target.value)}
                      required
                    >
                      {roles.map((r) => (
                        <option key={r.id} value={r.id}>
                          {r.name.toUpperCase()}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Teléfono Móvil</label>
                    <input
                      type="text"
                      className="form-input"
                      value={editPhone}
                      onChange={(e) => setEditPhone(e.target.value)}
                    />
                  </div>
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn-secondary" onClick={() => setEditingUser(null)} disabled={editLoading}>
                  Cancelar
                </button>
                <button type="submit" className="btn-primary-register" disabled={editLoading}>
                  {editLoading ? (
                    <>
                      <Loader2 size={16} className="spinner" />
                      <span>Guardando...</span>
                    </>
                  ) : (
                    <>
                      <Check size={16} />
                      <span>Actualizar Datos</span>
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Confirmar Eliminación */}
      {deletingUser && (
        <div className="modal-backdrop" onClick={() => !deleteLoading && setDeletingUser(null)}>
          <div className="modal-content delete-modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="delete-modal-body">
              <div className="delete-modal-icon-box">
                <Trash2 size={28} />
              </div>
              <h3 className="delete-modal-title">¿Eliminar Usuario?</h3>
              <p className="delete-modal-desc">
                Esta acción removerá el acceso al sistema de MaquiTrace para esta cuenta.
              </p>
              <div className="delete-modal-machine-tag">
                {deletingUser.name} · {deletingUser.email}
              </div>
            </div>
            <div className="modal-footer" style={{ justifyContent: 'center', gap: '12px' }}>
              <button
                type="button"
                className="btn-secondary"
                onClick={() => setDeletingUser(null)}
                disabled={deleteLoading}
              >
                Cancelar
              </button>
              <button
                type="button"
                className="btn-danger-confirm"
                onClick={handleConfirmDelete}
                disabled={deleteLoading}
              >
                {deleteLoading ? (
                  <>
                    <Loader2 size={15} className="spinner" />
                    <span>Eliminando...</span>
                  </>
                ) : (
                  <>
                    <Trash2 size={15} />
                    <span>Sí, Eliminar Usuario</span>
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default UsersPage;
