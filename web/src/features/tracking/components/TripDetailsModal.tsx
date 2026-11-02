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
                    <span className={`modal-spec-chip ${readiness.canDepart ? 'spec-chip-ready' : 'spec-chip-pending'}`}>
                      Alistamiento: <strong>{readiness.badgeLabel}</strong>
                    </span>
                  </div>
                  <p className="modal-machine-dest-text">
                    <MapPin size={13} style={{ display: 'inline', marginRight: '4px', color: theme.primary }} />
                    Destino Oficial: <strong>{trip.destination}</strong>
                  </p>

                  {/* Alerta de bloqueo si el alistamiento aún no ha terminado */}
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

          {/* El panel supervisa el viaje; las acciones de campo se realizan en la app móvil. */}
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
                <span>Editar Viaje</span>
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
