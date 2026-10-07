import React from 'react';
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
  const mainNavItems = [
    { id: 'inicio', label: 'Inicio', icon: LayoutDashboard },
    { id: 'maquinas', label: 'Máquinas', icon: Truck },
    { id: 'alistamientos', label: 'Alistamientos', icon: ClipboardCheck },
    { id: 'seguimiento', label: 'Seguimiento', icon: Navigation },
    { id: 'usuarios', label: 'Usuarios', icon: Users },
    { id: 'evidencias', label: 'Evidencias e informes', icon: FileText },
  ];

  const secondaryNavItems = [
    { id: 'configuracion', label: 'Configuración', icon: Settings },
    { id: 'ayuda', label: 'Ayuda', icon: HelpCircle },
  ];

  const handleItemClick = (id: string) => {
    onSelectTab(id);
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
            const isActive = currentTab === item.id;
            return (
              <button
                key={item.id}
                type="button"
                className={`sidebar-item ${isActive ? 'active' : ''}`}
                onClick={() => handleItemClick(item.id)}
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
                onClick={() => handleItemClick(item.id)}
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
