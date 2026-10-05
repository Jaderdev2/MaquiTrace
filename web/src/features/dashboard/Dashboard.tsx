import React, { useState, useEffect } from 'react';
import { useAuth } from '../../context/AuthContext';
import { fetchMachinesApi } from '../../services/api';
import type { Machine, MachineStatus } from '../../types';
import { MachineDetailModal } from '../../components/MachineDetailModal';
import {
  Truck,
  LogOut,
  Search,
  Filter,
  RefreshCw,
  Wrench,
  Clock,
  CheckCircle2,
  MapPin,
  Eye,
  Server,
  Layers,
  Activity,
  Loader2,
} from 'lucide-react';

export const Dashboard: React.FC = () => {
  const { user, logout, token } = useAuth();
  const [machines, setMachines] = useState<Machine[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [isMock, setIsMock] = useState<boolean>(false);
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<string>('todos');
  const [categoryFilter, setCategoryFilter] = useState<string>('todos');
  const [selectedMachine, setSelectedMachine] = useState<Machine | null>(null);

  const loadMachines = async () => {
    if (!token) return;
    setLoading(true);
    try {
      const result = await fetchMachinesApi(token);
      setMachines(result.data);
      setIsMock(result.isMock);
    } catch (err) {
      console.error('Error fetching machines:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadMachines();
  }, [token]);

  // Derived KPIs
  const totalCount = machines.length;
  const inProcessCount = machines.filter((m) => m.status === 'en_proceso').length;
  const inTransitCount = machines.filter((m) => m.status === 'en_transito').length;
  const completedCount = machines.filter((m) => m.status === 'completada' || m.status === 'entregada').length;
  const pendingCount = machines.filter((m) => m.status === 'pendiente').length;

  // Filtered List
  const filteredMachines = machines.filter((m) => {
    const matchesSearch =
      m.serial.toLowerCase().includes(searchTerm.toLowerCase()) ||
      m.model.toLowerCase().includes(searchTerm.toLowerCase()) ||
      m.category.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesStatus = statusFilter === 'todos' || m.status === statusFilter;
    const matchesCategory = categoryFilter === 'todos' || m.category === categoryFilter;

    return matchesSearch && matchesStatus && matchesCategory;
  });

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
        return roleStr || 'Usuario';
    }
  };

  const getStatusBadge = (status: MachineStatus) => {
    switch (status) {
      case 'pendiente':
        return <span className="badge badge-amber"><Clock size={12} /> Pendiente</span>;
      case 'en_proceso':
        return <span className="badge badge-blue"><Wrench size={12} /> En Alistamiento</span>;
      case 'completada':
        return <span className="badge badge-emerald"><CheckCircle2 size={12} /> Listo</span>;
      case 'en_transito':
        return <span className="badge badge-purple"><MapPin size={12} /> En Tránsito GPS</span>;
      case 'entregada':
        return <span className="badge badge-teal"><CheckCircle2 size={12} /> Entregada</span>;
      default:
        return <span className="badge">{status}</span>;
    }
  };

  const renderPhaseTracker = (machine: Machine) => {
    const phases = machine.phases || [];
    const getPhaseDotClass = (pName: string) => {
      const ph = phases.find((p) => p.name === pName);
      if (!ph) return 'dot-pending';
      if (ph.status === 'completada') return 'dot-completed';
      if (ph.status === 'en_proceso') return 'dot-active';
      return 'dot-pending';
    };

    return (
      <div className="phase-tracker">
        <div className={`phase-step ${getPhaseDotClass('ensamblaje')}`} title="Fase 1: Ensamblaje">
          <span>Ensamblaje</span>
        </div>
        <div className="phase-line"></div>
        <div className={`phase-step ${getPhaseDotClass('pintura')}`} title="Fase 2: Pintura">
          <span>Pintura</span>
        </div>
        <div className="phase-line"></div>
        <div className={`phase-step ${getPhaseDotClass('lavado')}`} title="Fase 3: Lavado">
          <span>Lavado</span>
        </div>
      </div>
    );
  };

  return (
    <div className="dashboard-layout">
      {/* Top Navbar Header */}
      <header className="navbar">
        <div className="navbar-brand">
          <div className="logo-icon-bg shadow-glow">
            <Truck className="logo-icon" size={24} />
          </div>
          <div>
            <h1 className="navbar-title">Maqui<span className="text-secondary">Trace</span></h1>
            <span className="navbar-subtitle">Panel de Supervisión y Trazabilidad</span>
          </div>
        </div>

        <div className="navbar-right">
          <div className={`server-status-pill ${isMock ? 'warning' : 'success'}`}>
            <Server size={14} />
            <span>{isMock ? 'Modo Demostración' : 'API NestJS Conectada'}</span>
          </div>

          <div className="user-profile-badge">
            <div className="user-avatar">
              {user?.name?.charAt(0) || 'U'}
            </div>
            <div className="user-info">
              <span className="user-name">{user?.name}</span>
              <span className="user-role-tag">{getRoleDisplayName(user?.role)}</span>
            </div>
          </div>

          <button className="btn-logout" onClick={logout} title="Cerrar Sesión">
            <LogOut size={18} />
            <span>Salir</span>
          </button>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="dashboard-content">
        {/* Banner Alert for Backend State */}
        {isMock && (
          <div className="info-banner">
            <Activity size={18} className="banner-icon" />
            <div>
              <strong>Visualizando Maquinaria en Modo Demostración:</strong> El servidor local NestJS en <code>http://localhost:3000</code> no respondió en este instante, por lo que se han cargado datos simulados e interactivos de prueba.
            </div>
          </div>
        )}

        {/* Metric Cards / KPI Summary */}
        <section className="kpi-grid">
          <div className="kpi-card card-total">
            <div className="kpi-icon"><Layers size={22} /></div>
            <div className="kpi-body">
              <span className="kpi-title">Total Maquinaria</span>
              <span className="kpi-value">{totalCount}</span>
            </div>
          </div>

          <div className="kpi-card card-process">
            <div className="kpi-icon"><Wrench size={22} /></div>
            <div className="kpi-body">
              <span className="kpi-title">En Alistamiento</span>
              <span className="kpi-value">{inProcessCount}</span>
            </div>
          </div>

          <div className="kpi-card card-transit">
            <div className="kpi-icon"><MapPin size={22} /></div>
            <div className="kpi-body">
              <span className="kpi-title">En Tránsito (GPS)</span>
              <span className="kpi-value">{inTransitCount}</span>
            </div>
          </div>

          <div className="kpi-card card-completed">
            <div className="kpi-icon"><CheckCircle2 size={22} /></div>
            <div className="kpi-body">
              <span className="kpi-title">Listas / Entregadas</span>
              <span className="kpi-value">{completedCount}</span>
            </div>
          </div>

          <div className="kpi-card card-pending">
            <div className="kpi-icon"><Clock size={22} /></div>
            <div className="kpi-body">
              <span className="kpi-title">Pendientes</span>
              <span className="kpi-value">{pendingCount}</span>
            </div>
          </div>
        </section>

        {/* Toolbar & Filter Options */}
        <section className="toolbar-card">
          <div className="search-box">
            <Search size={18} className="search-icon" />
            <input
              type="text"
              placeholder="Buscar por código serial, modelo o categoría..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>

          <div className="filter-group">
            <div className="filter-item">
              <Filter size={16} />
              <span>Estado:</span>
              <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
                <option value="todos">Todos los estados</option>
                <option value="pendiente">Pendiente</option>
                <option value="en_proceso">En Alistamiento</option>
                <option value="completada">Completada</option>
                <option value="en_transito">En Tránsito</option>
                <option value="entregada">Entregada</option>
              </select>
            </div>

            <div className="filter-item">
              <span>Categoría:</span>
              <select value={categoryFilter} onChange={(e) => setCategoryFilter(e.target.value)}>
                <option value="todos">Todas las categorías</option>
                <option value="Excavadora">Excavadoras</option>
                <option value="Retroexcavadora">Retroexcavadoras</option>
                <option value="Cargador Frontal">Cargadores Frontales</option>
                <option value="Bulldozer">Bulldozers</option>
                <option value="Motoniveladora">Motoniveladoras</option>
              </select>
            </div>

            <button className="btn-refresh" onClick={loadMachines} title="Actualizar datos">
              <RefreshCw size={16} className={loading ? 'spinner' : ''} />
            </button>
          </div>
        </section>

        {/* Machinery Data Table */}
        <section className="table-card">
          <div className="table-header-title">
            <h3>Registro e Historial de Maquinaria</h3>
            <span className="table-count">Mostrando {filteredMachines.length} de {totalCount} máquinas</span>
          </div>

          {loading ? (
            <div className="table-loading-state">
              <Loader2 size={32} className="spinner text-primary" />
              <p>Cargando información de maquinaria...</p>
            </div>
          ) : filteredMachines.length === 0 ? (
            <div className="table-empty-state">
              <Truck size={40} className="empty-icon" />
              <h4>No se encontraron maquinarias</h4>
              <p>Intenta cambiar los filtros de búsqueda o el estado seleccionado.</p>
            </div>
          ) : (
            <div className="table-responsive">
              <table className="machines-table">
                <thead>
                  <tr>
                    <th>Código Serial</th>
                    <th>Modelo & Categoría</th>
                    <th>Estado General</th>
                    <th>Fases de Alistamiento</th>
                    <th>Fecha de Registro</th>
                    <th className="text-right">Acciones</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredMachines.map((machine) => (
                    <tr key={machine.id}>
                      <td>
                        <span className="serial-badge">{machine.serial}</span>
                      </td>
                      <td>
                        <div className="machine-name-cell">
                          <strong className="machine-model">{machine.model}</strong>
                          <span className="machine-category">{machine.category}</span>
                        </div>
                      </td>
                      <td>{getStatusBadge(machine.status)}</td>
                      <td>{renderPhaseTracker(machine)}</td>
                      <td>
                        <span className="date-cell">
                          {machine.createdAt ? new Date(machine.createdAt).toLocaleDateString('es-ES') : 'Reciente'}
                        </span>
                      </td>
                      <td className="text-right">
                        <button
                          className="btn-action"
                          onClick={() => setSelectedMachine(machine)}
                        >
                          <Eye size={16} />
                          <span>Ver Detalle</span>
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </section>
      </main>

      {/* Detail Modal */}
      <MachineDetailModal
        machine={selectedMachine}
        onClose={() => setSelectedMachine(null)}
      />
    </div>
  );
};
