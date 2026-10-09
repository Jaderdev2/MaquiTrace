import React, { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../../context/AuthContext';
import { fetchMachinesApi } from '../../services/api';
import type { Machine } from '../../types';
import { Sidebar } from '../../components/Sidebar';
import { Navbar } from '../../components/Navbar';
import { RegisterMachineModal } from '../../components/RegisterMachineModal';
import { MachineDetailModal } from '../../components/MachineDetailModal';
import { getMachineProfileImage } from '../../utils/evidence';
import {
  Truck,
  Plus,
  Search,
  RefreshCw,
  LayoutGrid,
  List,
  Camera,
  AlertCircle,
  Eye,
  CheckCircle2,
  Clock,
  Layers,
  Wrench,
} from 'lucide-react';
import '../../styles/machines.css';

export const MachinesPage: React.FC = () => {
  const { token } = useAuth();
  const [machines, setMachines] = useState<Machine[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [sidebarOpen, setSidebarOpen] = useState<boolean>(false);
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [categoryFilter, setCategoryFilter] = useState<string>('todas');
  const [statusFilter, setStatusFilter] = useState<string>('todos');
  const [viewMode, setViewMode] = useState<'grid' | 'table'>('grid');
  const [selectedMachine, setSelectedMachine] = useState<Machine | null>(null);
  const [registerModalOpen, setRegisterModalOpen] = useState<boolean>(false);
  const [successBanner, setSuccessBanner] = useState<string | null>(null);

  // Carga de maquinaria desde el backend
  const loadMachines = useCallback(async () => {
    if (!token) return;
    try {
      setLoading(true);
      setError(null);
      const data = await fetchMachinesApi(token);
      setMachines(data);
    } catch (err: any) {
      setError(err.message || 'Error al conectar con el servidor.');
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    loadMachines();
  }, [loadMachines]);

  // Manejo de nueva máquina registrada por el Admin
  const handleMachineCreated = (newMachine: Machine) => {
    setMachines((prev) => [newMachine, ...prev]);
    setSuccessBanner(`¡La maquinaria ${newMachine.model} (${newMachine.serial}) fue registrada con éxito!`);
    setTimeout(() => setSuccessBanner(null), 5000);
  };

  // Listado de categorías únicas para el filtro
  const categoriesList = Array.from(
    new Set(machines.map((m) => m.category).filter(Boolean))
  );

  // Filtro reactivo
  const filteredMachines = machines.filter((m) => {
    if (categoryFilter !== 'todas' && m.category !== categoryFilter) {
      return false;
    }
    if (statusFilter !== 'todos' && m.status !== statusFilter) {
      return false;
    }
    if (!searchTerm.trim()) return true;
    const q = searchTerm.toLowerCase();
    return (
      m.model.toLowerCase().includes(q) ||
      m.serial.toLowerCase().includes(q) ||
      (m.category && m.category.toLowerCase().includes(q))
    );
  });

  // Métricas
  const totalCount = machines.length;
  const inProcessCount = machines.filter((m) => m.status === 'en_proceso').length;
  const pendingCount = machines.filter((m) => m.status === 'pendiente').length;
  const completedCount = machines.filter((m) => m.status === 'completada').length;
  const inTransitCount = machines.filter((m) => m.status === 'en_transito').length;

  const getStatusBadge = (status: string) => {
    switch (status.toLowerCase()) {
      case 'en_proceso':
        return { label: 'En proceso', className: 'pill-status-process' };
      case 'completada':
        return { label: 'Completada', className: 'pill-status-ready' };
      case 'en_transito':
        return { label: 'En tránsito', className: 'pill-status-transit' };
      case 'pendiente':
        return { label: 'Pendiente', className: 'pill-status-pending' };
      case 'entregada':
        return { label: 'Entregada', className: 'pill-status-ready' };
      default:
        return { label: status, className: 'pill-status-process' };
    }
  };

  return (
    <div className="machines-page-layout">
      {/* Barra lateral */}
      <Sidebar
        currentTab="maquinas"
        onSelectTab={() => {}}
        isOpen={sidebarOpen}
        onCloseMobile={() => setSidebarOpen(false)}
      />

      {/* Contenedor principal */}
      <div className="machines-main-wrapper">
        <Navbar
          onToggleSidebar={() => setSidebarOpen((prev) => !prev)}
          searchValue={searchTerm}
          onSearchChange={setSearchTerm}
        />

        <main className="machines-content-area">
          {/* Cabecera y botón principal de registro */}
          <div className="machines-header-row">
            <div className="machines-title-box">
              <h1>Parque y Gestión de Maquinaria</h1>
              <span className="machines-title-sub">
                Control de flota, registro oficial de nuevos equipos y consulta de evidencias fotográficas en Oracle Cloud.
              </span>
            </div>

            <div className="machines-actions-group">
              <button
                type="button"
                className="btn-refresh-data"
                onClick={loadMachines}
                disabled={loading}
                title="Actualizar datos desde el servidor"
              >
                <RefreshCw size={15} className={loading ? 'spinner' : ''} />
                <span>Actualizar</span>
              </button>

              <button
                type="button"
                className="btn-create-machine"
                onClick={() => setRegisterModalOpen(true)}
              >
                <Plus size={18} />
                <span>Registrar Maquinaria</span>
              </button>
            </div>
          </div>

          {/* Banner de éxito al registrar */}
          {successBanner && (
            <div className="register-alert success">
              <CheckCircle2 size={18} />
              <span>{successBanner}</span>
            </div>
          )}

          {/* Error de conexión */}
          {error && (
            <div className="register-alert error">
              <AlertCircle size={18} />
              <span>{error}</span>
            </div>
          )}

          {/* Tarjetas de Métricas KPI */}
          <div className="machines-kpi-grid">
            <div className="machine-kpi-card">
              <div className="machine-kpi-icon icon-blue">
                <Truck size={22} />
              </div>
              <div className="machine-kpi-data">
                <span className="machine-kpi-num">{loading ? '...' : totalCount}</span>
                <span className="machine-kpi-label">Total Maquinaria Registrada</span>
              </div>
            </div>

            <div className="machine-kpi-card">
              <div className="machine-kpi-icon icon-blue">
                <Wrench size={22} />
              </div>
              <div className="machine-kpi-data">
                <span className="machine-kpi-num">{loading ? '...' : inProcessCount}</span>
                <span className="machine-kpi-label">En Alistamiento Activo</span>
              </div>
            </div>

            <div className="machine-kpi-card">
              <div className="machine-kpi-icon icon-amber">
                <Clock size={22} />
              </div>
              <div className="machine-kpi-data">
                <span className="machine-kpi-num">{loading ? '...' : pendingCount}</span>
                <span className="machine-kpi-label">Pendientes de Inicio</span>
              </div>
            </div>

            <div className="machine-kpi-card">
              <div className="machine-kpi-icon icon-emerald">
                <CheckCircle2 size={22} />
              </div>
              <div className="machine-kpi-data">
                <span className="machine-kpi-num">{loading ? '...' : completedCount}</span>
                <span className="machine-kpi-label">Listas / Inspeccionadas</span>
              </div>
            </div>

            <div className="machine-kpi-card">
              <div className="machine-kpi-icon icon-purple">
                <Layers size={22} />
              </div>
              <div className="machine-kpi-data">
                <span className="machine-kpi-num">{loading ? '...' : inTransitCount}</span>
                <span className="machine-kpi-label">En Tránsito (Transporte)</span>
              </div>
            </div>
          </div>

          {/* Barra de Filtros y Controles */}
          <div className="machines-filters-bar">
            <div className="filter-search-box">
              <Search size={16} className="filter-search-icon" />
              <input
                type="text"
                placeholder="Buscar por modelo, serial o categoría..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>

            <div className="filters-group">
              <select
                className="filter-select"
                value={categoryFilter}
                onChange={(e) => setCategoryFilter(e.target.value)}
              >
                <option value="todas">Todas las categorías</option>
                {categoriesList.map((cat) => (
                  <option key={cat} value={cat}>
                    {cat}
                  </option>
                ))}
              </select>

              <select
                className="filter-select"
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
              >
                <option value="todos">Todos los estados</option>
                <option value="pendiente">Pendiente</option>
                <option value="en_proceso">En proceso</option>
                <option value="completada">Completada</option>
                <option value="en_transito">En tránsito</option>
                <option value="entregada">Entregada</option>
              </select>

              <div className="view-mode-toggle">
                <button
                  type="button"
                  className={`view-btn ${viewMode === 'grid' ? 'active' : ''}`}
                  onClick={() => setViewMode('grid')}
                  title="Vista en tarjetas"
                >
                  <LayoutGrid size={16} />
                </button>
                <button
                  type="button"
                  className={`view-btn ${viewMode === 'table' ? 'active' : ''}`}
                  onClick={() => setViewMode('table')}
                  title="Vista en tabla"
                >
                  <List size={16} />
                </button>
              </div>
            </div>
          </div>

          {/* Listado de Máquinas */}
          {filteredMachines.length === 0 ? (
            <div className="empty-machines-banner">
              <div className="empty-machines-icon">
                <Truck size={32} />
              </div>
              <span className="empty-machines-title">No se encontraron maquinarias</span>
              <p className="empty-machines-sub">
                {searchTerm || categoryFilter !== 'todas' || statusFilter !== 'todos'
                  ? 'Intenta ajustar los filtros de búsqueda o categoría.'
                  : 'Aún no hay equipos registrados. Puedes agregar el primer equipo con el botón de abajo.'}
              </p>
              <button
                type="button"
                className="btn-create-machine mt-2"
                onClick={() => setRegisterModalOpen(true)}
              >
                <Plus size={16} />
                <span>Registrar Nueva Maquinaria</span>
              </button>
            </div>
          ) : viewMode === 'grid' ? (
            /* Vista Cuadrícula */
            <div className="machines-card-grid">
              {filteredMachines.map((machine) => {
                const photo = getMachineProfileImage(machine);
                const statusBadge = getStatusBadge(machine.status);
                const evidenceCount = machine.evidence?.length || 0;
                const phasesCount = machine.phases?.length || 0;
                const completedPhases = machine.phases?.filter((p) => p.status === 'completada').length || 0;

                return (
                  <div key={machine.id} className="machine-card-item">
                    <div className="card-media-banner">
                      {photo ? (
                        <img src={photo} alt={machine.model} className="card-media-img" loading="lazy" />
                      ) : (
                        <div className="card-media-fallback">
                          <Truck size={42} />
                          <span>Sin foto en OCI</span>
                        </div>
                      )}

                      <div className="card-badge-status-top">
                        <span className={`pill-badge ${statusBadge.className}`}>
                          {statusBadge.label}
                        </span>
                      </div>

                      {evidenceCount > 0 && (
                        <div className="card-badge-evidence-top" title={`${evidenceCount} fotos en Oracle Cloud`}>
                          <Camera size={11} /> {evidenceCount}
                        </div>
                      )}
                    </div>

                    <div className="card-info-content">
                      <div className="card-title-row">
                        <div>
                          <h3 className="card-machine-name">{machine.model}</h3>
                          <span className="card-machine-category">{machine.category}</span>
                        </div>
                        <span className="card-serial-pill">{machine.serial}</span>
                      </div>

                      <div className="card-meta-list">
                        <div className="card-meta-row">
                          <span className="card-meta-label">Fases de Alistamiento:</span>
                          <span className="card-meta-val">
                            {phasesCount > 0 ? `${completedPhases}/${phasesCount} completadas` : 'Sin asignar'}
                          </span>
                        </div>
                        <div className="card-meta-row">
                          <span className="card-meta-label">Evidencias en OCI:</span>
                          <span className="card-meta-val">
                            {evidenceCount > 0 ? `${evidenceCount} fotos subidas` : 'Pendiente de fotos'}
                          </span>
                        </div>
                        <div className="card-meta-row">
                          <span className="card-meta-label">Fecha de Registro:</span>
                          <span className="card-meta-val">
                            {machine.createdAt ? new Date(machine.createdAt).toLocaleDateString('es-CO') : 'Reciente'}
                          </span>
                        </div>
                      </div>

                      <div className="card-action-footer">
                        <button
                          type="button"
                          className="btn-card-details"
                          onClick={() => setSelectedMachine(machine)}
                        >
                          <Eye size={15} />
                          <span>Ver Ficha Técnica Completa</span>
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          ) : (
            /* Vista Tabla */
            <div className="card-section" style={{ padding: '0', overflow: 'hidden' }}>
              <div className="table-scroll-wrapper">
                <table className="modern-data-table">
                  <thead>
                    <tr>
                      <th>Equipo</th>
                      <th>Serial</th>
                      <th>Categoría</th>
                      <th>Estado</th>
                      <th>Alistamiento</th>
                      <th>Evidencias</th>
                      <th>Acción</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredMachines.map((machine) => {
                      const photo = getMachineProfileImage(machine);
                      const statusBadge = getStatusBadge(machine.status);
                      const evidenceCount = machine.evidence?.length || 0;
                      const completedPhases = machine.phases?.filter((p) => p.status === 'completada').length || 0;
                      const phasesCount = machine.phases?.length || 0;

                      return (
                        <tr key={machine.id}>
                          <td>
                            <div className="machine-cell-visual">
                              <div className="machine-thumb-box">
                                {photo ? (
                                  <img src={photo} alt={machine.model} className="machine-thumb-img" loading="lazy" />
                                ) : (
                                  <Truck size={20} />
                                )}
                              </div>
                              <div className="machine-text-names">
                                <span className="machine-model-name">{machine.model}</span>
                                <span className="machine-tag-sub">{machine.category}</span>
                              </div>
                            </div>
                          </td>
                          <td>
                            <span className="serial-code-text">{machine.serial}</span>
                          </td>
                          <td>{machine.category}</td>
                          <td>
                            <span className={`pill-badge ${statusBadge.className}`}>
                              {statusBadge.label}
                            </span>
                          </td>
                          <td>
                            <span style={{ fontSize: '12px', color: '#475569' }}>
                              {phasesCount > 0 ? `${completedPhases} de ${phasesCount}` : 'Sin fases'}
                            </span>
                          </td>
                          <td>
                            <span
                              style={{
                                display: 'inline-flex',
                                alignItems: 'center',
                                gap: '4px',
                                fontSize: '11px',
                                color: evidenceCount > 0 ? '#0284C7' : '#94A3B8',
                                backgroundColor: evidenceCount > 0 ? '#E0F2FE' : '#F1F5F9',
                                padding: '2px 7px',
                                borderRadius: '4px',
                                fontWeight: 600,
                              }}
                            >
                              <Camera size={11} /> {evidenceCount}
                            </span>
                          </td>
                          <td>
                            <button
                              type="button"
                              className="btn-table-action"
                              onClick={() => setSelectedMachine(machine)}
                              title="Ver ficha técnica de la máquina"
                            >
                              <Eye size={14} />
                              <span style={{ fontSize: '11px', marginLeft: '4px', fontWeight: 600 }}>Detalle</span>
                            </button>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </main>
      </div>

      {/* Modal de Registro de Maquinaria */}
      <RegisterMachineModal
        isOpen={registerModalOpen}
        onClose={() => setRegisterModalOpen(false)}
        onMachineCreated={handleMachineCreated}
      />

      {/* Modal de Ficha Técnica Completa con foto grande y galería */}
      <MachineDetailModal
        machine={selectedMachine}
        onClose={() => setSelectedMachine(null)}
      />
    </div>
  );
};
export default MachinesPage;
