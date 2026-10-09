import React, { useState } from 'react';
import type { Machine } from '../types';
import {
  X,
  CheckCircle2,
  Clock,
  FileText,
  Camera,
  Calendar,
  Wrench,
  Truck,
  ExternalLink,
  Maximize2,
  User,
} from 'lucide-react';
import { getMachinePrimaryPhoto, getEvidenceAngleLabel } from '../utils/evidence';

interface Props {
  machine: Machine | null;
  onClose: () => void;
}

export const MachineDetailModal: React.FC<Props> = ({ machine, onClose }) => {
  const [selectedPhoto, setSelectedPhoto] = useState<string | null>(null);

  if (!machine) return null;

  const primaryPhoto = getMachinePrimaryPhoto(machine);

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'pendiente':
        return <span className="badge badge-amber"><Clock size={12} /> Pendiente</span>;
      case 'en_proceso':
        return <span className="badge badge-blue"><Wrench size={12} /> En Alistamiento</span>;
      case 'completada':
        return <span className="badge badge-emerald"><CheckCircle2 size={12} /> Lista / Completada</span>;
      case 'en_transito':
        return <span className="badge badge-purple"><Clock size={12} /> En Tránsito (GPS)</span>;
      case 'entregada':
        return <span className="badge badge-teal"><CheckCircle2 size={12} /> Entregada</span>;
      default:
        return <span className="badge">{status}</span>;
    }
  };

  const getPhaseStatusBadge = (status: string) => {
    switch (status) {
      case 'completada':
        return <span className="phase-pill completed"><CheckCircle2 size={12} /> Completada</span>;
      case 'en_proceso':
        return <span className="phase-pill in-progress"><Clock size={12} /> En Proceso</span>;
      default:
        return <span className="phase-pill pending"><Clock size={12} /> Pendiente</span>;
    }
  };

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        {/* Header con foto real de la máquina */}
        <div className="modal-header">
          <div className="modal-title-box">
            <div className="modal-machine-thumb">
              {primaryPhoto ? (
                <img
                  src={primaryPhoto}
                  alt={machine.model}
                  onError={(e) => {
                    e.currentTarget.style.display = 'none';
                    const parent = e.currentTarget.parentElement;
                    const fallback = parent?.querySelector('.modal-thumb-fallback');
                    if (fallback) (fallback as HTMLElement).style.display = 'flex';
                  }}
                />
              ) : null}
              <div
                className="modal-thumb-fallback"
                style={{
                  display: primaryPhoto ? 'none' : 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  width: '100%',
                  height: '100%',
                }}
              >
                <Truck size={22} />
              </div>
            </div>

            <div className="serial-tag">{machine.serial}</div>
            <div>
              <h3>{machine.model}</h3>
              <span className="modal-subtitle">Categoría: {machine.category}</span>
            </div>
          </div>
          <button className="btn-close" onClick={onClose} aria-label="Cerrar modal">
            <X size={20} />
          </button>
        </div>

        <div className="modal-body">
          {/* Status summary */}
          <div className="detail-status-bar">
            <div>
              <span className="detail-label">Estado actual:</span>
              <div className="mt-1">{getStatusBadge(machine.status)}</div>
            </div>
            <div>
              <span className="detail-label">Fecha de Registro:</span>
              <div className="detail-val">
                <Calendar size={14} />{' '}
                {machine.createdAt ? new Date(machine.createdAt).toLocaleDateString('es-CO') : 'Reciente'}
              </div>
            </div>
            <div>
              <span className="detail-label">Evidencias en OCI:</span>
              <div className="detail-val">
                <Camera size={14} /> {machine.evidence?.length || 0} archivo(s)
              </div>
            </div>
          </div>

          {/* Fases de Alistamiento */}
          <div className="section-block">
            <h4 className="section-title">
              <Wrench size={16} /> Fases de Alistamiento y Preparación
            </h4>
            <div className="phases-list">
              {machine.phases && machine.phases.length > 0 ? (
                machine.phases.map((phase, idx) => (
                  <div key={phase.id || idx} className="phase-card">
                    <div className="phase-card-header">
                      <span className="phase-name">
                        {idx + 1}. {phase.name.toUpperCase()}
                      </span>
                      {getPhaseStatusBadge(phase.status)}
                    </div>
                    {phase.operator && (
                      <p className="phase-operator" style={{ fontSize: '11.5px', color: '#64748B', display: 'flex', alignItems: 'center', gap: '4px', margin: '4px 0 0 0' }}>
                        <User size={12} /> Operario: <strong>{phase.operator.name}</strong>
                      </p>
                    )}
                    {phase.observations ? (
                      <p className="phase-obs">
                        <FileText size={12} /> {phase.observations}
                      </p>
                    ) : (
                      <p className="phase-obs empty">Sin observaciones adicionales.</p>
                    )}
                  </div>
                ))
              ) : (
                <div className="empty-notice">No hay fases de alistamiento registradas aún.</div>
              )}
            </div>
          </div>

          {/* Galería de Evidencias Fotográficas vinculadas a la máquina */}
          <div className="section-block">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h4 className="section-title">
                <Camera size={16} /> Evidencias Fotográficas ({machine.evidence?.length || 0})
              </h4>
              <span style={{ fontSize: '11px', color: '#64748B' }}>
                Almacenamiento: Oracle Cloud Infrastructure (OCI)
              </span>
            </div>

            {machine.evidence && machine.evidence.length > 0 ? (
              <div className="evidence-grid">
                {machine.evidence.map((ev) => {
                  const angleLabel = getEvidenceAngleLabel(ev);
                  const formattedDate = ev.createdAt
                    ? new Date(ev.createdAt).toLocaleDateString('es-CO', {
                        day: '2-digit',
                        month: 'short',
                      })
                    : 'Reciente';

                  return (
                    <div
                      key={ev.id}
                      className="evidence-card"
                      onClick={() => setSelectedPhoto(ev.url)}
                      title="Haz clic para ampliar la imagen"
                    >
                      <div className="evidence-card-media">
                        <img
                          src={ev.url}
                          alt={angleLabel}
                          loading="lazy"
                          onError={(e) => {
                            (e.currentTarget as HTMLImageElement).src =
                              'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" fill="%23CBD5E1" viewBox="0 0 24 24"><path d="M21 19V5c0-1.1-.9-2-2-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2zM8.5 13.5l2.5 3.01L14.5 12l4.5 6H5l3.5-4.5z"/></svg>';
                          }}
                        />
                        <div className="media-overlay-btn">
                          <Maximize2 size={13} />
                        </div>
                        <span className="evidence-badge-type">
                          {ev.type || 'foto'}
                        </span>
                      </div>
                      <div className="evidence-card-info">
                        <span className="evidence-tag-title">{angleLabel}</span>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <span className="evidence-meta-date">
                            <Clock size={10} /> {formattedDate}
                          </span>
                          <a
                            href={ev.url}
                            target="_blank"
                            rel="noopener noreferrer"
                            onClick={(e) => e.stopPropagation()}
                            className="evidence-link-icon"
                            title="Abrir URL original en Oracle Cloud"
                          >
                            <ExternalLink size={12} />
                          </a>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            ) : (
              <div className="evidence-placeholder">
                <Camera size={32} className="placeholder-icon" />
                <strong>Sin evidencias fotográficas aún</strong>
                <p>
                  Cuando los operarios capturen los 4 ángulos de inspección (Vista Frontal, Vista Lateral,
                  Cabina y Serial) desde la app móvil, se guardarán en Oracle Cloud y aparecerán aquí automáticamente.
                </p>
              </div>
            )}
          </div>
        </div>

        <div className="modal-footer">
          <button className="btn-secondary" onClick={onClose}>
            Cerrar Detalle
          </button>
        </div>
      </div>

      {/* Lightbox / Visor de Imagen en Alta Resolución */}
      {selectedPhoto && (
        <div
          className="lightbox-overlay"
          onClick={() => setSelectedPhoto(null)}
        >
          <div className="lightbox-content" onClick={(e) => e.stopPropagation()}>
            <img src={selectedPhoto} alt="Evidencia en resolución completa" />
            <div className="lightbox-actions">
              <a
                href={selectedPhoto}
                target="_blank"
                rel="noopener noreferrer"
                className="btn-lightbox-action"
              >
                <ExternalLink size={14} /> Abrir en nueva pestaña
              </a>
              <button
                className="btn-lightbox-close"
                onClick={() => setSelectedPhoto(null)}
              >
                <X size={16} /> Cerrar
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
