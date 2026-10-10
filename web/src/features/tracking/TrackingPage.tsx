import React, { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../../context/AuthContext';
import {
  fetchActiveTripsApi,
  fetchTripHistoryApi,
  departTransportApi,
  deliverTransportApi,
  fetchMachinesApi,
} from '../../services/api';
import type { TransportTrip, Machine } from '../../types';
import { Sidebar } from '../../components/Sidebar';
import { Navbar } from '../../components/Navbar';
import {
  Navigation,
  Truck,
  MapPin,
  Clock,
  CheckCircle2,
  AlertCircle,
  RefreshCw,
  Search,
  Eye,
  Calendar,
  X,
  Loader2,
  ShieldAlert,
  Play,
} from 'lucide-react';
import '../../styles/machines.css';
import '../../styles/tracking.css';

export const TrackingPage: React.FC = () => {
  const { token } = useAuth();
  const [trips, setTrips] = useState<TransportTrip[]>([]);
  const [machines, setMachines] = useState<Machine[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [successBanner, setSuccessBanner] = useState<string | null>(null);
  const [sidebarOpen, setSidebarOpen] = useState<boolean>(false);
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<string>('todos');

  // Modal de Historial GPS
  const [selectedTrip, setSelectedTrip] = useState<TransportTrip | null>(null);
  const [tripHistory, setTripHistory] = useState<any | null>(null);
  const [historyLoading, setHistoryLoading] = useState<boolean>(false);
  const [historyError, setHistoryError] = useState<string | null>(null);

  // Acciones de transporte
  const [actionLoading, setActionLoading] = useState<boolean>(false);

  const loadData = useCallback(async () => {
    if (!token) return;
    try {
      setLoading(true);
      setError(null);
      const [tripsData, machinesData] = await Promise.all([
        fetchActiveTripsApi(token),
        fetchMachinesApi(token),
      ]);
      setTrips(tripsData);
      setMachines(machinesData);
    } catch (err: any) {
      setError(err.message || 'Error al cargar información de seguimiento.');
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Ver historial GPS de un viaje
  const handleOpenGpsHistory = async (trip: TransportTrip) => {
    setSelectedTrip(trip);
    setHistoryLoading(true);
    setHistoryError(null);
    try {
      if (token) {
        const history = await fetchTripHistoryApi(trip.id, token);
        setTripHistory(history);
      }
    } catch (err: any) {
      setHistoryError(err.message || 'Error al obtener registros GPS del viaje.');
    } finally {
      setHistoryLoading(false);
    }
  };

  // Registrar salida de transporte
  const handleDepart = async (machineId: string) => {
    if (!token) return;
    try {
      setActionLoading(true);
      await departTransportApi(machineId, token);
      setSuccessBanner('¡Salida de ruta confirmada! La máquina ahora está "En Tránsito".');
      setTimeout(() => setSuccessBanner(null), 5000);
      await loadData();
    } catch (err: any) {
      setError(err.message || 'Error al registrar la salida de transporte.');
    } finally {
      setActionLoading(false);
    }
  };

  // Registrar entrega final
  const handleDeliver = async (machineId: string) => {
    if (!token) return;
    try {
      setActionLoading(true);
      await deliverTransportApi(machineId, token);
      setSuccessBanner('¡Entrega de maquinaria completada con éxito!');
      setTimeout(() => setSuccessBanner(null), 5000);
      await loadData();
    } catch (err: any) {
      setError(err.message || 'Error al registrar la entrega de maquinaria.');
    } finally {
      setActionLoading(false);
    }
  };

  // Métricas
  const totalTrips = trips.length;
  const inTransitTrips = trips.filter((t) => t.status === 'en_transito').length;
  const pendingTrips = trips.filter((t) => t.status === 'pendiente').length;
  const deliveredTrips = trips.filter((t) => t.status === 'entregado').length;

  // Filtrado reactivo
  const filteredTrips = trips.filter((t) => {
    if (statusFilter !== 'todos' && t.status !== statusFilter) return false;
    if (!searchTerm.trim()) return true;
    const q = searchTerm.toLowerCase();
    const dest = t.destination?.toLowerCase() || '';
    const vehicle = t.vehicle?.toLowerCase() || '';
    const driver = t.transporter?.name?.toLowerCase() || '';
    const machine = t.machine ? `${t.machine.model} ${t.machine.serial}`.toLowerCase() : '';
    return dest.includes(q) || vehicle.includes(q) || driver.includes(q) || machine.includes(q);
  });

  return (
    <div className="machines-page-layout">
      <Sidebar
        currentTab="seguimiento"
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
              <h1>Seguimiento y Trazabilidad en Ruta</h1>
              <span className="machines-title-sub">
                Monitoreo GPS en tiempo real de viajes de transporte, entregas y gestión de incidencias.
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
                <span className="machine-kpi-num">{loading ? '...' : totalTrips}</span>
                <span className="machine-kpi-label">Total de Viajes Registrados</span>
              </div>
            </div>

            <div className="machine-kpi-card">
              <div className="machine-kpi-icon icon-purple">
                <Navigation size={22} />
              </div>
              <div className="machine-kpi-data">
                <span className="machine-kpi-num">{loading ? '...' : inTransitTrips}</span>
                <span className="machine-kpi-label">En Tránsito Ahora</span>
              </div>
            </div>

            <div className="machine-kpi-card">
              <div className="machine-kpi-icon icon-amber">
                <Clock size={22} />
              </div>
              <div className="machine-kpi-data">
                <span className="machine-kpi-num">{loading ? '...' : pendingTrips}</span>
                <span className="machine-kpi-label">Pendientes de Salida</span>
              </div>
            </div>

            <div className="machine-kpi-card">
              <div className="machine-kpi-icon icon-emerald">
                <CheckCircle2 size={22} />
              </div>
              <div className="machine-kpi-data">
                <span className="machine-kpi-num">{loading ? '...' : deliveredTrips}</span>
                <span className="machine-kpi-label">Entregas Confirmadas</span>
              </div>
            </div>
          </div>

          {/* Filtros */}
          <div className="machines-filters-bar">
            <div className="filter-search-box">
              <Search size={16} className="filter-search-icon" />
              <input
                type="text"
                placeholder="Buscar por destino, vehículo, conductor o equipo..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>

            <div className="filters-group">
              <select
                className="filter-select"
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
              >
                <option value="todos">Todos los estados</option>
                <option value="en_transito">En tránsito</option>
                <option value="pendiente">Pendiente</option>
                <option value="entregado">Entregado</option>
              </select>
            </div>
          </div>

          {/* Listado de Viajes */}
          {filteredTrips.length === 0 ? (
            <div className="empty-machines-banner">
              <Navigation size={36} />
              <span className="empty-machines-title">No hay viajes registrados</span>
              <p className="empty-machines-sub">
                Actualmente no hay viajes de transporte en curso o no coinciden con los filtros.
              </p>
            </div>
          ) : (
            <div className="machines-card-grid">
              {filteredTrips.map((trip) => {
                const machine = trip.machine || machines.find((m) => m.id === trip.machineId);
                const isTransit = trip.status === 'en_transito';
                const isDelivered = trip.status === 'entregado';
                const isPending = trip.status === 'pendiente';

                return (
                  <div key={trip.id} className="tracking-trip-card">
                    <div className="tracking-trip-header">
                      <div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                          <Truck size={18} color="#0F172A" />
                          <strong style={{ fontSize: '14px', color: '#0F172A' }}>
                            {trip.vehicle || 'Vehículo de Carga'}
                          </strong>
                        </div>
                        <span style={{ fontSize: '11px', color: '#64748B' }}>
                          Conductor: {trip.transporter?.name || 'Transportador asignado'}
                        </span>
                      </div>

                      <div className="tracking-trip-badge-row">
                        <span
                          className={`pill-badge ${
                            isTransit
                              ? 'pill-status-transit'
                              : isDelivered
                              ? 'pill-status-ready'
                              : 'pill-status-pending'
                          }`}
                        >
                          {trip.status.replace('_', ' ')}
                        </span>
                      </div>
                    </div>

                    <div className="tracking-trip-body">
                      {/* Destino y Maquinaria */}
                      <div className="tracking-info-grid">
                        <div className="tracking-info-item">
                          <span className="tracking-info-label">Destino Oficial</span>
                          <span className="tracking-info-val">
                            <MapPin size={13} style={{ display: 'inline', marginRight: '3px' }} />
                            {trip.destination}
                          </span>
                        </div>

                        <div className="tracking-info-item">
                          <span className="tracking-info-label">Maquinaria Transportada</span>
                          <span className="tracking-info-val">
                            {machine ? `${machine.model} (${machine.serial})` : 'Cargando equipo...'}
                          </span>
                        </div>

                        <div className="tracking-info-item">
                          <span className="tracking-info-label">Fecha / Salida</span>
                          <span className="tracking-info-val">
                            <Calendar size={13} style={{ display: 'inline', marginRight: '3px' }} />
                            {trip.departureAt ? new Date(trip.departureAt).toLocaleDateString('es-CO') : 'Pendiente'}
                          </span>
                        </div>

                        <div className="tracking-info-item">
                          <span className="tracking-info-label">Llegada / Entrega</span>
                          <span className="tracking-info-val">
                            <Clock size={13} style={{ display: 'inline', marginRight: '3px' }} />
                            {trip.arrivalAt ? new Date(trip.arrivalAt).toLocaleDateString('es-CO') : isTransit ? 'En ruta' : 'Pendiente'}
                          </span>
                        </div>
                      </div>

                      {/* Botones de acción operativos */}
                      <div className="card-action-footer mt-2">
                        <div className="card-actions-row">
                          <button
                            type="button"
                            className="btn-card-details"
                            onClick={() => handleOpenGpsHistory(trip)}
                          >
                            <Eye size={14} />
                            <span>Ver Ruta GPS</span>
                          </button>

                          {isPending && machine && (
                            <button
                              type="button"
                              className="btn-primary-register"
                              style={{ padding: '6px 12px', fontSize: '12px' }}
                              onClick={() => handleDepart(machine.id)}
                              disabled={actionLoading}
                            >
                              <Play size={13} />
                              <span>Marcar Salida</span>
                            </button>
                          )}

                          {isTransit && machine && (
                            <button
                              type="button"
                              className="btn-primary-register"
                              style={{
                                padding: '6px 12px',
                                fontSize: '12px',
                                backgroundColor: '#059669',
                              }}
                              onClick={() => handleDeliver(machine.id)}
                              disabled={actionLoading}
                            >
                              <CheckCircle2 size={13} />
                              <span>Confirmar Entrega</span>
                            </button>
                          )}
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

      {/* Modal de Historial de Puntos GPS e Incidentes */}
      {selectedTrip && (
        <div className="modal-backdrop" onClick={() => setSelectedTrip(null)}>
          <div
            className="modal-content gps-history-modal-content"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="modal-header">
              <div className="modal-header-title">
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <div className="register-modal-icon-badge">
                    <Navigation size={20} />
                  </div>
                  <div>
                    <h3>Trazabilidad y Waypoints GPS</h3>
                    <span className="modal-header-sub">
                      Vehículo {selectedTrip.vehicle} · Destino {selectedTrip.destination}
                    </span>
                  </div>
                </div>
              </div>
              <button className="btn-close" onClick={() => setSelectedTrip(null)}>
                <X size={20} />
              </button>
            </div>

            <div className="modal-body">
              {historyLoading ? (
                <div style={{ textAlign: 'center', padding: '30px' }}>
                  <Loader2 size={32} className="spinner text-primary" style={{ margin: '0 auto' }} />
                  <p style={{ marginTop: '10px', color: '#64748B' }}>Cargando registros satelitales...</p>
                </div>
              ) : historyError ? (
                <div className="register-alert error">
                  <AlertCircle size={18} />
                  <span>{historyError}</span>
                </div>
              ) : (
                <div>
                  <div className="tracking-info-grid">
                    <div className="tracking-info-item">
                      <span className="tracking-info-label">Estado Actual</span>
                      <span className="tracking-info-val">{selectedTrip.status.replace('_', ' ')}</span>
                    </div>
                    <div className="tracking-info-item">
                      <span className="tracking-info-label">Puntos GPS Registrados</span>
                      <span className="tracking-info-val">
                        {tripHistory?.gpsRecords?.length || 0} coordenadas
                      </span>
                    </div>
                  </div>

                  {/* Línea de tiempo de registros GPS */}
                  <h4 style={{ margin: '16px 0 8px 0', fontSize: '13px', color: '#0F172A' }}>
                    Registro Cronológico de Coordenadas
                  </h4>

                  {(!tripHistory?.gpsRecords || tripHistory.gpsRecords.length === 0) ? (
                    <div className="empty-machines-banner" style={{ padding: '20px' }}>
                      <Navigation size={28} />
                      <span style={{ fontSize: '13px', fontWeight: 600 }}>Sin coordenadas GPS</span>
                      <p style={{ fontSize: '11px', color: '#64748B' }}>
                        El transportador aún no ha enviado telemetría desde la app móvil.
                      </p>
                    </div>
                  ) : (
                    <div className="gps-timeline">
                      {tripHistory.gpsRecords.map((record: any, index: number) => (
                        <div key={record.id || index} className="gps-timeline-item">
                          <div className="gps-timeline-point" />
                          <div className="gps-timeline-header">
                            <span className="gps-coords-pill">
                              <MapPin size={11} /> {record.latitude.toFixed(6)}, {record.longitude.toFixed(6)}
                            </span>
                            <span style={{ fontSize: '11px', color: '#64748B' }}>
                              {record.recordedAt ? new Date(record.recordedAt).toLocaleTimeString('es-CO') : ''}
                            </span>
                          </div>
                          <span style={{ fontSize: '11px', color: '#475569' }}>
                            Punto de control satelital #{index + 1}
                          </span>
                        </div>
                      ))}
                    </div>
                  )}

                  {/* Incidencias si existen */}
                  {tripHistory?.incidents && tripHistory.incidents.length > 0 && (
                    <div style={{ marginTop: '20px' }}>
                      <h4 style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px', color: '#B91C1C' }}>
                        <ShieldAlert size={16} /> Incidencias Reportadas en Ruta
                      </h4>
                      {tripHistory.incidents.map((inc: any) => (
                        <div
                          key={inc.id}
                          style={{
                            padding: '10px 14px',
                            backgroundColor: '#FEF2F2',
                            border: '1px solid #FECACA',
                            borderRadius: '8px',
                            marginTop: '8px',
                          }}
                        >
                          <strong style={{ fontSize: '12px', color: '#991B1B' }}>
                            {inc.description}
                          </strong>
                          <span style={{ display: 'block', fontSize: '10px', color: '#B91C1C', marginTop: '4px' }}>
                            Reportado el {new Date(inc.reportedAt).toLocaleString('es-CO')}
                          </span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}
            </div>

            <div className="modal-footer">
              <button
                type="button"
                className="btn-secondary"
                onClick={() => setSelectedTrip(null)}
              >
                Cerrar
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default TrackingPage;
