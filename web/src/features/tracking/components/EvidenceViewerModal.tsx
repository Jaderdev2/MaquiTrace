import React, { useState } from 'react';
import type { Evidence } from '../../../types';
import { X, ChevronLeft, ChevronRight, Image as ImageIcon, Calendar } from 'lucide-react';

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

  const current = evidences[currentIndex];

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
        {/* Cabecera del visor */}
        <div className="evidence-lightbox-header">
          <div>
            <span className="lightbox-title">{machineTitle} - Evidencia de Inspección</span>
            <span className="lightbox-counter">
              Foto {currentIndex + 1} de {evidences.length}
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
            <img src={current.url} alt="Evidencia de maquinaria" className="lightbox-main-img" />
          </div>

          {evidences.length > 1 && (
            <button className="lightbox-nav-btn next" onClick={handleNext} title="Siguiente foto">
              <ChevronRight size={24} />
            </button>
          )}
        </div>

        {/* Pie con observaciones y fecha */}
        <div className="evidence-lightbox-footer">
          <p className="lightbox-obs-text">
            {current.observations || 'Registro fotográfico oficial de alistamiento y despacho de maquinaria.'}
          </p>
          <div className="lightbox-meta-row">
            <span className="lightbox-meta-item">
              <Calendar size={13} /> {new Date(current.createdAt).toLocaleString('es-CO')}
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
