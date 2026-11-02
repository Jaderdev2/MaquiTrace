import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { useAuth } from '../../context/AuthContext';
import {
  fetchTripsApi,
  fetchActiveTripsApi,
  receiveTransportApi,
  updateTransportApi,
  deleteTransportApi,
  fetchMachinesApi,
  fetchUsersApi,
} from '../../services/api';
import type { TransportTrip, Machine, User } from '../../types';
import { Sidebar } from '../../components/Sidebar';
import { Navbar } from '../../components/Navbar';
import { TrackingMap } from './components/TrackingMap';
import { NewTripModal } from './components/NewTripModal';
import { EditTripModal } from './components/EditTripModal';
import { TripDetailsModal } from './components/TripDetailsModal';
import { MOCK_TRIPS } from './mockTrackingData';
import { getTripColorTheme, TRIP_PALETTE } from './utils/tripColors';
import { checkMachineTransitReadiness } from './utils/transitValidation';
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
  ShieldAlert,
  Plus,
  Map,
  LayoutGrid,
  Info,
  Radio,
  SlidersHorizontal,
  User as UserIcon,
  Edit3,
  Trash2,
} from 'lucide-react';
import '../../styles/machines.css';
import '../../styles/tracking.css';

export const TrackingPage: React.FC = () => {
  const { token } = useAuth();
  const [trips, setTrips] = useState<TransportTrip[]>([]);
  const [machines, setMachines] = useState<Machine[]>([]);
  const [transporters, setTransporters] = useState<User[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [successBanner, setSuccessBanner] = useState<string | null>(null);
  const [sidebarOpen, setSidebarOpen] = useState<boolean>(false);
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<string>('todos');

  // Modo de visualización: 'split' (mapa arriba + tarjetas), 'map' (mapa completo), 'cards' (solo tarjetas)
  const [viewMode, setViewMode] = useState<'split' | 'map' | 'cards'>('split');

  // Estado para saber si estamos usando datos de demostración o datos reales de la nube
  const [isDemoMode, setIsDemoMode] = useState<boolean>(false);

  // Modales
  const [isNewTripModalOpen, setIsNewTripModalOpen] = useState<boolean>(false);
  const [selectedTrip, setSelectedTrip] = useState<TransportTrip | null>(null);
  const [editingTrip, setEditingTrip] = useState<TransportTrip | null>(null);
  const [actionLoading, setActionLoading] = useState<boolean>(false);

  // Carga de datos principales desde la API o Fallback MOCK
  const loadData = useCallback(async () => {
    if (!token) return;
    try {
      setLoading(true);
      setError(null);

      const [tripsData, machinesData, usersData] = await Promise.all([
        fetchTripsApi(token).catch(() => fetchActiveTripsApi(token).catch(() => [])),
        fetchMachinesApi(token).catch(() => []),
        fetchUsersApi('transportador', token).catch(() => []),
      ]);

      setMachines(machinesData);
      setTransporters(usersData);

      // Si la API remota devuelve viajes creados, los cargamos
      if (tripsData && tripsData.length > 0) {
        const enriched = tripsData.map((t, idx) => ({
          ...t,
          color: t.color || TRIP_PALETTE[idx % TRIP_PALETTE.length].primary,
        }));
        setTrips(enriched);
        setIsDemoMode(false);
      } else {
        const enriched = MOCK_TRIPS.map((t, idx) => ({
          ...t,
          color: t.color || TRIP_PALETTE[idx % TRIP_PALETTE.length].primary,
        }));
        setTrips(enriched);
        setIsDemoMode(true);
      }
    } catch (err: any) {
      setError(err.message || 'Error al conectar con el servicio de transporte.');
      const enriched = MOCK_TRIPS.map((t, idx) => ({
        ...t,
        color: t.color || TRIP_PALETTE[idx % TRIP_PALETTE.length].primary,
      }));
      setTrips(enriched);
      setIsDemoMode(true);
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Alternar manualmente entre datos de demostración y datos de la nube
  const handleToggleDemoData = () => {
    if (isDemoMode) {
      setIsDemoMode(false);
      loadData();
    } else {
      const enriched = MOCK_TRIPS.map((t, idx) => ({
        ...t,
        color: t.color || TRIP_PALETTE[idx % TRIP_PALETTE.length].primary,
      }));
      setTrips(enriched);
      setIsDemoMode(true);
      setSuccessBanner('Datos de demostración activados.');
      setTimeout(() => setSuccessBanner(null), 3500);
    }
  };

  // Programar nuevo viaje (Create)
  const handleCreateTrip = async (
    machineId: string,
    vehicle: string,
    destination: string,
    transporterId: string
  ) => {
    if (!token) return;
    setActionLoading(true);
    try {
      if (isDemoMode) {
        const foundMachine = machines.find((machine) => machine.id === machineId);
        const foundTransporter = transporters.find((transporter) => transporter.id === transporterId);
        const newTripId = `trip-${Date.now()}`;
        setTrips((prev) => [
          {
            id: newTripId,
            machineId,
            color: TRIP_PALETTE[prev.length % TRIP_PALETTE.length].primary,
            vehicle,
            destination,
            status: 'pendiente',
            transporterId,
            transporter: foundTransporter
              ? { name: foundTransporter.name, email: foundTransporter.email, phone: foundTransporter.phone || '' }
              : undefined,
            machine: foundMachine,
            gpsRecords: [],
            incidents: [],
          },
          ...prev,
        ]);
      } else {
        await receiveTransportApi(machineId, { vehicle, destination, transporterId }, token);
        await loadData();
      }

      setSuccessBanner('¡Viaje programado con éxito en el sistema de despacho!');
      setTimeout(() => setSuccessBanner(null), 4500);
    } catch (err: any) {
      setError(err.message || 'Error al programar el viaje.');
    } finally {
      setActionLoading(false);
    }
  };

  // Actualizar viaje (Update)
  const handleUpdateTrip = async (
    tripId: string,
    payload: { vehicle?: string; destination?: string; transporterId?: string }
  ) => {
    if (!token) return;
    setActionLoading(true);
    try {
      if (isDemoMode) {
        setTrips((prev) =>
          prev.map((trip) =>
            trip.id === tripId
              ? {
                  ...trip,
                  ...payload,
                  transporter:
                    transporters.find((transporter) => transporter.id === payload.transporterId) ??
                    trip.transporter,
                }
              : trip
          )
        );
      } else {
        const updatedTrip = await updateTransportApi(tripId, payload, token);
        setTrips((prev) => prev.map((trip) => (trip.id === tripId ? updatedTrip : trip)));
        if (selectedTrip?.id === tripId) setSelectedTrip(updatedTrip);
      }

      setSuccessBanner('¡Viaje de transporte actualizado exitosamente!');
      setTimeout(() => setSuccessBanner(null), 4000);
      setEditingTrip(null);
    } catch (err: any) {
      setError(err.message || 'Error al actualizar el viaje.');
    } finally {
      setActionLoading(false);
    }
  };

  // Eliminar viaje (Delete)
  const handleDeleteTrip = async (tripId: string) => {
    if (!token) return;
    setActionLoading(true);
    try {
      if (isDemoMode) {
        setTrips((prev) => prev.filter((trip) => trip.id !== tripId));
        if (selectedTrip?.id === tripId) setSelectedTrip(null);
        if (editingTrip?.id === tripId) setEditingTrip(null);
      } else {
        await deleteTransportApi(tripId, token);
        await loadData();
      }

      setSuccessBanner('Registro de transporte eliminado del sistema.');
      setTimeout(() => setSuccessBanner(null), 4000);
    } catch (err: any) {
      setError(err.message || 'Error al eliminar el viaje.');
    } finally {
      setActionLoading(false);
    }
  };

  // Métricas
  const totalTrips = trips.length;
  const inTransitTrips = trips.filter((t) => t.status === 'en_transito').length;
  const pendingTrips = trips.filter((t) => t.status === 'pendiente').length;
  const deliveredTrips = trips.filter((t) => t.status === 'entregado').length;
  const totalIncidents = trips.reduce((acc, t) => acc + (t.incidents?.length || 0), 0);

  // Filtrado reactivo
  const filteredTrips = useMemo(() => {
    return trips.filter((t) => {
      if (statusFilter !== 'todos' && t.status !== statusFilter) return false;
      if (!searchTerm.trim()) return true;
      const q = searchTerm.toLowerCase();
      const dest = t.destination?.toLowerCase() || '';
      const vehicle = t.vehicle?.toLowerCase() || '';
      const driver = t.transporter?.name?.toLowerCase() || '';
      const machine = t.machine ? `${t.machine.model} ${t.machine.serial}`.toLowerCase() : '';
      return dest.includes(q) || vehicle.includes(q) || driver.includes(q) || machine.includes(q);
    });
  }, [trips, statusFilter, searchTerm]);

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
          {/* Cabecera Principal */}
          <div className="machines-header-row">
            <div className="machines-title-box">
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <h1>Seguimiento y Trazabilidad Satelital</h1>
                {isDemoMode && (
                  <span className="demo-badge-pill" title="Mostrando datos genéricos de ejemplo sincronizables con la app móvil">
                    <Radio size={11} className="pulse-icon" /> Datos de Demostración
                  </span>
                )}
              </div>
              <span className="machines-title-sub">
                Monitoreo GPS en tiempo real de viajes de transporte, telemetría de ruta y control de entrega en obra.
              </span>
            </div>

            <div className="machines-actions-group">
              <button
                type="button"
                className="btn-toggle-demo"
                onClick={handleToggleDemoData}
                title="Alternar entre datos de demostración y nube"
              >
                <SlidersHorizontal size={14} />
                <span>{isDemoMode ? 'Ver datos de Nube' : 'Cargar datos Demo'}</span>
              </button>

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
                className="btn-primary-register"
                onClick={() => setIsNewTripModalOpen(true)}
              >
                <Plus size={16} />
                <span>Programar Despacho</span>
              </button>
            </div>
          </div>

          {/* Banners informativos */}
          {isDemoMode && (
            <div className="tracking-demo-notice">
              <Info size={16} className="notice-icon" />
              <span>
                <strong>Entorno de Demostración Activo:</strong> Se han cargado viajes y coordenadas de ejemplo en Colombia para visualizar el mapa en vivo y probar la telemetría mientras tu compañero finaliza la integración en la aplicación móvil.
              </span>
            </div>
          )}

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
                <span className="machine-kpi-label">Total de Viajes</span>
              </div>
            </div>

            <div className="machine-kpi-card">
              <div className="machine-kpi-icon icon-purple">
                <Navigation size={22} />
              </div>
              <div className="machine-kpi-data">
                <span className="machine-kpi-num">{loading ? '...' : inTransitTrips}</span>
                <span className="machine-kpi-label">En Tránsito en Vivo</span>
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

            <div className="machine-kpi-card">
              <div className="machine-kpi-icon" style={{ backgroundColor: '#FEF2F2', color: '#DC2626' }}>
                <ShieldAlert size={22} />
              </div>
              <div className="machine-kpi-data">
                <span className="machine-kpi-num">{loading ? '...' : totalIncidents}</span>
                <span className="machine-kpi-label">Novedades en Ruta</span>
              </div>
            </div>
          </div>

          {/* Barra de Filtros y Selector de Vista (Mapa / Cuadrícula) */}
          <div className="machines-filters-bar tracking-filters-bar">
            <div className="filter-search-box">
              <Search size={16} className="filter-search-icon" />
              <input
                type="text"
                placeholder="Buscar por vehículo, placa, conductor o destino..."
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

              {/* Botones de Vista (Split, Mapa Completo, Tarjetas) */}
              <div className="view-mode-toggle-group">
                <button
                  type="button"
                  className={`btn-view-mode ${viewMode === 'split' ? 'active' : ''}`}
                  onClick={() => setViewMode('split')}
                  title="Vista combinada: Mapa y Tarjetas"
                >
                  <Map size={14} />
                  <span>Combinada</span>
                </button>
                <button
                  type="button"
                  className={`btn-view-mode ${viewMode === 'map' ? 'active' : ''}`}
                  onClick={() => setViewMode('map')}
                  title="Vista Mapa Completo"
                >
                  <Navigation size={14} />
                  <span>Mapa</span>
                </button>
                <button
                  type="button"
                  className={`btn-view-mode ${viewMode === 'cards' ? 'active' : ''}`}
                  onClick={() => setViewMode('cards')}
                  title="Vista Lista de Tarjetas"
                >
                  <LayoutGrid size={14} />
                  <span>Tarjetas</span>
                </button>
              </div>
            </div>
          </div>

          {/* Sección de Mapa Interactivo Leaflet (Visible en 'split' y 'map') */}
          {(viewMode === 'split' || viewMode === 'map') && (
            <div className="tracking-map-section">
              <div className="map-section-header">
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <Navigation size={16} color="#0066FF" />
                  <h3>Monitoreo Satelital de Flota en Vivo</h3>
                </div>
                <span className="map-section-sub">
                  Haz clic en cualquier camión para ver sus Detalles o trazar su Ruta en el mapa.
                </span>
              </div>

              <TrackingMap
                trips={filteredTrips}
                selectedTripId={selectedTrip?.id}
                onSelectTrip={(t) => setSelectedTrip(t)}
                onOpenDetails={(t) => setSelectedTrip(t)}
                height={viewMode === 'map' ? '680px' : '460px'}
              />
            </div>
          )}

          {/* Listado de Tarjetas de Viaje (Visible en 'split' y 'cards') */}
          {(viewMode === 'split' || viewMode === 'cards') && (
            <div style={{ marginTop: '24px' }}>
              <div className="section-title-strip">
                <h3>Viajes de Transporte y Despacho ({filteredTrips.length})</h3>
                <span className="section-subtitle">
                  Control de bitácora, maquinaria asignada, conductor y evidencias fotográficas.
                </span>
              </div>

              {filteredTrips.length === 0 ? (
                <div className="empty-machines-banner">
                  <Navigation size={36} />
                  <span className="empty-machines-title">No hay viajes que coincidan con la búsqueda</span>
                  <p className="empty-machines-sub">
                    Intenta cambiar los filtros o programa un nuevo despacho usando el botón superior.
                  </p>
                </div>
              ) : (
                <div className="machines-card-grid tracking-cards-grid">
                  {filteredTrips.map((trip, index) => {
                    const machine = trip.machine || machines.find((m) => m.id === trip.machineId);
                    const isTransit = trip.status === 'en_transito';
                    const isDelivered = trip.status === 'entregado';
                    const gpsCount = trip.gpsRecords?.length || 0;
                    const incidentsCount = trip.incidents?.length || 0;

                    // Color único asignado a este transporte
                    const theme = getTripColorTheme(trip, index);
                    const driver = trip.transporter;
                    const readiness = checkMachineTransitReadiness(machine);

                    return (
                      <div
                        key={trip.id}
                        className={`tracking-trip-card ${selectedTrip?.id === trip.id ? 'is-selected-card' : ''}`}
                        style={{
                          borderTopColor: theme.primary,
                          ['--card-theme-color' as any]: theme.primary,
                          ['--card-theme-glow' as any]: theme.glow,
                          boxShadow: selectedTrip?.id === trip.id ? `0 0 0 3px ${theme.glow}` : undefined,
                        }}
                      >
                        {/* Cabecera de la Tarjeta con Vehículo y Estado */}
                        <div className="tracking-trip-header">
                          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                            <div
                              className="trip-vehicle-icon-box"
                              style={{
                                backgroundColor: theme.light,
                                color: theme.primary,
                                borderColor: theme.border,
                              }}
                            >
                              <Truck size={20} />
                            </div>
                            <div>
                              <strong className="trip-card-vehicle-name">{trip.vehicle || 'Vehículo de Carga'}</strong>
                              <span className="trip-card-dest-sub">
                                <MapPin size={11} style={{ display: 'inline', marginRight: '3px' }} />
                                {trip.destination}
                              </span>
                            </div>
                          </div>

                          <div className="tracking-trip-badge-row">
                            {/* Badge con el Color Distintivo (Idéntico al del Modal y Mapa) */}
                            <span
                              className="popup-badge"
                              style={{
                                backgroundColor: theme.badgeBg,
                                color: theme.badgeText,
                                fontWeight: 700,
                                fontSize: '11px',
                                padding: '3px 8px',
                                borderRadius: '6px',
                              }}
                              title={`Color de trazado y telemetría: ${theme.name}`}
                            >
                              {theme.name}
                            </span>

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

                            {/* Acciones Rápidas CRUD: Editar y Eliminar */}
                            <div className="card-quick-actions-group">
                              <button
                                type="button"
                                className="btn-card-action-icon edit-action"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  setEditingTrip(trip);
                                }}
                                title="Editar viaje de transporte"
                              >
                                <Edit3 size={13} />
                              </button>
                              <button
                                type="button"
                                className="btn-card-action-icon delete-action"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  handleDeleteTrip(trip.id);
                                }}
                                title="Eliminar registro de viaje"
                              >
                                <Trash2 size={13} />
                              </button>
                            </div>
                          </div>
                        </div>

                        <div className="tracking-trip-body">
                          {/* Resumen de Maquinaria Transportada y Validación de Alistamiento */}
                          <div className="trip-card-section-box">
                            <span className="trip-card-section-label">Maquinaria Transportada</span>
                            <div className="trip-card-section-content">
                              <span className="trip-machine-label-text">
                                {machine ? `${machine.model} (${machine.serial})` : 'Maquinaria Asignada'}
                              </span>
                              <span className="pill-badge pill-status-ready" style={{ fontSize: '10.5px' }}>
                                {machine?.category || 'Pesada'}
                              </span>
                            </div>

                            {/* Estado de Alistamiento en Taller */}
                            <div style={{ marginTop: '5px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                              <span
                                className={`trip-card-prep-badge ${readiness.canDepart ? 'prep-ready' : 'prep-warning'}`}
                                title={readiness.reason}
                              >
                                {readiness.badgeLabel}
                              </span>
                            </div>
                          </div>

                          {/* Conductor Asignado */}
                          <div className="trip-card-section-box">
                            <span className="trip-card-section-label">Conductor Asignado</span>
                            <div className="trip-card-section-content">
                              <span className="trip-driver-name-text">
                                <UserIcon size={14} color={theme.primary} />
                                {driver?.name || 'Conductor Oficial'}
                              </span>
                              <span style={{ fontSize: '11px', color: '#64748B' }}>
                                {driver?.licenseType ? driver.licenseType.split(' ')[1] || 'C3' : 'C3'}
                              </span>
                            </div>
                          </div>

                          {/* Metadatos Rápidos: Salida y Telemetría */}
                          <div className="tracking-info-grid">
                            <div className="tracking-info-item">
                              <span className="tracking-info-label">Fecha / Salida</span>
                              <span className="tracking-info-val">
                                <Calendar size={13} style={{ display: 'inline', marginRight: '3px' }} />
                                {trip.departureAt ? new Date(trip.departureAt).toLocaleDateString('es-CO') : 'Pendiente'}
                              </span>
                            </div>

                            <div className="tracking-info-item">
                              <span className="tracking-info-label">Puntos Satelitales</span>
                              <span className="tracking-info-val">
                                <Radio size={13} style={{ display: 'inline', marginRight: '3px', color: theme.primary }} />
                                {gpsCount} waypoints en ruta
                              </span>
                            </div>
                          </div>

                          {/* Alerta de Novedades si existen */}
                          {incidentsCount > 0 && (
                            <div className="trip-card-incident-pill">
                              <ShieldAlert size={13} />
                              <span>{incidentsCount} {incidentsCount === 1 ? 'novedad reportada' : 'novedades reportadas'}</span>
                            </div>
                          )}

                          {/* Botones de acción operativos con bloqueo condicional */}
                          <div className="card-action-footer mt-2">
                            <div className="card-actions-row">
                              <button
                                type="button"
                                className="btn-card-details"
                                onClick={() => setSelectedTrip(trip)}
                                style={{
                                  borderColor: theme.primary,
                                  color: theme.primary,
                                }}
                              >
                                <Eye size={14} />
                                <span>Ver Detalles y Ruta Satelital</span>
                              </button>

                            </div>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          )}
        </main>
      </div>

      {/* Modal para Programar Nuevo Despacho */}
      <NewTripModal
        isOpen={isNewTripModalOpen}
        onClose={() => setIsNewTripModalOpen(false)}
        machines={machines}
        transporters={transporters}
        existingTrips={trips}
        onSubmit={handleCreateTrip}
        loading={actionLoading}
      />

      {/* Modal para Editar Viaje de Transporte */}
      {editingTrip && (
        <EditTripModal
          trip={editingTrip}
          isOpen={true}
          onClose={() => setEditingTrip(null)}
          transporters={transporters}
          onUpdate={handleUpdateTrip}
          onDelete={handleDeleteTrip}
          loading={actionLoading}
        />
      )}

      {/* Modal de Detalles del Viaje, Telemetría GPS, Maquinaria, Conductor y Evidencias */}
      {selectedTrip && (
        <TripDetailsModal
          trip={selectedTrip}
          machine={selectedTrip.machine || machines.find((m) => m.id === selectedTrip.machineId)}
          onClose={() => setSelectedTrip(null)}
          onEdit={() => {
            const tripToEdit = selectedTrip;
            setSelectedTrip(null);
            setEditingTrip(tripToEdit);
          }}
          actionLoading={actionLoading}
        />
      )}
    </div>
  );
};

export default TrackingPage;
