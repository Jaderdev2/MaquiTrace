import React, { useState } from 'react';
import type { TransportTrip, Machine, Evidence } from '../../../types';
import { getTripColorTheme } from '../utils/tripColors';
import { getMachinePrimaryPhoto } from '../../../utils/evidence';
import { EvidenceViewerModal } from './EvidenceViewerModal';
import {
  Navigation,
  MapPin,
  Truck,
  ShieldAlert,
  CheckCircle2,
  Play,
  X,
  Loader2,
  Radio,
  User,
  CreditCard,
  Clock,
  Award,
  Phone,
  Mail,
  Camera,
  Layers,
} from 'lucide-react';

interface TripDetailsModalProps {
  trip: TransportTrip;
  machine?: Machine | null;
  onClose: () => void;
  onDepart: (machineId: string) => Promise<void>;
  onDeliver: (machineId: string) => Promise<void>;
  onTransmitGps: (tripId: string, lat: number, lng: number) => Promise<void>;
  actionLoading: boolean;
}

export const TripDetailsModal: React.FC<TripDetailsModalProps> = ({
  trip,
  machine,
  onClose,
  onDepart,
  onDeliver,
  onTransmitGps,
  actionLoading,
}) => {
  const [gpsSimulating, setGpsSimulating] = useState(false);
  const [simMessage, setSimMessage] = useState<string | null>(null);

  // Estado para el visor de fotos de evidencia en alta resolución
  const [viewerIndex, setViewerIndex] = useState<number | null>(null);

  const isPending = trip.status === 'pendiente';
  const isTransit = trip.status === 'en_transito';
  const isDelivered = trip.status === 'entregado';

  const theme = getTripColorTheme(trip);
  const driver = trip.transporter;
  const machinePhoto = machine ? getMachinePrimaryPhoto(machine) : null;
  const evidences: Evidence[] = machine?.evidence || trip.evidence || [];

  const gpsRecords = trip.gpsRecords || [];
  const incidents = trip.incidents || [];

  // Coordenadas simuladas realistas por carreteras nacionales desde Buenaventura
  const sampleWaypoints = [
    { name: 'Buenaventura (Puerto Marítimo TCBUEN)', lat: 3.8826, lng: -77.0311 },
    { name: 'Loboguerrero (Cañón de Dagua - Vía al Mar)', lat: 3.7663, lng: -76.6610 },
    { name: 'Buga (Troncal del Valle - Ruta 25)', lat: 3.9009, lng: -76.2978 },
    { name: 'Tuluá (Estación de Pesaje e Industrial)', lat: 4.0847, lng: -76.1954 },
    { name: 'Cartago (Límite Valle del Cauca - Risaralda)', lat: 4.7464, lng: -75.9117 },
    { name: 'Túnel de La Línea (Paso Cordillera Central)', lat: 4.4851, lng: -75.5214 },
    { name: 'Ibagué (Variante Tolima)', lat: 4.4389, lng: -75.2322 },
    { name: 'La Pintada (Entrada Suroeste Antioqueño)', lat: 5.7481, lng: -75.6052 },
    { name: 'Medellín (Destino Obra Pacífico)', lat: 6.2442, lng: -75.5812 },
    { name: 'Cali (Destino Zona Industrial Acopi)', lat: 3.4542, lng: -76.5458 },
    { name: 'Bogotá (Destino Fontibón)', lat: 4.6712, lng: -74.1421 },
  ];

  const handleSimulateGps = async () => {
    setGpsSimulating(true);
    setSimMessage(null);
    try {
      const nextIndex = gpsRecords.length % sampleWaypoints.length;
      const targetPoint = sampleWaypoints[nextIndex];

      const randomOffsetLat = (Math.random() - 0.5) * 0.01;
      const randomOffsetLng = (Math.random() - 0.5) * 0.01;
      const lat = Number((targetPoint.lat + randomOffsetLat).toFixed(4));
      const lng = Number((targetPoint.lng + randomOffsetLng).toFixed(4));

      await onTransmitGps(trip.id, lat, lng);
      setSimMessage(`¡Punto satelital emitido: ${lat}, ${lng} (${targetPoint.name})!`);
      setTimeout(() => setSimMessage(null), 4000);
    } catch (err: any) {
      setSimMessage(`Error: ${err.message || 'No se pudo transmitir punto GPS'}`);
    } finally {
      setGpsSimulating(false);
    }
  };

  return (
    <>
      <div className="modal-backdrop" onClick={onClose}>
        <div className="modal-content trip-details-modal-content" onClick={(e) => e.stopPropagation()}>
          {/* Cabecera del Modal con Color Distintivo */}
          <div className="modal-header" style={{ borderTop: `4px solid ${theme.primary}` }}>
            <div className="modal-header-title">
              <div
                className="register-modal-icon-badge"
                style={{ backgroundColor: theme.light, color: theme.primary }}
              >
                <Truck size={20} />
              </div>
              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <h3 style={{ margin: 0 }}>Detalles del Servicio de Transporte</h3>
                  <span
                    className="popup-badge"
                    style={{ backgroundColor: theme.badgeBg, color: theme.badgeText }}
                  >
                    {theme.name}
                  </span>
                </div>
                <span className="modal-header-sub">
                  {trip.vehicle} · Obra: {trip.destination}
                </span>
              </div>
            </div>
            <button className="btn-close" onClick={onClose}>
              <X size={20} />
            </button>
          </div>

          <div className="modal-body trip-details-body">
            {/* Stepper de progreso del viaje */}
            <div className="trip-stepper-bar">
              <div className={`stepper-step ${isPending || isTransit || isDelivered ? 'completed' : ''}`}>
                <div className="step-circle" style={{ backgroundColor: isPending || isTransit || isDelivered ? theme.primary : undefined }}>
                  1
                </div>
                <span className="step-label">Recepción / Asignado</span>
              </div>
              <div className={`stepper-line ${isTransit || isDelivered ? 'active' : ''}`} style={{ backgroundColor: isTransit || isDelivered ? theme.primary : undefined }} />
              <div className={`stepper-step ${isTransit || isDelivered ? 'completed' : ''}`}>
                <div className="step-circle" style={{ backgroundColor: isTransit || isDelivered ? theme.primary : undefined }}>
                  2
                </div>
                <span className="step-label">En Tránsito Satelital</span>
              </div>
              <div className={`stepper-line ${isDelivered ? 'active' : ''}`} style={{ backgroundColor: isDelivered ? theme.primary : undefined }} />
              <div className={`stepper-step ${isDelivered ? 'completed' : ''}`}>
                <div className="step-circle" style={{ backgroundColor: isDelivered ? theme.primary : undefined }}>
                  3
                </div>
                <span className="step-label">Entregado en Obra</span>
              </div>
            </div>

            {/* SECCIÓN 1: AVATAR Y FICHA DE LA MAQUINARIA TRANSPORTADA */}
            <div className="modal-section-card">
              <div className="modal-section-title-row">
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <Layers size={16} color={theme.primary} />
                  <h4>Maquinaria Transportada</h4>
                </div>
                <span
                  className={`pill-badge ${
                    isTransit ? 'pill-status-transit' : isDelivered ? 'pill-status-ready' : 'pill-status-pending'
                  }`}
                >
                  {trip.status.replace('_', ' ')}
                </span>
              </div>

              <div className="modal-machine-showcase">
                <div className="modal-machine-avatar-box">
                  {machinePhoto ? (
                    <img
                      src={machinePhoto}
                      alt={machine?.model || 'Maquinaria'}
                      className="modal-machine-avatar-img"
                    />
                  ) : (
                    <div className="modal-machine-placeholder">
                      <Truck size={36} />
                    </div>
                  )}
                </div>

                <div className="modal-machine-details">
                  <span className="modal-machine-category">{machine?.category || 'Maquinaria Pesada'}</span>
                  <h3 className="modal-machine-model">{machine?.model || 'Equipo Asignado'}</h3>
                  <div className="modal-machine-specs-row">
                    <span className="modal-spec-chip">
                      Serial: <strong>{machine?.serial || 'S/N'}</strong>
                    </span>
                    <span className="modal-spec-chip">
                      Estado: <strong>{machine?.status?.toUpperCase() || 'LISTO'}</strong>
                    </span>
                  </div>
                  <p className="modal-machine-dest-text">
                    <MapPin size={13} style={{ display: 'inline', marginRight: '4px', color: theme.primary }} />
                    Destino Oficial: <strong>{trip.destination}</strong>
                  </p>
                </div>
              </div>
            </div>

            {/* SECCIÓN 2: DETALLES COMPLETOS DEL CONDUCTOR (FOTO, CÉDULA, TIEMPO TRABAJANDO) */}
            <div className="modal-section-card">
              <div className="modal-section-title-row">
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <User size={16} color={theme.primary} />
                  <h4>Ficha Técnica del Conductor Asignado</h4>
                </div>
              </div>

              <div className="driver-modal-showcase">
                <div className="driver-avatar-container">
                  {driver?.avatarUrl ? (
                    <img src={driver.avatarUrl} alt={driver.name} className="driver-photo-img" />
                  ) : (
                    <div className="driver-photo-fallback">
                      <User size={34} />
                    </div>
                  )}
                  <span className="driver-active-badge" title="Conductor activo" />
                </div>

                <div className="driver-profile-meta">
                  <h4 className="driver-full-name">{driver?.name || 'Carlos Alberto Mendoza'}</h4>
                  <div className="driver-tags-row">
                    <span className="driver-role-tag">
                      <Award size={12} /> Transportador Oficial Certificado
                    </span>
                    <span className="driver-status-tag">En Servicio Activo</span>
                  </div>
                </div>
              </div>

              <div className="driver-details-grid" style={{ marginTop: '12px' }}>
                {/* Cédula */}
                <div className="driver-info-cell">
                  <div className="cell-icon-wrap icon-blue">
                    <CreditCard size={15} />
                  </div>
                  <div className="cell-data">
                    <span className="cell-label">Cédula de Ciudadanía</span>
                    <strong className="cell-value">{driver?.cedula || 'CC 1.094.882.310'}</strong>
                  </div>
                </div>

                {/* Tiempo Trabajando */}
                <div className="driver-info-cell">
                  <div className="cell-icon-wrap icon-purple">
                    <Clock size={15} />
                  </div>
                  <div className="cell-data">
                    <span className="cell-label">Tiempo Trabajando</span>
                    <strong className="cell-value">{driver?.experienceTime || '4 años y 6 meses'}</strong>
                  </div>
                </div>

                {/* Licencia */}
                <div className="driver-info-cell">
                  <div className="cell-icon-wrap icon-emerald">
                    <Award size={15} />
                  </div>
                  <div className="cell-data">
                    <span className="cell-label">Categoría de Licencia</span>
                    <strong className="cell-value">{driver?.licenseType || 'Licencia C3 (Carga Pesada)'}</strong>
                  </div>
                </div>

                {/* Teléfono */}
                <div className="driver-info-cell">
                  <div className="cell-icon-wrap icon-amber">
                    <Phone size={15} />
                  </div>
                  <div className="cell-data">
                    <span className="cell-label">Teléfono Móvil</span>
                    <strong className="cell-value">{driver?.phone || '+57 312 458 9921'}</strong>
                  </div>
                </div>

                {/* Correo */}
                <div className="driver-info-cell" style={{ gridColumn: 'span 2' }}>
                  <div className="cell-icon-wrap icon-blue">
                    <Mail size={15} />
                  </div>
                  <div className="cell-data">
                    <span className="cell-label">Correo Corporativo</span>
                    <strong className="cell-value">{driver?.email || 'carlos.mendoza@transporte-maquitrace.com'}</strong>
                  </div>
                </div>
              </div>
            </div>

            {/* SECCIÓN 3: APARTADO PARA LAS EVIDENCIAS FOTOGRÁFICAS */}
            <div className="modal-section-card">
              <div className="modal-section-title-row">
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <Camera size={16} color={theme.primary} />
                  <h4>Evidencias Multimedia de Inspección y Alistamiento ({evidences.length})</h4>
                </div>
                <span className="section-note">Almacenadas en Oracle Cloud (OCI)</span>
              </div>

              {evidences.length === 0 ? (
                <div className="empty-card-evidence">
                  <Camera size={20} color="#94A3B8" />
                  <span>Actualmente no hay evidencias fotográficas registradas para este equipo.</span>
                </div>
              ) : (
                <div className="modal-evidence-gallery-grid">
                  {evidences.map((ev, evIdx) => (
                    <div
                      key={ev.id || evIdx}
                      className="modal-evidence-card-item"
                      onClick={() => setViewerIndex(evIdx)}
                      title="Clic para ampliar fotografía"
                    >
                      <div className="modal-evidence-img-box">
                        <img src={ev.url} alt="Evidencia" className="modal-evidence-img" />
                        <span className="modal-evidence-zoom-hint">Ampliar</span>
                      </div>
                      <div className="modal-evidence-info">
                        <span className="modal-evidence-date">
                          {new Date(ev.createdAt).toLocaleDateString('es-CO')}
                        </span>
                        <p className="modal-evidence-obs">
                          {ev.observations || 'Inspección técnica de maquinaria.'}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* SECCIÓN 4: SIMULADOR DE TELEMETRÍA GPS SATELITAL */}
            <div className="telemetry-simulation-box">
              <div className="telemetry-sim-left">
                <Radio size={18} className="telemetry-sim-icon" style={{ color: theme.primary }} />
                <div>
                  <strong>Simulador de Telemetría GPS en Vivo</strong>
                  <p>Transmite una coordenada satelital para actualizar en tiempo real el mapa.</p>
                </div>
              </div>
              <button
                type="button"
                className="btn-simulate-gps"
                style={{ backgroundColor: theme.primary }}
                onClick={handleSimulateGps}
                disabled={gpsSimulating || isDelivered}
              >
                {gpsSimulating ? (
                  <>
                    <Loader2 size={14} className="spinner" />
                    <span>Transmitiendo...</span>
                  </>
                ) : (
                  <>
                    <Radio size={14} />
                    <span>Emitir Coordenada GPS</span>
                  </>
                )}
              </button>
            </div>

            {simMessage && (
              <div className="register-alert success" style={{ margin: '0' }}>
                <CheckCircle2 size={16} />
                <span>{simMessage}</span>
              </div>
            )}

            {/* SECCIÓN 5: HISTORIAL DE WAYPOINTS SATELITALES */}
            <div className="modal-section-card">
              <div className="modal-section-title-row">
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <Navigation size={16} color={theme.primary} />
                  <h4>Historial de Waypoints Satelitales ({gpsRecords.length} registrados)</h4>
                </div>
              </div>

              {gpsRecords.length === 0 ? (
                <div className="empty-waypoints-box">
                  <Navigation size={22} />
                  <span>Sin coordenadas registradas aún</span>
                </div>
              ) : (
                <div className="gps-waypoints-timeline">
                  {gpsRecords.map((record, idx) => {
                    const isLatest = idx === gpsRecords.length - 1;
                    return (
                      <div key={record.id || idx} className={`waypoint-node ${isLatest ? 'is-latest' : ''}`}>
                        <div className="waypoint-pin" style={{ backgroundColor: theme.primary }} />
                        <div className="waypoint-details">
                          <div className="waypoint-header">
                            <span className="waypoint-coords" style={{ color: theme.primary }}>
                              <MapPin size={12} /> {record.latitude.toFixed(5)}, {record.longitude.toFixed(5)}
                            </span>
                            <span className="waypoint-time">
                              {record.recordedAt ? new Date(record.recordedAt).toLocaleTimeString('es-CO') : ''}
                            </span>
                          </div>
                          <span className="waypoint-meta">
                            {isLatest ? '📍 Posición satelital más reciente' : `Punto de control #${idx + 1}`}
                          </span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>

            {/* SECCIÓN 6: INCIDENCIAS REPORTADAS SI EXISTEN */}
            {incidents.length > 0 && (
              <div className="modal-section-card" style={{ borderColor: '#FECACA', backgroundColor: '#FFF5F5' }}>
                <div className="modal-section-title-row">
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <ShieldAlert size={16} color="#DC2626" />
                    <h4 style={{ color: '#991B1B' }}>Novedades Reportadas en Ruta ({incidents.length})</h4>
                  </div>
                </div>

                <div className="incidents-list-wrap">
                  {incidents.map((inc) => (
                    <div key={inc.id} className="incident-card-item">
                      <div className="incident-icon-pill">
                        <ShieldAlert size={16} />
                      </div>
                      <div className="incident-card-body">
                        <strong className="incident-title">{inc.description}</strong>
                        <span className="incident-time">
                          Reportado el {new Date(inc.reportedAt).toLocaleString('es-CO')}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Footer con Acciones Operativas de Despacho / Entrega */}
          <div className="modal-footer">
            <button type="button" className="btn-secondary" onClick={onClose} disabled={actionLoading}>
              Cerrar
            </button>

            {isPending && machine && (
              <button
                type="button"
                className="btn-primary-register"
                onClick={() => onDepart(machine.id)}
                disabled={actionLoading}
              >
                {actionLoading ? <Loader2 size={16} className="spinner" /> : <Play size={16} />}
                <span>Iniciar Marcha en Carretera</span>
              </button>
            )}

            {isTransit && machine && (
              <button
                type="button"
                className="btn-primary-register"
                style={{ backgroundColor: '#059669' }}
                onClick={() => onDeliver(machine.id)}
                disabled={actionLoading}
              >
                {actionLoading ? <Loader2 size={16} className="spinner" /> : <CheckCircle2 size={16} />}
                <span>Confirmar Entrega en Destino</span>
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Visor Lightbox para Evidencias en Alta Resolución */}
      {viewerIndex !== null && (
        <EvidenceViewerModal
          evidences={evidences}
          initialIndex={viewerIndex}
          machineTitle={machine ? `${machine.model} (${machine.serial})` : 'Maquinaria'}
          onClose={() => setViewerIndex(null)}
        />
      )}
    </>
  );
};
