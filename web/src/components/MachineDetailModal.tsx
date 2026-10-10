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
  ExternalLink,
  Maximize2,
  User,
  Truck,
  Layers,
  Sparkles,
} from 'lucide-react';
import {
  getMachineProfileImage,
  getEvidenceAngleLabel,
} from '../utils/evidence';
import '../styles/modal.css';

interface Props {
  machine: Machine | null;
  onClose: () => void;
}

export const MachineDetailModal: React.FC<Props> = ({ machine, onClose }) => {
  const [selectedPhoto, setSelectedPhoto] = useState<string | null>(null);

  if (!machine) return null;

  const profilePhoto = getMachineProfileImage(machine);

  // Filtrar evidencias operativas excluyendo fotos de avatar para evitar duplicados o confusiones
  const operationalEvidences = (machine.evidence || []).filter((ev) => {
    const isAvatar =
      ev.url?.toLowerCase().includes('avatar') ||
      ev.observations?.toLowerCase().includes('avatar');
    return !isAvatar;
  });

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'pendiente':
        return (
          <span className="detail-status-pill status-pending">
            <Clock size={13} /> Pendiente
          </span>
        );
      case 'en_proceso':
        return (
          <span className="detail-status-pill status-process">
            <span className="status-pulse-dot" /> En Alistamiento
          </span>
        );
      case 'completada':
        return (
          <span className="detail-status-pill status-completed">
            <CheckCircle2 size={13} /> Lista / Completada
          </span>
        );
      case 'en_transito':
        return (
          <span className="detail-status-pill status-transit">
            <Clock size={13} /> En Tránsito (GPS)
          </span>
        );
      case 'entregada':
        return (
          <span className="detail-status-pill status-delivered">
            <CheckCircle2 size={13} /> Entregada a Cliente
          </span>
        );
      default:
        return <span className="detail-status-pill status-pending">{status}</span>;
    }
  };

  const getPhaseStatusBadge = (status: string) => {
    switch (status) {
      case 'completada':
        return (
          <span className="phase-pill completed">
            <CheckCircle2 size={12} /> Completada
          </span>
        );
      case 'en_proceso':
        return (
          <span className="phase-pill in-progress">
            <span className="status-pulse-dot small" /> En Proceso
          </span>
        );
      default:
        return (
          <span className="phase-pill pending">
            <Clock size={12} /> Pendiente
          </span>
        );
    }
  };

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div
        className="modal-content machine-detail-modal-content"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Cabecera del modal (Fija / Sticky) */}
        <div className="modal-header">
          <div className="modal-header-title">
            <div className="detail-header-badge">
              <div className="header-icon-box">
                <Truck size={18} />
              </div>
              <div>
                <h3>Ficha Técnica e Inspección</h3>
                <span className="modal-header-sub">
                  Equipo {machine.serial} &bull; {machine.category}
                </span>
              </div>
            </div>
          </div>
          <button className="btn-close" onClick={onClose} aria-label="Cerrar modal">
            <X size={20} />
          </button>
        </div>

        {/* Cuerpo del modal (Scrollable y siempre accesible) */}
        <div className="modal-body detail-modal-body">
          {/* FOTO GRANDE DEL EQUIPO (HERO SHOWCASE) */}
          <div className="machine-showcase-hero">
            <div className="machine-showcase-media">
              {profilePhoto ? (
                <>
                  <img
                    src={profilePhoto}
                    alt={machine.model}
                    className="machine-showcase-image"
                    onClick={() => setSelectedPhoto(profilePhoto)}
                    title="Haz clic para ver imagen en alta resolución"
                  />
                  <div className="machine-showcase-badges-top">
                    <span className="badge-photo-source">
                      <Sparkles size={13} /> Foto Oficial (Oracle Cloud)
                    </span>
                    <button
                      className="btn-showcase-zoom"
                      onClick={() => setSelectedPhoto(profilePhoto)}
                      title="Ampliar imagen en pantalla completa"
                      type="button"
                    >
                      <Maximize2 size={16} />
                    </button>
                  </div>
                </>
              ) : (
                <div className="machine-showcase-empty">
                  <div className="empty-machine-icon-box">
                    <Truck size={42} />
                  </div>
                  <span className="empty-machine-text">
                    Sin foto oficial registrada en Oracle Cloud
                  </span>
                  <span className="empty-machine-sub">
                    Las fotos registradas desde la app móvil o el administrador se desplegarán aquí en alta definición.
                  </span>
                </div>
              )}
            </div>

            {/* Ficha descriptiva directamente abajo de la imagen grande */}
            <div className="machine-showcase-footer">
              <div className="showcase-titles-box">
                <div className="showcase-serial-pill">{machine.serial}</div>
                <div>
                  <h2 className="showcase-machine-name">{machine.model}</h2>
                  <span className="showcase-category-label">
                    <Layers size={13} /> {machine.category}
                  </span>
                </div>
              </div>
              <div className="showcase-status-box">
                {getStatusBadge(machine.status)}
              </div>
            </div>
          </div>

          {/* Grid de Métricas y Especificaciones */}
          <div className="detail-specs-grid">
            <div className="spec-item-card">
              <span className="spec-item-label">Estado Operativo</span>
              <div className="spec-item-value-pill">
                {getStatusBadge(machine.status)}
              </div>
            </div>

            <div className="spec-item-card">
              <span className="spec-item-label">Fecha de Ingreso</span>
              <div className="spec-item-value">
                <Calendar size={15} className="spec-icon" />
                <span>
                  {machine.createdAt
                    ? new Date(machine.createdAt).toLocaleDateString('es-CO', {
                        day: '2-digit',
                        month: 'short',
                        year: 'numeric',
                      })
                    : 'Reciente'}
                </span>
              </div>
            </div>

            <div className="spec-item-card">
              <span className="spec-item-label">Categoría Técnica</span>
              <div className="spec-item-value">
                <Truck size={15} className="spec-icon" />
                <span>{machine.category}</span>
              </div>
            </div>

            <div className="spec-item-card">
              <span className="spec-item-label">Evidencias Operativas</span>
              <div className="spec-item-value">
                <Camera size={15} className="spec-icon" />
                <span>{operationalEvidences.length} archivo(s)</span>
              </div>
            </div>
          </div>

          {/* Fases del Ciclo de Alistamiento */}
          <div className="section-block">
            <div className="section-title-wrap">
              <h4 className="section-title">
                <Wrench size={16} /> Fases del Ciclo de Alistamiento
              </h4>
              <span className="section-subtitle">
                3 estaciones obligatorias: Ensamblaje, Pintura y Lavado
              </span>
            </div>

            <div className="phases-list">
              {machine.phases && machine.phases.length > 0 ? (
                machine.phases.map((phase, idx) => (
                  <div key={phase.id || idx} className={`phase-card phase-${phase.status}`}>
                    <div className="phase-card-header">
                      <div className="phase-title-group">
                        <span className="phase-number">{idx + 1}</span>
                        <span className="phase-name">{phase.name.toUpperCase()}</span>
                      </div>
                      {getPhaseStatusBadge(phase.status)}
                    </div>

                    {phase.operator && (
                      <div className="phase-operator-pill">
                        <User size={13} />
                        <span>
                          Operario: <strong>{phase.operator.name}</strong>
                        </span>
                      </div>
                    )}

                    {phase.observations ? (
                      <div className="phase-obs-box">
                        <FileText size={13} className="obs-icon" />
                        <span className="phase-obs-text">{phase.observations}</span>
                      </div>
                    ) : (
                      <div className="phase-obs-box empty">
                        <span>Sin observaciones técnicas registradas en esta fase.</span>
                      </div>
                    )}
                  </div>
                ))
              ) : (
                <div className="empty-notice-card">
                  <Clock size={20} />
                  <span>No hay fases de alistamiento registradas en el backend aún.</span>
                </div>
              )}
            </div>
          </div>

          {/* Galería de Evidencias Fotográficas vinculadas en OCI */}
          <div className="section-block">
            <div className="section-title-wrap">
              <h4 className="section-title">
                <Camera size={16} /> Evidencias Operativas en la Nube ({operationalEvidences.length})
              </h4>
              <span className="section-subtitle">
                Almacenamiento: Oracle Cloud Infrastructure (OCI) Object Storage
              </span>
            </div>

            {operationalEvidences.length > 0 ? (
              <div className="evidence-grid">
                {operationalEvidences.map((ev) => {
                  const angleLabel = getEvidenceAngleLabel(ev);
                  const formattedDate = ev.createdAt
                    ? new Date(ev.createdAt).toLocaleDateString('es-CO', {
                        day: '2-digit',
                        month: 'short',
                        year: 'numeric',
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
                        <div className="evidence-meta-row">
                          <span className="evidence-meta-date">
                            <Clock size={11} /> {formattedDate}
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
              <div className="evidence-placeholder-card">
                <Camera size={36} className="placeholder-icon" />
                <strong>Sin evidencias fotográficas operativas</strong>
                <p>
                  Cuando los operarios capturen los 4 ángulos de inspección desde la app móvil en patio,
                  se sincronizarán de forma segura en esta sección.
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Pie del modal (Sticky / Fijo con botones de acción siempre visibles) */}
        <div className="modal-footer">
          <button className="btn-secondary" onClick={onClose} type="button">
            Cerrar Ficha Técnica
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
                type="button"
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
