import React, { useState } from 'react';
import type { TransportTrip, Machine, Evidence } from '../../../types';
import { getTripColorTheme } from '../utils/tripColors';
import { getMachinePrimaryPhoto } from '../../../utils/evidence';
import { EvidenceViewerModal } from './EvidenceViewerModal';
import { checkMachineTransitReadiness } from '../utils/transitValidation';
import {
  Navigation,
  MapPin,
  Truck,
  ShieldAlert,
  X,
  User,
  CreditCard,
  Clock,
  Award,
  Phone,
  Mail,
  Camera,
  Layers,
  Edit3,
  FileCheck2,
} from 'lucide-react';

interface TripDetailsModalProps {
  trip: TransportTrip;
  machine?: Machine | null;
  onClose: () => void;
  onEdit?: () => void;
  actionLoading: boolean;
}

export const TripDetailsModal: React.FC<TripDetailsModalProps> = ({
  trip,
  machine,
  onClose,
  onEdit,
  actionLoading,
}) => {
  // Estado para el visor de fotos de evidencia en alta resolución
  const [viewerIndex, setViewerIndex] = useState<number | null>(null);

  const isPending = trip.status === 'pendiente';
  const isTransit = trip.status === 'en_transito';
  const isDelivered = trip.status === 'entregado';

  const theme = getTripColorTheme(trip);
  const driver = trip.transporter;
  const readiness = checkMachineTransitReadiness(machine);
  const machinePhoto = machine ? getMachinePrimaryPhoto(machine) : null;
  const evidences: Evidence[] = machine?.evidence || trip.evidence || [];
  const gpsRecords = trip.gpsRecords || [];
  const incidents = trip.incidents || [];

  return (
    <>
      <div className="modal-backdrop" onClick={onClose}>
        <div
          className="modal-content trip-details-modal-content"
          onClick={(e) => e.stopPropagation()}
        >
          {/* HEADER CON COLOR TEMÁTICO DINÁMICO */}
          <div className="modal-header" style={{ borderBottom: `2.5px solid ${theme.primary}` }}>
            <div className="modal-header-title">
              <div
                className="trip-vehicle-icon-box"
                style={{
                  backgroundColor: theme.badgeBg,
                  color: theme.primary,
                  borderColor: theme.primary,
                }}
              >
                <Truck size={22} />
              </div>
              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
                  <h3>{trip.vehicle}</h3>
                  <span
                    className="modal-theme-indicator-tag"
                    style={{
                      backgroundColor: theme.badgeBg,
                      color: theme.badgeText,
                      borderColor: theme.primary,
                    }}
                  >
                    {theme.name}
                  </span>
                </div>
                <span className="modal-header-sub">
                  Monitoreo de ruta oficial y telemetría móvil en tiempo real
                </span>
              </div>
            </div>

            <button className="btn-close" onClick={onClose} aria-label="Cerrar modal">
              <X size={20} />
            </button>
          </div>

          <div className="modal-body">
            {/* BARRA DE ESTADO DEL VIAJE */}
            <div className="trip-status-banner-card" style={{ borderColor: theme.primary }}>
              <div className="status-banner-item">
                <span className="banner-label">Estado de Logística:</span>
                <span
                  className="trip-status-badge"
                  style={{
                    backgroundColor: isTransit ? '#EFF6FF' : isDelivered ? '#E8F5EC' : '#FEF3C7',
                    color: isTransit ? '#2563EB' : isDelivered ? '#15803D' : '#B45309',
                    fontWeight: 700,
                  }}
                >
                  {isTransit ? 'En Tránsito (Móvil)' : isDelivered ? 'Entregado a Conformidad (POD)' : 'Pendiente de Salida'}
                </span>
              </div>

              <div className="status-banner-item">
                <span className="banner-label">Salida de Patio:</span>
                <strong>
                  {trip.departureAt ? new Date(trip.departureAt).toLocaleString('es-CO') : 'Pendiente de salida en celular'}
                </strong>
              </div>

              <div className="status-banner-item">
                <span className="banner-label">Llegada a Destino:</span>
                <strong>
                  {trip.arrivalAt ? new Date(trip.arrivalAt).toLocaleString('es-CO') : 'En tránsito hacia el destino'}
                </strong>
              </div>
            </div>

            {/* SECCIÓN 1: AVATAR Y DATOS DE LA MÁQUINA TRANSPORTADA */}
            <div className="modal-section-card">
              <div className="modal-section-title-row">
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <Layers size={16} color={theme.primary} />
                  <h4>Maquinaria Transportada</h4>
                </div>
              </div>

              <div className="modal-machine-showcase">
                <div className="modal-machine-avatar-wrap">
                  {machinePhoto ? (
                    <img src={machinePhoto} alt={machine?.model} className="modal-machine-avatar-img" />
                  ) : (
                    <div className="modal-machine-avatar-empty">
                      <Truck size={38} color="#94A3B8" />
                      <span>Sin fotografía</span>
                    </div>
                  )}
                  <span className="modal-machine-avatar-badge" style={{ backgroundColor: theme.primary }}>
                    {machine?.category || 'Maquinaria Pesada'}
                  </span>
                </div>

                <div className="modal-machine-meta-col">
                  <h4 className="modal-machine-model-title">{machine?.model || 'Modelo no especificado'}</h4>
                  <div className="modal-machine-specs-row">
                    <span className="modal-spec-chip">
                      Serial: <strong>{machine?.serial || 'S/N'}</strong>
                    </span>
                    <span className="modal-spec-chip">
                      Categoría: <strong>{machine?.category || 'General'}</strong>
                    </span>
                    <span className={`modal-spec-chip ${readiness.canDepart ? 'spec-chip-ready' : 'spec-chip-pending'}`}>
                      Alistamiento: <strong>{readiness.badgeLabel}</strong>
                    </span>
                  </div>
                  <p className="modal-machine-dest-text">
                    <MapPin size={13} style={{ display: 'inline', marginRight: '4px', color: theme.primary }} />
                    Destino Oficial: <strong>{trip.destination}</strong>
                  </p>

                  {!readiness.canDepart && isPending && (
                    <div className="transit-readiness-warning-box">
                      <ShieldAlert size={18} className="warning-icon" />
                      <div>
                        <strong>Bloqueo Operativo de Salida:</strong>
                        <p>{readiness.reason}</p>
                        <span>
                          La maquinaria no puede transitar por carreteras nacionales hasta que el taller certifique la culminación de todas sus fases técnicas.
                        </span>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* SECCIÓN 2: DETALLES COMPLETOS DEL CONDUCTOR */}
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
                <div className="driver-info-cell">
                  <div className="cell-icon-wrap icon-blue">
                    <CreditCard size={15} />
                  </div>
                  <div className="cell-data">
                    <span className="cell-label">Cédula de Ciudadanía</span>
                    <strong className="cell-value">{driver?.cedula || 'CC 1.094.882.310'}</strong>
                  </div>
                </div>

                <div className="driver-info-cell">
                  <div className="cell-icon-wrap icon-purple">
                    <Clock size={15} />
                  </div>
                  <div className="cell-data">
                    <span className="cell-label">Tiempo Trabajando</span>
                    <strong className="cell-value">{driver?.experienceTime || '4 años y 6 meses'}</strong>
                  </div>
                </div>

                <div className="driver-info-cell">
                  <div className="cell-icon-wrap icon-emerald">
                    <Award size={15} />
                  </div>
                  <div className="cell-data">
                    <span className="cell-label">Categoría de Licencia</span>
                    <strong className="cell-value">{driver?.licenseType || 'Licencia C3 (Carga Pesada)'}</strong>
                  </div>
                </div>

                <div className="driver-info-cell">
                  <div className="cell-icon-wrap icon-amber">
                    <Phone size={15} />
                  </div>
                  <div className="cell-data">
                    <span className="cell-label">Teléfono Móvil</span>
                    <strong className="cell-value">{driver?.phone || '+57 312 458 9921'}</strong>
                  </div>
                </div>

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

            {/* SECCIÓN 3: NOVEDADES / INCIDENCIAS REPORTADAS DESDE LA APP MÓVIL */}
            {incidents.length > 0 && (
              <div className="modal-section-card" style={{ borderColor: '#FECACA', backgroundColor: '#FFFBFB' }}>
                <div className="modal-section-title-row">
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <ShieldAlert size={16} color="#DC2626" />
                    <h4 style={{ color: '#991B1B' }}>Novedades Reportadas en Ruta desde el Celular ({incidents.length})</h4>
                  </div>
                  <span className="section-note" style={{ color: '#B91C1C' }}>Reportadas por el conductor</span>
                </div>

                <div className="incidents-list-wrap">
                  {incidents.map((inc) => (
                    <div key={inc.id} className="incident-card-item">
                      <div className="incident-icon-pill">
                        <ShieldAlert size={16} />
                      </div>
                      <div className="incident-card-body" style={{ flex: 1 }}>
                        <strong className="incident-title">{inc.description}</strong>
                        <span className="incident-time">
                          {inc.reportedAt ? new Date(inc.reportedAt).toLocaleString('es-CO') : 'Reporte reciente'}
                        </span>
                      </div>
                      {inc.photoUrl && (
                        <div
                          style={{ cursor: 'pointer', borderRadius: '6px', overflow: 'hidden', width: '60px', height: '60px' }}
                          onClick={() => window.open(inc.photoUrl, '_blank')}
                          title="Ver fotografía de la novedad"
                        >
                          <img src={inc.photoUrl} alt="Foto novedad" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* SECCIÓN 4: EVIDENCIAS MULTIMEDIA DE ALISTAMIENTO / OCI */}
            <div className="modal-section-card">
              <div className="modal-section-title-row">
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <Camera size={16} color={theme.primary} />
                  <h4>Evidencias de Alistamiento y Salida ({evidences.length})</h4>
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

            {/* SECCIÓN 5: TRANSMISIONES GPS PERIÓDICAS DEL CELULAR */}
            <div className="modal-section-card">
              <div className="modal-section-title-row">
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <Navigation size={16} color={theme.primary} />
                  <h4>Historial de Transmisiones GPS ({gpsRecords.length} reportes del celular)</h4>
                </div>
              </div>

              {gpsRecords.length === 0 ? (
                <div className="empty-waypoints-box">
                  <Navigation size={22} />
                  <span>El conductor aún no ha iniciado marcha ni transmitido coordenadas</span>
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
                            {isLatest ? '📍 Transmisión más reciente en carretera' : `Reporte GPS #${idx + 1}`}
                          </span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>

          <div className="modal-footer">
            <button type="button" className="btn-secondary" onClick={onClose} disabled={actionLoading}>
              Cerrar
            </button>

            {onEdit && (
              <button
                type="button"
                className="btn-secondary"
                style={{ display: 'inline-flex', alignItems: 'center', gap: '6px' }}
                onClick={() => {
                  onClose();
                  onEdit();
                }}
                disabled={actionLoading}
              >
                <Edit3 size={15} />
                <span>Editar Asignación</span>
              </button>
            )}
          </div>
        </div>
      </div>

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
