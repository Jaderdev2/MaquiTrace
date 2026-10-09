import React, { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../../context/AuthContext';
import { fetchMachinesApi } from '../../services/api';
import type { Machine, PreparationPhase } from '../../types';
import { Sidebar } from '../../components/Sidebar';
import { Navbar } from '../../components/Navbar';
import { MachineDetailModal } from '../../components/MachineDetailModal';
import { getMachinePrimaryPhoto } from '../../utils/evidence';
import {
  Layers,
  Clock,
  CheckCircle2,
  ChevronRight,
  Calendar,
  Truck,
  Camera,
  Wrench,
  RefreshCw,
  Database,
  MapPin,
  AlertCircle,
  Eye,
} from 'lucide-react';

export const Dashboard: React.FC = () => {
  const { user, token } = useAuth();
  const [machines, setMachines] = useState<Machine[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [currentTab, setCurrentTab] = useState<string>('inicio');
  const [sidebarOpen, setSidebarOpen] = useState<boolean>(false);
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<string>('todos');
  const [selectedMachine, setSelectedMachine] = useState<Machine | null>(null);
  const [lastUpdated, setLastUpdated] = useState<Date>(new Date());

  // Carga de datos reales desde el backend NestJS (Neon PostgreSQL)
  const loadMachines = useCallback(async () => {
    if (!token) return;
    try {
      setLoading(true);
      setError(null);
      const data = await fetchMachinesApi(token);
      setMachines(data);
      setLastUpdated(new Date());
    } catch (err: any) {
      console.error('Error al consultar maquinarias del backend:', err);
      setError(err.message || 'Error de conexión con el backend');
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    loadMachines();
  }, [loadMachines]);

  // Helper para identificar la fase activa o última fase de una máquina
  const getActivePhase = (machine: Machine): { name: string; status: string; operatorName: string } => {
    if (!machine.phases || machine.phases.length === 0) {
      return { name: 'Sin iniciar', status: 'pendiente', operatorName: 'Sin asignar' };
    }

    // Prioridad 1: Fase que está en proceso
    const inProcess = machine.phases.find((p: PreparationPhase) => p.status === 'en_proceso');
    if (inProcess) {
      return {
        name: inProcess.name,
        status: inProcess.status,
        operatorName: inProcess.operator?.name || 'Por asignar',
      };
    }

    // Prioridad 2: Si todas están completadas
    const allCompleted = machine.phases.every((p: PreparationPhase) => p.status === 'completada');
    if (allCompleted) {
      const last = machine.phases[machine.phases.length - 1];
      return {
        name: 'Finalizado',
        status: 'completada',
        operatorName: last?.operator?.name || 'Equipo finalizado',
      };
    }

    // Prioridad 3: Siguiente fase pendiente
    const nextPending = machine.phases.find((p: PreparationPhase) => p.status === 'pendiente');
    if (nextPending) {
      return {
        name: nextPending.name,
        status: 'pendiente',
        operatorName: nextPending.operator?.name || 'Por asignar',
      };
    }

    return { name: 'En espera', status: 'pendiente', operatorName: 'Sin asignar' };
  };

  // Clases CSS de etapas del alistamiento
  const getStageClass = (stage: string) => {
    switch (stage.toLowerCase()) {
      case 'pintura': return 'pill-stage-pintura';
      case 'lavado': return 'pill-stage-lavado';
      case 'ensamblaje': return 'pill-stage-ensamblaje';
      case 'finalizado': return 'pill-stage-finalizado';
      default: return 'pill-stage-ensamblaje';
    }
  };

  // Clases CSS de estados generales
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

  // -------------------------------------------------------------
  // MÉTRICAS 100% REALES DERIVADAS DEL BACKEND
  // -------------------------------------------------------------
  const totalMachines = machines.length;
  const inProcessCount = machines.filter((m) => m.status === 'en_proceso').length;
  const pendingCount = machines.filter((m) => m.status === 'pendiente').length;
  const completedCount = machines.filter((m) => m.status === 'completada').length;
  const inTransitCount = machines.filter((m) => m.status === 'en_transito').length;
  const totalEvidenceCount = machines.reduce((acc, m) => acc + (m.evidence?.length || 0), 0);


  // Máquinas agrupadas por categoría
  const categoryCounts = machines.reduce((acc, m) => {
    const cat = m.category || 'Sin categoría';
    acc[cat] = (acc[cat] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);

  // Viajes reales de transporte asociados a las máquinas
  const activeTrips = machines.flatMap((m) =>
    (m.trips || []).map((t) => ({
      ...t,
      machineModel: m.model,
      machineSerial: m.serial,
      machineCategory: m.category,
    }))
  );

  // Filtrado reactivo de la tabla de Alistamientos Recientes
  const filteredMachines = machines.filter((m) => {
    // Filtro por estado
    if (statusFilter !== 'todos' && m.status !== statusFilter) {
      return false;
    }

    // Filtro por término de búsqueda (modelo, serie, categoría u operario)
    if (!searchTerm.trim()) return true;
    const q = searchTerm.toLowerCase();
    const phaseInfo = getActivePhase(m);
    return (
      m.model.toLowerCase().includes(q) ||
      m.serial.toLowerCase().includes(q) ||
      (m.category && m.category.toLowerCase().includes(q)) ||
      phaseInfo.operatorName.toLowerCase().includes(q)
    );
  });

  return (
    <div className="dashboard-root">
      {/* 1. Menú lateral izquierdo (Sidebar) */}
      <Sidebar
        currentTab={currentTab}
        onSelectTab={setCurrentTab}
        isOpen={sidebarOpen}
        onCloseMobile={() => setSidebarOpen(false)}
      />

      {/* 2. Área Principal de Contenido */}
      <div className="dashboard-main-area">
        {/* Barra superior con Buscador y Perfil */}
        <Navbar
          onToggleSidebar={() => setSidebarOpen(!sidebarOpen)}
          searchValue={searchTerm}
          onSearchChange={setSearchTerm}
        />

        {/* Contenido Central del Dashboard */}
        <main className="dashboard-container">
          {/* Encabezado: Saludo, Título y Estado de sincronización en vivo */}
          <section className="dashboard-heading-row">
            <div className="heading-left-box">
              <span className="greeting-label">
                Bienvenido, {user?.name || 'Administrador'}
              </span>
              <div className="heading-title-line">
                <h1 className="dashboard-main-title">Panel de control</h1>
                <div className="backend-live-indicator" title="Conexión establecida con PostgreSQL Neon">
                  <span className="live-dot"></span>
                  <span>Backend en línea</span>
                </div>
              </div>
              <p className="dashboard-main-desc">
                Supervisión en tiempo real del alistamiento, inspección y logística de maquinaria pesada.
              </p>
            </div>

            <div className="heading-right-meta">
              <div className="meta-date">
                <Calendar size={14} />
                <span>
                  {new Date().toLocaleDateString('es-CO', {
                    day: 'numeric',
                    month: 'long',
                    year: 'numeric',
                  })}
                </span>
              </div>
              <div className="meta-sync-row">
                <span className="meta-time">
                  Actualizado: {lastUpdated.toLocaleTimeString('es-CO', { hour: '2-digit', minute: '2-digit' })}
                </span>
                <button
                  type="button"
                  onClick={loadMachines}
                  className={`btn-refresh-data ${loading ? 'spinning' : ''}`}
                  title="Sincronizar datos del backend"
                >
                  <RefreshCw size={13} />
                </button>
              </div>
            </div>
          </section>

          {/* Alerta en caso de error de conexión */}
          {error && (
            <div className="dashboard-error-banner">
              <AlertCircle size={18} />
              <span>{error}</span>
              <button type="button" onClick={loadMachines} className="btn-error-retry">
                Reintentar
              </button>
            </div>
          )}

          {/* Tarjetas Superiores de Métricas (KPIs 100% reales del Backend) */}
          <section className="kpi-cards-grid">
            {/* KPI 1: Total Máquinas Registradas */}
            <div className="kpi-stat-card kpi-blue" onClick={() => setStatusFilter('todos')}>
              <div className="kpi-card-top">
                <span className="kpi-number">{loading ? '...' : totalMachines}</span>
                <div className="kpi-badge-circle">
                  <Layers size={18} />
                </div>
              </div>
              <div className="kpi-card-label">
                <span>Total de maquinaria</span>
                <ChevronRight size={14} className="kpi-arrow" />
              </div>
            </div>

            {/* KPI 2: En Proceso de Alistamiento */}
            <div className="kpi-stat-card kpi-amber" onClick={() => setStatusFilter('en_proceso')}>
              <div className="kpi-card-top">
                <span className="kpi-number">{loading ? '...' : inProcessCount}</span>
                <div className="kpi-badge-circle">
                  <Clock size={18} />
                </div>
              </div>
              <div className="kpi-card-label">
                <span>En alistamiento activo</span>
                <ChevronRight size={14} className="kpi-arrow" />
              </div>
            </div>

            {/* KPI 3: Pendientes por Iniciar */}
            <div className="kpi-stat-card kpi-cyan" onClick={() => setStatusFilter('pendiente')}>
              <div className="kpi-card-top">
                <span className="kpi-number">{loading ? '...' : pendingCount}</span>
                <div className="kpi-badge-circle">
                  <Wrench size={18} />
                </div>
              </div>
              <div className="kpi-card-label">
                <span>Pendientes por iniciar</span>
                <ChevronRight size={14} className="kpi-arrow" />
              </div>
            </div>

            {/* KPI 4: Listas / Completadas */}
            <div className="kpi-stat-card kpi-emerald" onClick={() => setStatusFilter('completada')}>
              <div className="kpi-card-top">
                <span className="kpi-number">{loading ? '...' : completedCount}</span>
                <div className="kpi-badge-circle">
                  <CheckCircle2 size={18} />
                </div>
              </div>
              <div className="kpi-card-label">
                <span>Listas / Completadas</span>
                <ChevronRight size={14} className="kpi-arrow" />
              </div>
            </div>

            {/* KPI 5: Evidencias Registradas */}
            <div className="kpi-stat-card kpi-rose">
              <div className="kpi-card-top">
                <span className="kpi-number">{loading ? '...' : totalEvidenceCount}</span>
                <div className="kpi-badge-circle">
                  <Camera size={18} />
                </div>
              </div>
              <div className="kpi-card-label">
                <span>Evidencias cargadas</span>
                <ChevronRight size={14} className="kpi-arrow" />
              </div>
            </div>
          </section>

          {/* SECCIÓN PRINCIPAL: ALISTAMIENTOS RECIENTES (Con datos reales de Backend) */}
          <section className="card-section">
            <div className="section-card-header">
              <div className="header-title-flex">
                <span className="section-icon-tag">☷</span>
                <div>
                  <h2>Alistamientos recientes</h2>
                  <span className="section-subtitle">
                    Equipos en el sistema con sus fases activas y operarios responsables.
                  </span>
                </div>
              </div>

              {/* Chips de filtrado rápido */}
              <div className="filter-chips-row">
                <button
                  type="button"
                  className={`filter-chip ${statusFilter === 'todos' ? 'active' : ''}`}
                  onClick={() => setStatusFilter('todos')}
                >
                  Todos ({totalMachines})
                </button>
                <button
                  type="button"
                  className={`filter-chip ${statusFilter === 'en_proceso' ? 'active' : ''}`}
                  onClick={() => setStatusFilter('en_proceso')}
                >
                  En alistamiento ({inProcessCount})
                </button>
                <button
                  type="button"
                  className={`filter-chip ${statusFilter === 'pendiente' ? 'active' : ''}`}
                  onClick={() => setStatusFilter('pendiente')}
                >
                  Pendientes ({pendingCount})
                </button>
                <button
                  type="button"
                  className={`filter-chip ${statusFilter === 'completada' ? 'active' : ''}`}
                  onClick={() => setStatusFilter('completada')}
                >
                  Completadas ({completedCount})
                </button>
                <button
                  type="button"
                  className={`filter-chip ${statusFilter === 'en_transito' ? 'active' : ''}`}
                  onClick={() => setStatusFilter('en_transito')}
                >
                  En tránsito ({inTransitCount})
                </button>
              </div>
            </div>

            <div className="table-scroll-wrapper">
              {loading ? (
                <div className="table-loading-state">
                  <RefreshCw size={24} className="spinning text-primary" />
                  <p>Cargando información de alistamientos desde la base de datos...</p>
                </div>
              ) : filteredMachines.length === 0 ? (
                <div className="table-empty-state">
                  <Database size={36} className="empty-icon" />
                  <h4>No se encontraron alistamientos</h4>
                  <p>
                    {searchTerm
                      ? `No hay máquinas que coincidan con la búsqueda "${searchTerm}".`
                      : 'No hay equipos registrados bajo el filtro seleccionado en este momento.'}
                  </p>
                  {(searchTerm || statusFilter !== 'todos') && (
                    <button
                      type="button"
                      className="btn-clear-filters"
                      onClick={() => {
                        setSearchTerm('');
                        setStatusFilter('todos');
                      }}
                    >
                      Limpiar filtros
                    </button>
                  )}
                </div>
              ) : (
                <table className="modern-data-table">
                  <thead>
                    <tr>
                      <th>Máquina</th>
                      <th>Número de serie</th>
                      <th>Operario asignado</th>
                      <th>Etapa actual</th>
                      <th>Estado del equipo</th>
                      <th>Fecha de ingreso</th>
                      <th className="text-right">Acciones</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredMachines.map((machine) => {
                      const phaseInfo = getActivePhase(machine);
                      const statusBadge = getStatusBadge(machine.status);
                      const formattedDate = machine.createdAt
                        ? new Date(machine.createdAt).toLocaleDateString('es-CO', {
                            day: '2-digit',
                            month: '2-digit',
                            year: 'numeric',
                          })
                        : 'Reciente';
                      const formattedTime = machine.createdAt
                        ? new Date(machine.createdAt).toLocaleTimeString('es-CO', {
                            hour: '2-digit',
                            minute: '2-digit',
                          })
                        : '';

                      const machinePhoto = getMachinePrimaryPhoto(machine);

                      return (
                        <tr key={machine.id}>
                          <td>
                            <div className="machine-cell-visual">
                              <div
                                className="machine-thumb-box"
                                title={machinePhoto ? 'Foto de inspección cargada desde app móvil' : 'Sin foto cargada'}
                              >
                                {machinePhoto ? (
                                  <img
                                    src={machinePhoto}
                                    alt={machine.model}
                                    className="machine-thumb-img"
                                    loading="lazy"
                                    onError={(e) => {
                                      e.currentTarget.style.display = 'none';
                                      const parent = e.currentTarget.parentElement;
                                      const fallback = parent?.querySelector('.machine-thumb-fallback');
                                      if (fallback) (fallback as HTMLElement).style.display = 'flex';
                                    }}
                                  />
                                ) : null}
                                <div
                                  className="machine-thumb-fallback"
                                  style={{
                                    display: machinePhoto ? 'none' : 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    width: '100%',
                                    height: '100%',
                                  }}
                                >
                                  <Truck size={20} />
                                </div>
                              </div>
                              <div className="machine-text-names">
                                <span className="machine-model-name">{machine.model}</span>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                                  <span className="machine-tag-sub">{machine.category}</span>
                                  {machine.evidence && machine.evidence.length > 0 && (
                                    <span
                                      style={{
                                        display: 'inline-flex',
                                        alignItems: 'center',
                                        gap: '3px',
                                        fontSize: '10px',
                                        color: '#0284C7',
                                        backgroundColor: '#E0F2FE',
                                        padding: '1px 5px',
                                        borderRadius: '4px',
                                        fontWeight: 600,
                                      }}
                                      title={`${machine.evidence.length} evidencia(s) registradas`}
                                    >
                                      <Camera size={10} /> {machine.evidence.length}
                                    </span>
                                  )}
                                </div>
                              </div>
                            </div>
                          </td>
                          <td>
                            <span className="serial-code-text">{machine.serial}</span>
                          </td>
                          <td>
                            <div className="operator-cell">
                              <span className="operator-name-text">{phaseInfo.operatorName}</span>
                            </div>
                          </td>
                          <td>
                            <span className={`pill-badge ${getStageClass(phaseInfo.name)}`}>
                              {phaseInfo.name.charAt(0).toUpperCase() + phaseInfo.name.slice(1)}
                            </span>
                          </td>
                          <td>
                            <span className={`pill-badge ${statusBadge.className}`}>
                              {statusBadge.label}
                            </span>
                          </td>
                          <td>
                            <span className="table-time-text">
                              {formattedDate}
                              {formattedTime && <span className="time-sub-block">{formattedTime}</span>}
                            </span>
                          </td>
                          <td className="text-right">
                            <button
                              type="button"
                              className="btn-table-action"
                              onClick={() => setSelectedMachine(machine)}
                              title="Ver detalle del alistamiento"
                            >
                              <Eye size={15} />
                              <span style={{ fontSize: '11px', marginLeft: '4px', fontWeight: 600 }}>Detalle</span>
                            </button>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              )}
            </div>
          </section>

          {/* DETALLES RELEVANTES 2 Y 3: Logística y Distribución por Categoría */}
          <div className="dashboard-bottom-grid">
            {/* Control de Despacho y Transporte */}
            <section className="card-section bottom-card-left">
              <div className="section-card-header">
                <div className="header-title-flex">
                  <span className="section-icon-tag"><Truck size={18} /></span>
                  <div>
                    <h2>Control de despacho y transporte</h2>
                    <span className="section-subtitle">
                      Seguimiento a viajes registrados y traslados de maquinaria.
                    </span>
                  </div>
                </div>
                <span className="badge-trips-count">
                  {activeTrips.length} {activeTrips.length === 1 ? 'viaje' : 'viajes'}
                </span>
              </div>

              <div className="bottom-card-body">
                {activeTrips.length > 0 ? (
                  <div className="trips-table-wrapper">
                    <table className="transit-compact-table">
                      <thead>
                        <tr>
                          <th>Máquina</th>
                          <th>Vehículo</th>
                          <th>Destino</th>
                          <th>Transportador</th>
                          <th>Estado</th>
                        </tr>
                      </thead>
                      <tbody>
                        {activeTrips.map((trip) => (
                          <tr key={trip.id}>
                            <td>
                              <strong>{trip.machineModel}</strong>
                              <span style={{ display: 'block', fontSize: '11px', color: '#64748B' }}>
                                {trip.machineSerial}
                              </span>
                            </td>
                            <td>{trip.vehicle}</td>
                            <td>
                              <span style={{ display: 'inline-flex', alignItems: 'center', gap: '3px' }}>
                                <MapPin size={12} style={{ color: '#0066FF' }} />
                                {trip.destination}
                              </span>
                            </td>
                            <td>{trip.transporter?.name || 'Asignado'}</td>
                            <td>
                              <span className="pill-badge pill-status-process">
                                {trip.status}
                              </span>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                ) : (
                  <div className="fleet-status-banner">
                    <div className="fleet-status-icon">
                      <Truck size={22} />
                    </div>
                    <div className="fleet-status-text">
                      <strong>Todos los equipos en patio / taller</strong>
                      <p>
                        Actualmente no hay órdenes de traslado activas en carretera. Las {totalMachines} máquinas
                        se encuentran en estaciones de alistamiento o en patio central de operaciones.
                      </p>
                    </div>
                  </div>
                )}
              </div>
            </section>

            {/* Resumen de Inventario por Categoría */}
            <section className="card-section bottom-card-right">
              <div className="section-card-header">
                <div className="header-title-flex">
                  <span className="section-icon-tag"><Database size={18} /></span>
                  <div>
                    <h2>Parque de maquinaria</h2>
                    <span className="section-subtitle">
                      Distribución de flota por categoría en base de datos.
                    </span>
                  </div>
                </div>
              </div>

              <div className="bottom-card-body">
                {Object.keys(categoryCounts).length > 0 ? (
                  <div className="categories-list">
                    {Object.entries(categoryCounts).map(([category, count]) => {
                      const percentage = totalMachines > 0 ? Math.round((count / totalMachines) * 100) : 0;
                      return (
                        <div key={category} className="category-row-item">
                          <div className="category-row-top">
                            <span className="category-row-name">{category}</span>
                            <span className="category-row-val">
                              {count} {count === 1 ? 'unidad' : 'unidades'} ({percentage}%)
                            </span>
                          </div>
                          <div className="category-track-bar">
                            <div
                              className="category-fill-bar"
                              style={{ width: `${percentage}%` }}
                            ></div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <p style={{ color: '#64748B', fontSize: '13px', margin: 0 }}>
                    No hay categorías registradas aún.
                  </p>
                )}

                <div className="inventory-summary-footer">
                  <div className="inventory-footer-item">
                    <span className="footer-item-label">Evidencias fotográficas:</span>
                    <span className="footer-item-value">{totalEvidenceCount} archivos</span>
                  </div>
                  <div className="inventory-footer-item">
                    <span className="footer-item-label">Estado general:</span>
                    <span className="footer-item-value text-emerald font-semibold">Operacional</span>
                  </div>
                </div>
              </div>
            </section>
          </div>
        </main>
      </div>

      {/* Modal de Detalle con datos 100% reales */}
      <MachineDetailModal
        machine={selectedMachine}
        onClose={() => setSelectedMachine(null)}
      />
    </div>
  );
};

