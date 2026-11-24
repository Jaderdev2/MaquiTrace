import React, { useState, useEffect, useMemo } from 'react';
import type { TransportTrip, Machine, Evidence } from '../../../types';
import { useAuth } from '../../../context/AuthContext';
import { fetchMachineEvidenceApi } from '../../../services/api';
import { getTripColorTheme } from '../utils/tripColors';
import {
  getMachineCandidatePhotos,
  getEvidenceShortTitle,
  getEvidenceAngleLabel,
  getEvidenceUploaderRole,
} from '../../../utils/evidence';
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
  MessageSquareText,
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
  const { token } = useAuth();
  // Estado para el visor de fotos de evidencia en alta resolución
  const [viewerIndex, setViewerIndex] = useState<number | null>(null);
  // Evidencias frescas consultadas directamente del endpoint de OCI para esta máquina
  const [remoteEvidences, setRemoteEvidences] = useState<Evidence[]>([]);
  // Índice de fallback para la foto principal de la máquina si alguna URL expira o falla
  const [machinePhotoIdx, setMachinePhotoIdx] = useState<number>(0);

  const isPending = trip.status === 'pendiente';
  const isTransit = trip.status === 'en_transito';
  const isDelivered = trip.status === 'entregado';

  const theme = getTripColorTheme(trip);
  const driver = trip.transporter;
  const effectiveMachine = machine || trip.machine || null;
  const targetMachineId = effectiveMachine?.id || trip.machineId;
  const readiness = checkMachineTransitReadiness(effectiveMachine);
  const gpsRecords = trip.gpsRecords || [];
  const incidents = trip.incidents || [];

  // Consultar evidencias frescas desde el backend (con URLs firmadas renovadas en OCI)
  useEffect(() => {
    setMachinePhotoIdx(0);
    setRemoteEvidences([]);
    if (!token || !targetMachineId || targetMachineId.startsWith('mach-demo-')) {
      return;
    }
    let cancelled = false;
    fetchMachineEvidenceApi(targetMachineId, token)
      .then((list) => {
        if (!cancelled && Array.isArray(list) && list.length > 0) {
          setRemoteEvidences(list);
        }
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, [token, targetMachineId, trip.id]);

  // Construir galería unificada: todas las evidencias fotográficas enviadas por el conductor (novedades, salida, entrega) + evidencias de alistamiento
  const evidences: Evidence[] = useMemo(() => {
    const unified: Evidence[] = [];
    const seenUrls = new Set<string>();

    const pushUnique = (item: Evidence) => {
      const cleanUrl = item.url?.trim();
      if (!cleanUrl || seenUrls.has(cleanUrl)) return;
      seenUrls.add(cleanUrl);
      unified.push(item);
    };

    // 1. Fotografías enviadas por el conductor en el viaje (Salida, Derrumbe, Retén, Entrega, etc.)
    incidents.forEach((inc) => {
      if (inc.photoUrl && inc.photoUrl.trim().length > 0) {
        pushUnique({
          id: `inc-ev-${inc.id}`,
          type: 'foto',
          url: inc.photoUrl,
          createdAt: inc.reportedAt || trip.departureAt || new Date().toISOString(),
          machineId: targetMachineId,
          observations: inc.description || 'Evidencia enviada por el conductor en ruta',
          uploader: {
            name: driver?.name || 'Conductor Asignado',
            role: 'Conductor',
          },
        });
      }
    });

    // 2. Evidencias directas del viaje (si existen)
    (trip.evidence || []).forEach((ev) => {
      pushUnique({
        ...ev,
        observations: ev.observations || 'Evidencia fotográfica de salida y transporte',
        uploader: ev.uploader || {
          name: driver?.name || 'Conductor Asignado',
          role: 'Conductor',
        },
      });
    });

    // 3. Evidencias de la máquina (priorizando las recién refrescadas desde OCI)
    const machineEvSource =
      remoteEvidences.length > 0
        ? remoteEvidences
        : effectiveMachine?.evidence || trip.machine?.evidence || [];

    machineEvSource.forEach((ev: any) => {
      const phaseObs = ev.phase?.observations;
      const phaseName = ev.phase?.name
        ? `Fase de ${String(ev.phase.name).charAt(0).toUpperCase() + String(ev.phase.name).slice(1)}`
        : null;
      const angleLabel = getEvidenceAngleLabel(ev);
      const resolvedObs =
        ev.observations ||
        (phaseObs ? `[${phaseName || angleLabel}] ${phaseObs}` : null) ||
        (phaseName ? `${angleLabel} — ${phaseName}` : angleLabel);

      pushUnique({
        ...ev,
        observations: resolvedObs,
        uploader: ev.uploader || {
          name: 'Equipo Técnico MaquiTrace',
          role: 'Taller / Alistamiento',
        },
      });
    });

    return unified;
  }, [incidents, trip.evidence, trip.departureAt, trip.machine?.evidence, remoteEvidences, effectiveMachine?.evidence, targetMachineId, driver?.name]);

  // Lista de fotos candidatas para el avatar de la máquina (con fallback automático si una URL falla)
  const candidateMachinePhotos = useMemo(() => {
    const mergedMachine: Machine | null = effectiveMachine
      ? {
          ...effectiveMachine,
          evidence:
            remoteEvidences.length > 0
              ? remoteEvidences
              : effectiveMachine.evidence || trip.machine?.evidence,
        }
      : null;
    return getMachineCandidatePhotos(
      mergedMachine,
      evidences.map((e) => e.url)
    );
  }, [effectiveMachine, remoteEvidences, trip.machine?.evidence, evidences]);

  const machinePhoto =
    machinePhotoIdx < candidateMachinePhotos.length
      ? candidateMachinePhotos[machinePhotoIdx]
      : null;

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

          <div className="modal-body trip-details-modal-body">
            {/* BARRA DE ESTADO DEL VIAJE REDISEÑADA */}
            <div
              className="trip-status-banner-card"
              style={{ borderLeftColor: theme.primary }}
            >
              <div className="status-banner-item">
                <span className="banner-label">Estado de Logística</span>
                <div>
                  <span
                    className="trip-status-badge"
                    style={{
                      backgroundColor: isTransit ? '#EFF6FF' : isDelivered ? '#E8F5EC' : '#FEF3C7',
                      color: isTransit ? '#2563EB' : isDelivered ? '#15803D' : '#B45309',
                      borderColor: isTransit ? '#BFDBFE' : isDelivered ? '#A7F3D0' : '#FDE68A',
                    }}
                  >
                    <span
                      className="status-dot-indicator"
                      style={{
                        backgroundColor: isTransit ? '#2563EB' : isDelivered ? '#15803D' : '#D97706',
                      }}
                    />
                    {isTransit
                      ? 'En Tránsito (Móvil)'
                      : isDelivered
                      ? 'Entregado a Conformidad (POD)'
                      : 'Pendiente de Salida'}
                  </span>
                </div>
              </div>

              <div className="status-banner-item">
                <span className="banner-label">Salida de Patio</span>
                <strong className="banner-value">
                  <Clock size={14} style={{ color: theme.primary, flexShrink: 0 }} />
                  <span>
                    {trip.departureAt
                      ? new Date(trip.departureAt).toLocaleString('es-CO')
                      : 'Pendiente de salida en celular'}
                  </span>
                </strong>
              </div>

              <div className="status-banner-item">
                <span className="banner-label">Llegada a Destino</span>
                <strong className="banner-value">
                  <Navigation size={14} style={{ color: isDelivered ? '#15803D' : '#64748B', flexShrink: 0 }} />
                  <span>
                    {trip.arrivalAt
                      ? new Date(trip.arrivalAt).toLocaleString('es-CO')
                      : 'En tránsito hacia el destino'}
                  </span>
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
                <span
                  className="modal-machine-category-pill"
                  style={{
                    backgroundColor: theme.badgeBg,
                    color: theme.badgeText,
                    borderColor: theme.border,
                  }}
                >
                  {effectiveMachine?.category || 'Maquinaria Pesada'}
                </span>
              </div>

              <div className="modal-machine-showcase">
                <div className="modal-machine-avatar-wrap">
                  {machinePhoto ? (
                    <img
                      src={machinePhoto}
                      alt={effectiveMachine?.model || 'Maquinaria'}
                      className="modal-machine-avatar-img"
                      onError={() =>
                        setMachinePhotoIdx((prev) => prev + 1)
                      }
                    />
                  ) : (
                    <div className="modal-machine-avatar-empty">
                      <Truck size={34} color="#94A3B8" />
                      <span>Sin fotografía</span>
                    </div>
                  )}
                </div>

                <div className="modal-machine-meta-col">
                  <div className="modal-machine-header-line">
                    <h4 className="modal-machine-model-title">
                      {effectiveMachine?.model || 'Modelo no especificado'}
                    </h4>
                  </div>

                  <div className="modal-machine-specs-grid">
                    <div className="modal-spec-box">
                      <span className="modal-spec-label">Serial / Placa</span>
                      <strong className="modal-spec-value">{effectiveMachine?.serial || 'S/N'}</strong>
                    </div>

                    <div className="modal-spec-box">
                      <span className="modal-spec-label">Categoría</span>
                      <strong className="modal-spec-value">{effectiveMachine?.category || 'General'}</strong>
                    </div>

                    <div className={`modal-spec-box ${readiness.canDepart ? 'spec-box-ready' : 'spec-box-pending'}`}>
                      <span className="modal-spec-label">Estado Alistamiento</span>
                      <strong className="modal-spec-value">{readiness.badgeLabel}</strong>
                    </div>
                  </div>

                  <div className="modal-machine-dest-banner">
                    <MapPin size={15} style={{ color: theme.primary, flexShrink: 0 }} />
                    <span>
                      Destino Oficial: <strong>{trip.destination}</strong>
                    </span>
                  </div>

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
                          style={{ cursor: 'pointer', borderRadius: '6px', overflow: 'hidden', width: '60px', height: '60px', position: 'relative' }}
                          onClick={() => {
                            const foundIdx = evidences.findIndex((e) => e.url === inc.photoUrl || e.id === `inc-ev-${inc.id}`);
                            if (foundIdx >= 0) {
                              setViewerIndex(foundIdx);
                            } else {
                              window.open(inc.photoUrl, '_blank');
                            }
                          }}
                          title="Clic para ver fotografía e información reportada por el conductor"
                        >
                          <img src={inc.photoUrl} alt={inc.description || 'Foto novedad'} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* SECCIÓN 4: EVIDENCIAS MULTIMEDIA DE ALISTAMIENTO Y REPORTES DEL CONDUCTOR */}
            <div className="modal-section-card">
              <div className="modal-section-title-row">
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <Camera size={16} color={theme.primary} />
                  <h4>Evidencias de Alistamiento y Salida ({evidences.length})</h4>
                </div>
                <span className="section-note">Fotografías del conductor y taller (OCI)</span>
              </div>

              {evidences.length === 0 ? (
                <div className="empty-card-evidence">
                  <Camera size={20} color="#94A3B8" />
                  <span>Actualmente no hay evidencias fotográficas registradas para este equipo.</span>
                </div>
              ) : (
                <div className="modal-evidence-gallery-grid">
                  {evidences.map((ev, evIdx) => {
                    const shortLabel = getEvidenceShortTitle(ev);
                    const roleStr = getEvidenceUploaderRole(ev).toLowerCase();
                    const isDriverEvidence =
                      String(ev.id || '').startsWith('inc-ev-') ||
                      roleStr.includes('conductor') ||
                      roleStr.includes('transportador');

                    return (
                      <div
                        key={ev.id || evIdx}
                        className="modal-evidence-card-item"
                        onClick={() => setViewerIndex(evIdx)}
                        title={`Clic para ver detalle: ${shortLabel}`}
                      >
                        <div className="modal-evidence-img-box">
                          <img src={ev.url} alt={shortLabel} className="modal-evidence-img" />
                          <span
                            className="modal-evidence-tag-badge"
                            style={{
                              backgroundColor: isDriverEvidence ? theme.primary : '#0F172A',
                            }}
                          >
                            {shortLabel}
                          </span>
                          <span className="modal-evidence-zoom-hint">Ver info</span>
                        </div>
                        <div className="modal-evidence-info">
                          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '4px' }}>
                            <span className="modal-evidence-date">
                              {ev.createdAt ? new Date(ev.createdAt).toLocaleDateString('es-CO') : 'Reciente'}
                            </span>
                            <span className="modal-evidence-author-chip">
                              {isDriverEvidence ? 'Conductor' : 'Taller'}
                            </span>
                          </div>
                          <p className="modal-evidence-obs">
                            <MessageSquareText size={11} style={{ display: 'inline', marginRight: '4px', verticalAlign: 'middle', color: theme.primary }} />
                            {ev.observations || shortLabel}
                          </p>
                        </div>
                      </div>
                    );
                  })}
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
          machineTitle={
            effectiveMachine
              ? `${effectiveMachine.model} (${effectiveMachine.serial})`
              : 'Maquinaria'
          }
          onClose={() => setViewerIndex(null)}
        />
      )}
    </>
  );
};
