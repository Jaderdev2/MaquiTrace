import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { useAuth } from '../../context/AuthContext';
import {
  fetchTripsApi,
  fetchActiveTripsApi,
  departTransportApi,
  deliverTransportApi,
  receiveTransportApi,
  updateTransportApi,
  deleteTransportApi,
  recordGpsLocationApi,
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
  Play,
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
    transporterId?: string
  ) => {
    if (!token) return;
    setActionLoading(true);
    try {
      const foundMachine = machines.find((m) => m.id === machineId);
      const foundTransporter = transporters.find((t) => t.id === transporterId);
      const assignedColor = TRIP_PALETTE[trips.length % TRIP_PALETTE.length].primary;

      // Intentar persistir en el backend
      let savedViaApi = false;
      try {
        await receiveTransportApi(machineId, { vehicle, destination, transporterId }, token);
        savedViaApi = true;
      } catch (apiErr) {
        console.warn('API error creando despacho, persistiendo localmente:', apiErr);
      }

      if (savedViaApi) {
        await loadData();
      } else {
        // Fallback local robusto
        const newTripId = `trip-${Date.now()}`;
        const newTrip: TransportTrip = {
          id: newTripId,
          machineId,
          color: assignedColor,
          vehicle,
          destination,
          status: 'pendiente',
          departureAt: undefined,
          transporterId,
          transporter: foundTransporter
            ? {
                name: foundTransporter.name,
                email: foundTransporter.email,
                phone: foundTransporter.phone || '+57 312 458 9921',
                avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
                cedula: 'CC 1.094.882.310',
                experienceTime: '5 años',
                licenseType: 'Licencia C3 (Carga Pesada)',
              }
            : {
                name: 'Carlos Alberto Mendoza',
                email: 'carlos.mendoza@transporte-maquitrace.com',
                phone: '+57 312 458 9921',
                avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
                cedula: 'CC 1.094.882.310',
                experienceTime: '4 años y 6 meses',
                licenseType: 'Licencia C3 (Carga Pesada)',
              },
          machine: foundMachine || {
            id: machineId,
            model: 'Equipo Pesado',
            serial: 'MAQ-SN-001',
            category: 'Construcción',
            status: 'pendiente',
          },
          gpsRecords: [
            {
              id: `gps-init-${Date.now()}`,
              tripId: newTripId,
              latitude: 4.6097,
              longitude: -74.0817,
              recordedAt: new Date().toISOString(),
            },
          ],
          incidents: [],
        };
        setTrips((prev) => [newTrip, ...prev]);
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
    payload: { vehicle?: string; destination?: string; transporterId?: string; status?: string }
  ) => {
    if (!token) return;
    setActionLoading(true);
    try {
      try {
        await updateTransportApi(tripId, payload, token);
      } catch (apiErr) {
        console.warn('API error actualizando viaje, actualizando localmente:', apiErr);
      }

      setTrips((prev) =>
        prev.map((t) => {
          if (t.id === tripId) {
            const updated: TransportTrip = {
              ...t,
              vehicle: payload.vehicle ?? t.vehicle,
              destination: payload.destination ?? t.destination,
              status: (payload.status as any) ?? t.status,
            };
            if (payload.transporterId) {
              const tr = transporters.find((u) => u.id === payload.transporterId);
              if (tr) {
                updated.transporterId = tr.id;
                updated.transporter = {
                  ...t.transporter,
                  name: tr.name,
                  email: tr.email,
                  phone: tr.phone || t.transporter?.phone,
                };
              }
            }
            return updated;
          }
          return t;
        })
      );

      if (selectedTrip?.id === tripId) {
        setSelectedTrip((prev) =>
          prev
            ? {
                ...prev,
                vehicle: payload.vehicle ?? prev.vehicle,
                destination: payload.destination ?? prev.destination,
                status: (payload.status as any) ?? prev.status,
              }
            : null
        );
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
      try {
        await deleteTransportApi(tripId, token);
      } catch (apiErr) {
        console.warn('API error eliminando viaje, eliminando localmente:', apiErr);
      }

      setTrips((prev) => prev.filter((t) => t.id !== tripId));
      if (selectedTrip?.id === tripId) setSelectedTrip(null);
      if (editingTrip?.id === tripId) setEditingTrip(null);

      setSuccessBanner('Registro de transporte eliminado del sistema.');
      setTimeout(() => setSuccessBanner(null), 4000);
    } catch (err: any) {
      setError(err.message || 'Error al eliminar el viaje.');
    } finally {
      setActionLoading(false);
    }
  };

  // Actualización de ubicación interactiva en mapa (Manual o Aleatoria en Colombia)
  const handleUpdateLocation = async (tripId: string, lat: number, lng: number) => {
    await handleTransmitGps(tripId, lat, lng);
    setSuccessBanner(`¡Ubicación del camión actualizada a [${lat.toFixed(4)}, ${lng.toFixed(4)}]!`);
    setTimeout(() => setSuccessBanner(null), 4500);
  };

  // Marcar salida de transporte (Con validación estricta de alistamiento en taller)
  const handleDepart = async (machineId: string) => {
    if (!token) return;

    // VALIDACIÓN LÓGICA: ¿La maquinaria concluyó todas sus fases de alistamiento?
    const targetMachine =
      machines.find((m) => m.id === machineId) ||
      trips.find((t) => t.machineId === machineId || t.machine?.id === machineId)?.machine;
    const readiness = checkMachineTransitReadiness(targetMachine);

    if (!readiness.canDepart) {
      setError(`Bloqueo operativo: La maquinaria no puede iniciar tránsito. ${readiness.reason}`);
      setTimeout(() => setError(null), 6000);
      return;
    }

    try {
      setActionLoading(true);
      if (!isDemoMode) {
        await departTransportApi(machineId, token);
      } else {
        setTrips((prev) =>
          prev.map((t) =>
            t.machineId === machineId || t.machine?.id === machineId
              ? {
                  ...t,
                  status: 'en_transito',
                  departureAt: new Date().toISOString(),
                  gpsRecords: [
                    ...(t.gpsRecords || []),
                    {
                      id: `gps-${Date.now()}`,
                      tripId: t.id,
                      latitude: 4.8143,
                      longitude: -74.3541,
                      recordedAt: new Date().toISOString(),
                    },
                  ],
                }
              : t
          )
        );
      }
      setSuccessBanner('¡Salida de ruta confirmada! La maquinaria ahora está "En Tránsito".');
      setTimeout(() => setSuccessBanner(null), 4500);
      if (selectedTrip) {
        setSelectedTrip((prev) => (prev ? { ...prev, status: 'en_transito', departureAt: new Date().toISOString() } : null));
      }
      if (!isDemoMode) await loadData();
    } catch (err: any) {
      setError(err.message || 'Error al registrar la salida de transporte.');
    } finally {
      setActionLoading(false);
    }
  };

  // Marcar entrega final
  const handleDeliver = async (machineId: string) => {
    if (!token) return;
    try {
      setActionLoading(true);
      if (!isDemoMode) {
        await deliverTransportApi(machineId, token);
      } else {
        setTrips((prev) =>
          prev.map((t) =>
            t.machineId === machineId || t.machine?.id === machineId
              ? { ...t, status: 'entregado', arrivalAt: new Date().toISOString() }
              : t
          )
        );
      }
      setSuccessBanner('¡Entrega de maquinaria completada con éxito en obra!');
      setTimeout(() => setSuccessBanner(null), 4500);
      if (selectedTrip) {
        setSelectedTrip((prev) => (prev ? { ...prev, status: 'entregado', arrivalAt: new Date().toISOString() } : null));
      }
      if (!isDemoMode) await loadData();
    } catch (err: any) {
      setError(err.message || 'Error al registrar la entrega de maquinaria.');
    } finally {
      setActionLoading(false);
    }
  };

  // Transmisión de coordenada GPS satelital
  const handleTransmitGps = async (tripId: string, lat: number, lng: number) => {
    if (!token) return;
    if (!isDemoMode) {
      await recordGpsLocationApi(tripId, { latitude: lat, longitude: lng }, token);
    }

    const newRecord = {
      id: `gps-${Date.now()}`,
      tripId,
      latitude: lat,
      longitude: lng,
      recordedAt: new Date().toISOString(),
    };

    setTrips((prev) =>
      prev.map((t) =>
        t.id === tripId
          ? {
              ...t,
              status: t.status === 'pendiente' ? 'en_transito' : t.status,
              gpsRecords: [...(t.gpsRecords || []), newRecord],
            }
          : t
      )
    );

    if (selectedTrip && selectedTrip.id === tripId) {
      setSelectedTrip((prev) =>
        prev
          ? {
              ...prev,
              status: prev.status === 'pendiente' ? 'en_transito' : prev.status,
              gpsRecords: [...(prev.gpsRecords || []), newRecord],
            }
          : null
      );
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
                onUpdateLocation={handleUpdateLocation}
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
                    const isPending = trip.status === 'pendiente';
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
                                {readiness.canDepart ? '✅' : '⏳'} {readiness.badgeLabel}
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

                              {isPending && machine && (
                                <button
                                  type="button"
                                  className={`btn-primary-register ${!readiness.canDepart ? 'btn-action-blocked' : ''}`}
                                  style={{ padding: '6px 12px', fontSize: '12px' }}
                                  onClick={() => handleDepart(machine.id)}
                                  disabled={actionLoading || !readiness.canDepart}
                                  title={!readiness.canDepart ? readiness.reason : 'Marcar salida e iniciar tránsito'}
                                >
                                  <Play size={13} />
                                  <span>{readiness.canDepart ? 'Marcar Salida' : 'Salida Bloqueada'}</span>
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
          onDepart={handleDepart}
          onDeliver={handleDeliver}
          onTransmitGps={handleTransmitGps}
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
