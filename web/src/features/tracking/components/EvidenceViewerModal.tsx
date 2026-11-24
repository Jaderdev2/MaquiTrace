import React, { useState } from 'react';
import type { Evidence } from '../../../types';
import { getEvidenceShortTitle, getEvidenceUploaderRole } from '../../../utils/evidence';
import { X, ChevronLeft, ChevronRight, Image as ImageIcon, Calendar, User, Tag } from 'lucide-react';

interface EvidenceViewerModalProps {
  evidences: Evidence[];
  initialIndex?: number;
  machineTitle?: string;
  onClose: () => void;
}

export const EvidenceViewerModal: React.FC<EvidenceViewerModalProps> = ({
  evidences,
  initialIndex = 0,
  machineTitle = 'Maquinaria',
  onClose,
}) => {
  const [currentIndex, setCurrentIndex] = useState(initialIndex);

  if (evidences.length === 0) return null;

  const current = evidences[currentIndex] || evidences[0];
  if (!current) return null;

  const shortTitle = getEvidenceShortTitle(current);
  const uploaderName =
    typeof current.uploader?.name === 'string' && current.uploader.name
      ? current.uploader.name
      : 'Conductor / Operario';
  const uploaderRole = getEvidenceUploaderRole(current) || 'Registro Oficial';

  const handlePrev = (e: React.MouseEvent) => {
    e.stopPropagation();
    setCurrentIndex((prev) => (prev > 0 ? prev - 1 : evidences.length - 1));
  };

  const handleNext = (e: React.MouseEvent) => {
    e.stopPropagation();
    setCurrentIndex((prev) => (prev < evidences.length - 1 ? prev + 1 : 0));
  };

  return (
    <div className="modal-backdrop evidence-lightbox-backdrop" onClick={onClose}>
      <div className="evidence-lightbox-container" onClick={(e) => e.stopPropagation()}>
        {/* Cabecera del visor con etiqueta corta del reporte */}
        <div className="evidence-lightbox-header">
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
              <span className="lightbox-title">{machineTitle}</span>
              <span className="lightbox-short-tag-pill">
                <Tag size={12} /> {shortTitle}
              </span>
            </div>
            <span className="lightbox-counter">
              Evidencia {currentIndex + 1} de {evidences.length}
            </span>
          </div>
          <button className="btn-close-lightbox" onClick={onClose}>
            <X size={20} />
          </button>
        </div>

        {/* Imagen principal con botones de navegación */}
        <div className="evidence-lightbox-stage">
          {evidences.length > 1 && (
            <button className="lightbox-nav-btn prev" onClick={handlePrev} title="Foto anterior">
              <ChevronLeft size={24} />
            </button>
          )}

          <div className="lightbox-img-wrap">
            <img src={current.url} alt={shortTitle} className="lightbox-main-img" />
          </div>

          {evidences.length > 1 && (
            <button className="lightbox-nav-btn next" onClick={handleNext} title="Siguiente foto">
              <ChevronRight size={24} />
            </button>
          )}
        </div>

        {/* Pie con información corta y descripción registrada por el conductor */}
        <div className="evidence-lightbox-footer">
          <div className="lightbox-short-info-header">
            <span className="lightbox-short-info-badge">{shortTitle}</span>
            <span className="lightbox-author-meta">
              <User size={12} /> Enviado por: <strong>{uploaderName}</strong> ({uploaderRole})
            </span>
          </div>
          <p className="lightbox-obs-text">
            {current.observations || shortTitle}
          </p>
          <div className="lightbox-meta-row">
            <span className="lightbox-meta-item">
              <Calendar size={13} /> {current.createdAt ? new Date(current.createdAt).toLocaleString('es-CO') : 'Fecha reciente'}
            </span>
            <span className="lightbox-meta-item">
              <ImageIcon size={13} /> Almacenado en Oracle Cloud Infrastructure (OCI)
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};
