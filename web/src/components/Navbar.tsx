import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { Search, Bell, ChevronDown, LogOut, Menu } from 'lucide-react';

interface NavbarProps {
  onToggleSidebar: () => void;
  searchValue: string;
  onSearchChange: (value: string) => void;
}

export const Navbar: React.FC<NavbarProps> = ({
  onToggleSidebar,
  searchValue,
  onSearchChange,
}) => {
  const { user, logout } = useAuth();
  const [dropdownOpen, setDropdownOpen] = useState(false);

  const getRoleDisplayName = (role: any) => {
    const roleStr = typeof role === 'object' ? role?.name : role;
    switch (roleStr?.toUpperCase()) {
      case 'ADMIN':
      case 'ADMINISTRADOR':
        return 'Administrador';
      case 'SUPERVISOR':
        return 'Supervisor';
      case 'OPERATOR':
      case 'OPERARIO':
        return 'Operario';
      case 'TRANSPORTADOR':
        return 'Transportador';
      default:
        return 'Administrador';
    }
  };

  const displayName = user?.name || 'Administrador';
  const roleName = getRoleDisplayName(user?.role);

  return (
    <header className="top-navbar">
      <div className="navbar-left">
        <button
          type="button"
          className="btn-toggle-sidebar"
          onClick={onToggleSidebar}
          title="Alternar menú"
        >
          <Menu size={20} />
        </button>

        {/* Buscador idéntico al PDF */}
        <div className="navbar-search-box">
          <Search size={16} className="search-field-icon" />
          <input
            type="text"
            className="navbar-search-input"
            placeholder="Buscar máquina, serial, operario..."
            value={searchValue}
            onChange={(e) => onSearchChange(e.target.value)}
          />
        </div>
      </div>

      <div className="navbar-right">
        {/* Campana de Notificaciones con punto rojo */}
        <button type="button" className="btn-nav-icon" title="Notificaciones">
          <Bell size={18} />
          <span className="nav-icon-badge"></span>
        </button>

        {/* Perfil de Usuario con Menú Desplegable */}
        <div style={{ position: 'relative' }}>
          <button
            type="button"
            className="user-menu-trigger"
            onClick={() => setDropdownOpen(!dropdownOpen)}
          >
            <div className="user-avatar-circle">
              {displayName.charAt(0).toUpperCase()}
            </div>
            <div className="user-text-info">
              <span className="user-name-title">{displayName}</span>
              <span className="user-role-subtitle">{roleName} · Empresa</span>
            </div>
            <ChevronDown size={14} className="caret-icon" />
          </button>

          {dropdownOpen && (
            <div className="user-dropdown-card">
              <div className="dropdown-user-header">
                <span className="dropdown-user-name">{displayName}</span>
                <span className="dropdown-user-email">{user?.email || 'admin@maquitrace.com'}</span>
              </div>
              <button
                type="button"
                className="dropdown-item-btn"
                onClick={logout}
              >
                <LogOut size={16} />
                <span>Cerrar sesión</span>
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
};
