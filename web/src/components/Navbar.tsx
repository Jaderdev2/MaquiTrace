import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Search, ChevronDown, LogOut, Menu, X, ShieldCheck } from 'lucide-react';
import '../styles/navbar.css';

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
  const navigate = useNavigate();
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

        {/* Indicador de estado del sistema (En línea / OCI) */}
        <div className="navbar-status-pill" title="Conexión en tiempo real con Oracle Cloud Infrastructure">
          <span className="navbar-status-dot" />
          <span className="navbar-status-text">En línea · OCI Conectado</span>
        </div>

        {/* Buscador interactivo y fluido */}
        <div className="navbar-search-box">
          <Search size={16} className="search-field-icon" />
          <input
            type="text"
            className="navbar-search-input"
            placeholder="Buscar máquina, serial, operario..."
            value={searchValue}
            onChange={(e) => onSearchChange(e.target.value)}
          />
          {searchValue && (
            <button
              type="button"
              className="search-clear-btn"
              onClick={() => onSearchChange('')}
              title="Limpiar búsqueda"
            >
              <X size={14} />
            </button>
          )}
        </div>
      </div>

      <div className="navbar-right">
        {/* Perfil de Usuario con Menú Desplegable Reorganizado */}
        <div className="user-menu-wrapper" style={{ position: 'relative' }}>
          <button
            type="button"
            className={`user-menu-trigger ${dropdownOpen ? 'active' : ''}`}
            onClick={() => setDropdownOpen(!dropdownOpen)}
            aria-expanded={dropdownOpen}
          >
            <div className="user-avatar-circle">
              {displayName.charAt(0).toUpperCase()}
              <span className="user-online-badge" />
            </div>
            <div className="user-text-info">
              <span className="user-name-title">{displayName}</span>
              <span className="user-role-subtitle">{roleName} · Empresa</span>
            </div>
            <ChevronDown size={14} className={`caret-icon ${dropdownOpen ? 'open' : ''}`} />
          </button>

          {dropdownOpen && (
            <div className="user-dropdown-card">
              <div className="dropdown-user-header">
                <div className="dropdown-user-top">
                  <span className="dropdown-user-name">{displayName}</span>
                  <span className="dropdown-role-pill">
                    <ShieldCheck size={11} /> {roleName}
                  </span>
                </div>
                <span className="dropdown-user-email">{user?.email || 'admin@maquitrace.com'}</span>
              </div>
              <div className="dropdown-divider" />
              <button
                type="button"
                className="dropdown-item-btn"
                onClick={() => {
                  setDropdownOpen(false);
                  logout();
                  navigate('/login', { replace: true });
                }}
              >
                <LogOut size={15} />
                <span>Cerrar sesión</span>
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
};
