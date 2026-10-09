import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import {
  LayoutDashboard,
  Truck,
  ClipboardCheck,
  Navigation,
  Users,
  FileText,
  Settings,
  HelpCircle,
} from 'lucide-react';
import logoImg from '../assets/branding/logo.png';

interface SidebarProps {
  currentTab: string;
  onSelectTab: (tab: string) => void;
  isOpen: boolean;
  onCloseMobile?: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  currentTab,
  onSelectTab,
  isOpen,
  onCloseMobile,
}) => {
  const navigate = useNavigate();
  const location = useLocation();

  const mainNavItems = [
    { id: 'inicio', label: 'Inicio', icon: LayoutDashboard, path: '/dashboard' },
    { id: 'maquinas', label: 'Máquinas', icon: Truck, path: '/maquinas' },
    { id: 'alistamientos', label: 'Alistamientos', icon: ClipboardCheck, path: '/dashboard' },
    { id: 'seguimiento', label: 'Seguimiento', icon: Navigation, path: '/dashboard' },
    { id: 'usuarios', label: 'Usuarios', icon: Users, path: '/dashboard' },
    { id: 'evidencias', label: 'Evidencias e informes', icon: FileText, path: '/dashboard' },
  ];

  const secondaryNavItems = [
    { id: 'configuracion', label: 'Configuración', icon: Settings, path: '/dashboard' },
    { id: 'ayuda', label: 'Ayuda', icon: HelpCircle, path: '/dashboard' },
  ];

  const handleItemClick = (id: string, path: string) => {
    onSelectTab(id);
    if (location.pathname !== path) {
      navigate(path);
    }
    if (onCloseMobile) onCloseMobile();
  };

  return (
    <aside className={`app-sidebar ${isOpen ? 'open' : ''}`}>
      <div>
        {/* Cabecera con Logo oficial */}
        <div className="sidebar-header">
          <img src={logoImg} alt="MaquiTrace" className="sidebar-logo" />
        </div>

        {/* Navegación Principal */}
        <nav className="sidebar-nav">
          {mainNavItems.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path;
            return (
              <button
                key={item.id}
                type="button"
                className={`sidebar-item ${isActive ? 'active' : ''}`}
                onClick={() => handleItemClick(item.id, item.path)}
              >
                <span className="sidebar-item-icon">
                  <Icon size={19} />
                </span>
                <span>{item.label}</span>
              </button>
            );
          })}
        </nav>
      </div>

      <div>
        {/* Navegación Secundaria (Configuración & Ayuda) */}
        <div className="sidebar-footer-nav">
          {secondaryNavItems.map((item) => {
            const Icon = item.icon;
            const isActive = currentTab === item.id;
            return (
              <button
                key={item.id}
                type="button"
                className={`sidebar-item ${isActive ? 'active' : ''}`}
                onClick={() => handleItemClick(item.id, item.path)}
              >
                <span className="sidebar-item-icon">
                  <Icon size={19} />
                </span>
                <span>{item.label}</span>
              </button>
            );
          })}
        </div>

        {/* Tarjeta de Branding Inferior */}
        <div className="sidebar-bottom-badge">
          <div className="bottom-badge-title">MaquiTrace</div>
          <div className="bottom-badge-desc">Trazabilidad que genera confianza.</div>
        </div>
      </div>
    </aside>
  );
};
