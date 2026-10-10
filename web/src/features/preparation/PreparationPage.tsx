import React, { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../../context/AuthContext';
import { fetchMachinesApi, updatePhaseStatusApi, fetchMachinePhasesApi } from '../../services/api';
import type { Machine, PreparationPhase, PhaseName, PhaseStatus } from '../../types';
import { Sidebar } from '../../components/Sidebar';
import { Navbar } from '../../components/Navbar';
import { MachineDetailModal } from '../../components/MachineDetailModal';
import { getMachineProfileImage } from '../../utils/evidence';
import {
  ClipboardCheck,
  Search,
  RefreshCw,
  Truck,
  CheckCircle2,
  Clock,
  AlertCircle,
  Eye,
  Sliders,
  UserCheck,
  Loader2,
  Wrench,
  Droplet,
  Paintbrush,
  X,
  Check,
} from 'lucide-react';
import '../../styles/machines.css';
import '../../styles/preparation.css';

export const PreparationPage: React.FC = () => {
  const { token } = useAuth();
  const [machines, setMachines] = useState<Machine[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [successBanner, setSuccessBanner] = useState<string | null>(null);
  const [sidebarOpen, setSidebarOpen] = useState<boolean>(false);
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [phaseFilter, setPhaseFilter] = useState<string>('todas');

  // Modales
  const [selectedMachine, setSelectedMachine] = useState<Machine | null>(null);
  const [editingPhaseMachine, setEditingPhaseMachine] = useState<Machine | null>(null);
  const [machinePhases, setMachinePhases] = useState<PreparationPhase[]>([]);
  const [selectedPhaseName, setSelectedPhaseName] = useState<PhaseName>('ensamblaje');
  const [newStatus, setNewStatus] = useState<PhaseStatus>('pendiente');
  const [observations, setObservations] = useState<string>('');
  const [phaseLoading, setPhaseLoading] = useState<boolean>(false);
  const [phaseModalError, setPhaseModalError] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    if (!token) return;
    try {
      setLoading(true);
      setError(null);
      const data = await fetchMachinesApi(token);
      setMachines(data);
    } catch (err: any) {
      setError(err.message || 'Error al cargar fases de alistamiento.');
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Abrir modal de edición de fase para una máquina
  const handleOpenEditPhase = async (machine: Machine) => {
    setEditingPhaseMachine(machine);
    setPhaseModalError(null);
    setPhaseLoading(true);

    try {
      let phases = machine.phases || [];
      if (!phases || phases.length === 0) {
        if (token) {
          phases = await fetchMachinePhasesApi(machine.id, token);
        }
      }
      setMachinePhases(phases);

      // Por defecto seleccionar la primera fase que esté en pendiente o en proceso
      const firstActive = phases.find((p) => p.status !== 'completada') || phases[0];
      if (firstActive) {
        setSelectedPhaseName(firstActive.name);
        setNewStatus(firstActive.status);
        setObservations(firstActive.observations || '');
      } else {
        setSelectedPhaseName('ensamblaje');
        setNewStatus('pendiente');
        setObservations('');
      }
    } catch (err: any) {
      setPhaseModalError(err.message || 'Error al obtener fases de la máquina.');
    } finally {
      setPhaseLoading(false);
    }
  };

  // Cambiar fase activa en las pestañas del modal
  const handleSelectPhaseTab = (name: PhaseName) => {
    setSelectedPhaseName(name);
    setPhaseModalError(null);
    const targetPhase = machinePhases.find((p) => p.name === name);
    if (targetPhase) {
      setNewStatus(targetPhase.status);
      setObservations(targetPhase.observations || '');
    } else {
      setNewStatus('pendiente');
      setObservations('');
    }
  };

  // Guardar cambio de estado de la fase
  const handleSavePhase = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingPhaseMachine || !token) return;

    const targetPhase = machinePhases.find((p) => p.name === selectedPhaseName);
    if (!targetPhase) {
      setPhaseModalError(`No se encontró la fase de ${selectedPhaseName} para esta máquina.`);
      return;
    }

    try {
      setPhaseLoading(true);
      setPhaseModalError(null);

      const updatedPhase = await updatePhaseStatusApi(
        editingPhaseMachine.id,
        targetPhase.id,
        {
          status: newStatus,
          observations: observations.trim() || undefined,
        },
        token
      );

      // Actualizar estado local
      const updatedList = machinePhases.map((p) => (p.id === updatedPhase.id ? updatedPhase : p));
      setMachinePhases(updatedList);

      // Recargar lista global de máquinas para refrescar estados generales
      await loadData();

      setSuccessBanner(
        `Fase de ${selectedPhaseName.toUpperCase()} para ${editingPhaseMachine.model} actualizada a "${newStatus.replace('_', ' ')}".`
      );
      setTimeout(() => setSuccessBanner(null), 5000);
      setEditingPhaseMachine(null);
    } catch (err: any) {
      setPhaseModalError(err.message || 'Error al actualizar la fase en el servidor.');
    } finally {
      setPhaseLoading(false);
    }
  };

  // Métricas
  const totalCount = machines.length;
  const ensamblajeActive = machines.filter((m) =>
    m.phases?.some((p) => p.name === 'ensamblaje' && p.status === 'en_proceso')
  ).length;
  const lavadoActive = machines.filter((m) =>
    m.phases?.some((p) => p.name === 'lavado' && p.status === 'en_proceso')
  ).length;
  const pinturaActive = machines.filter((m) =>
    m.phases?.some((p) => p.name === 'pintura' && p.status === 'en_proceso')
  ).length;
  const fullyPrepared = machines.filter((m) =>
    m.phases && m.phases.length > 0 && m.phases.every((p) => p.status === 'completada')
  ).length;

  // Filtro reactivo
  const filteredMachines = machines.filter((m) => {
    if (phaseFilter !== 'todas') {
      if (phaseFilter === 'completadas') {
        const isAllDone = m.phases && m.phases.length > 0 && m.phases.every((p) => p.status === 'completada');
        if (!isAllDone) return false;
      } else if (phaseFilter === 'ensamblaje') {
        const hasActive = m.phases?.some((p) => p.name === 'ensamblaje' && p.status !== 'completada');
        if (!hasActive) return false;
      } else if (phaseFilter === 'lavado') {
        const hasActive = m.phases?.some((p) => p.name === 'lavado' && p.status !== 'completada');
        if (!hasActive) return false;
      } else if (phaseFilter === 'pintura') {
        const hasActive = m.phases?.some((p) => p.name === 'pintura' && p.status !== 'completada');
        if (!hasActive) return false;
      }
    }

    if (!searchTerm.trim()) return true;
    const q = searchTerm.toLowerCase();
    return (
      m.model.toLowerCase().includes(q) ||
      m.serial.toLowerCase().includes(q) ||
      m.category.toLowerCase().includes(q)
    );
  });

  const getPhaseIcon = (name: string) => {
    switch (name.toLowerCase()) {
      case 'ensamblaje':
        return <Wrench size={13} />;
      case 'lavado':
        return <Droplet size={13} />;
      case 'pintura':
        return <Paintbrush size={13} />;
      default:
        return <ClipboardCheck size={13} />;
    }
  };

  return (
    <div className="machines-page-layout">
      <Sidebar
        currentTab="alistamientos"
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
              <h1>Control y Fases de Alistamiento</h1>
              <span className="machines-title-sub">
                Seguimiento secuencial obligatorio de Ensamblaje, Lavado y Pintura antes del despacho.
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
                <Truck size={22} />
              </div>
              <div className="machine-kpi-data">
                <span className="machine-kpi-num">{loading ? '...' : totalCount}</span>
                <span className="machine-kpi-label">Total en Flota</span>
              </div>
            </div>

            <div className="machine-kpi-card">
              <div className="machine-kpi-icon icon-amber">
                <Wrench size={22} />
              </div>
              <div className="machine-kpi-data">
                <span className="machine-kpi-num">{loading ? '...' : ensamblajeActive}</span>
                <span className="machine-kpi-label">Ensamblaje en Curso</span>
              </div>
            </div>

            <div className="machine-kpi-card">
              <div className="machine-kpi-icon icon-blue">
                <Droplet size={22} />
              </div>
              <div className="machine-kpi-data">
                <span className="machine-kpi-num">{loading ? '...' : lavadoActive}</span>
                <span className="machine-kpi-label">Lavado en Curso</span>
              </div>
            </div>

            <div className="machine-kpi-card">
              <div className="machine-kpi-icon icon-purple">
                <Paintbrush size={22} />
              </div>
              <div className="machine-kpi-data">
                <span className="machine-kpi-num">{loading ? '...' : pinturaActive}</span>
                <span className="machine-kpi-label">Pintura en Curso</span>
              </div>
            </div>

            <div className="machine-kpi-card">
              <div className="machine-kpi-icon icon-emerald">
                <CheckCircle2 size={22} />
              </div>
              <div className="machine-kpi-data">
                <span className="machine-kpi-num">{loading ? '...' : fullyPrepared}</span>
                <span className="machine-kpi-label">100% Listas (Aprobadas)</span>
              </div>
            </div>
          </div>

          {/* Filtros */}
          <div className="machines-filters-bar">
            <div className="filter-search-box">
              <Search size={16} className="filter-search-icon" />
              <input
                type="text"
                placeholder="Buscar máquina por modelo, serial o categoría..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>

            <div className="filters-group">
              <select
                className="filter-select"
                value={phaseFilter}
                onChange={(e) => setPhaseFilter(e.target.value)}
              >
                <option value="todas">Todas las fases</option>
                <option value="ensamblaje">Ensamblaje pendiente / activo</option>
                <option value="lavado">Lavado pendiente / activo</option>
                <option value="pintura">Pintura pendiente / activo</option>
                <option value="completadas">Todas las fases completadas</option>
              </select>
            </div>
          </div>

          {/* Cuadrícula de Equipos con sus Fases */}
          {filteredMachines.length === 0 ? (
            <div className="empty-machines-banner">
              <ClipboardCheck size={36} />
              <span className="empty-machines-title">No hay maquinarias que coincidan</span>
              <p className="empty-machines-sub">Intenta modificar los filtros de búsqueda.</p>
            </div>
          ) : (
            <div className="machines-card-grid">
              {filteredMachines.map((machine) => {
                const photo = getMachineProfileImage(machine);
                const phases = machine.phases || [];
                const completedCount = phases.filter((p) => p.status === 'completada').length;
                const totalPhases = phases.length || 3;
                const percent = Math.round((completedCount / totalPhases) * 100);

                return (
                  <div key={machine.id} className="machine-card-item">
                    <div className="card-media-banner">
                      {photo ? (
                        <img src={photo} alt={machine.model} className="card-media-img" loading="lazy" />
                      ) : (
                        <div className="card-media-fallback">
                          <Truck size={42} />
                          <span>Sin foto</span>
                        </div>
                      )}
                      <div className="card-badge-status-top">
                        <span className={`pill-badge ${completedCount === 3 ? 'pill-status-ready' : 'pill-status-process'}`}>
                          {completedCount === 3 ? 'Alistamiento Completo' : `${completedCount}/3 Completadas`}
                        </span>
                      </div>
                    </div>

                    <div className="card-info-content">
                      <div className="card-title-row">
                        <div>
                          <h3 className="card-machine-name">{machine.model}</h3>
                          <span className="card-machine-category">{machine.category}</span>
                        </div>
                        <span className="card-serial-pill">{machine.serial}</span>
                      </div>

                      {/* Barra de progreso visual */}
                      <div className="phase-progress-bar-container">
                        <div className="phase-progress-header">
                          <span>Progreso de Alistamiento</span>
                          <span>{percent}%</span>
                        </div>
                        <div className="phase-progress-track">
                          <div className="phase-progress-fill" style={{ width: `${percent}%` }} />
                        </div>
                      </div>

                      {/* Chips de las 3 fases */}
                      <div className="phase-steps-grid">
                        {(['ensamblaje', 'lavado', 'pintura'] as PhaseName[]).map((phaseName) => {
                          const pData = phases.find((p) => p.name === phaseName);
                          const status = pData?.status || 'pendiente';
                          const operator = pData?.operator?.name || 'Por asignar';

                          return (
                            <div key={phaseName} className={`phase-step-chip ${status}`}>
                              <span className="phase-step-chip-title">
                                {getPhaseIcon(phaseName)}
                                {phaseName}
                              </span>
                              <span className="phase-step-chip-operator">
                                <UserCheck size={11} style={{ display: 'inline', marginRight: '3px' }} />
                                {operator}
                              </span>
                              <span className={`phase-step-badge ${status}`}>
                                {status.replace('_', ' ')}
                              </span>
                            </div>
                          );
                        })}
                      </div>

                      {/* Botones de acción */}
                      <div className="card-action-footer mt-4">
                        <div className="card-actions-row">
                          <button
                            type="button"
                            className="btn-card-details"
                            onClick={() => setSelectedMachine(machine)}
                          >
                            <Eye size={15} />
                            <span>Ver Ficha</span>
                          </button>

                          <button
                            type="button"
                            className="btn-primary-register"
                            style={{ padding: '6px 12px', fontSize: '12px' }}
                            onClick={() => handleOpenEditPhase(machine)}
                          >
                            <Sliders size={14} />
                            <span>Gestionar Fase</span>
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </main>
      </div>

      {/* Modal para Actualizar Estado de Fase */}
      {editingPhaseMachine && (
        <div className="modal-backdrop" onClick={() => !phaseLoading && setEditingPhaseMachine(null)}>
          <div
            className="modal-content phase-edit-modal-content"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="modal-header">
              <div className="modal-header-title">
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <div className="register-modal-icon-badge">
                    <ClipboardCheck size={20} />
                  </div>
                  <div>
                    <h3>Gestionar Fase de Alistamiento</h3>
                    <span className="modal-header-sub">
                      {editingPhaseMachine.model} · {editingPhaseMachine.serial}
                    </span>
                  </div>
                </div>
              </div>
              <button
                className="btn-close"
                onClick={() => setEditingPhaseMachine(null)}
                disabled={phaseLoading}
              >
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleSavePhase}>
              <div className="modal-body">
                {phaseModalError && (
                  <div className="register-alert error">
                    <AlertCircle size={18} />
                    <span>{phaseModalError}</span>
                  </div>
                )}

                {/* Regla de negocio visible */}
                <div className="phase-rule-alert">
                  <AlertCircle size={16} style={{ flexShrink: 0, marginTop: '2px' }} />
                  <div>
                    <strong>Secuencia de Calidad Obligatoria:</strong> Ensamblaje debe estar completado antes de iniciar Lavado, y Lavado completado antes de iniciar Pintura.
                  </div>
                </div>

                {/* Pestañas de selección de fase */}
                <label className="form-label">Seleccionar Fase</label>
                <div className="phase-select-tabs">
                  {(['ensamblaje', 'lavado', 'pintura'] as PhaseName[]).map((name) => {
                    const p = machinePhases.find((item) => item.name === name);
                    const isTabActive = selectedPhaseName === name;

                    return (
                      <button
                        key={name}
                        type="button"
                        className={`phase-tab-btn ${isTabActive ? 'active' : ''}`}
                        onClick={() => handleSelectPhaseTab(name)}
                      >
                        <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                          {getPhaseIcon(name)} {name.toUpperCase()}
                        </span>
                        <span className="phase-tab-sub">
                          {p?.status ? p.status.replace('_', ' ') : 'pendiente'}
                        </span>
                      </button>
                    );
                  })}
                </div>

                {/* Selector de nuevo estado */}
                <label className="form-label">Estado de la Fase ({selectedPhaseName})</label>
                <div className="phase-status-radio-group">
                  <div
                    className={`phase-status-radio-card ${newStatus === 'pendiente' ? 'active-pendiente' : ''}`}
                    onClick={() => setNewStatus('pendiente')}
                  >
                    <Clock size={20} color="#64748B" />
                    <span className="phase-status-title">Pendiente</span>
                  </div>

                  <div
                    className={`phase-status-radio-card ${newStatus === 'en_proceso' ? 'active-en_proceso' : ''}`}
                    onClick={() => setNewStatus('en_proceso')}
                  >
                    <Wrench size={20} color="#D97706" />
                    <span className="phase-status-title">En Proceso</span>
                  </div>

                  <div
                    className={`phase-status-radio-card ${newStatus === 'completada' ? 'active-completada' : ''}`}
                    onClick={() => setNewStatus('completada')}
                  >
                    <CheckCircle2 size={20} color="#059669" />
                    <span className="phase-status-title">Completada</span>
                  </div>
                </div>

                {/* Observaciones */}
                <div className="form-group mt-3">
                  <label htmlFor="phase-obs" className="form-label">
                    Observaciones y Notas Técnicas del Operario
                  </label>
                  <textarea
                    id="phase-obs"
                    className="form-input"
                    rows={3}
                    placeholder="Ej: Calibración de torque realizada al 100%, sin fugas en sistema hidráulico..."
                    value={observations}
                    onChange={(e) => setObservations(e.target.value)}
                    disabled={phaseLoading}
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={() => setEditingPhaseMachine(null)}
                  disabled={phaseLoading}
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="btn-primary-register"
                  disabled={phaseLoading}
                >
                  {phaseLoading ? (
                    <>
                      <Loader2 size={16} className="spinner" />
                      <span>Actualizando Fase...</span>
                    </>
                  ) : (
                    <>
                      <Check size={16} />
                      <span>Guardar Avance de Fase</span>
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Ficha técnica modal */}
      <MachineDetailModal
        machine={selectedMachine}
        onClose={() => setSelectedMachine(null)}
      />
    </div>
  );
};

export default PreparationPage;
