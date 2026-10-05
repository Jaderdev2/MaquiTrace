import React from 'react';
import type { Machine } from '../types';
import { X, CheckCircle2, Clock, FileText, Camera, Calendar, Wrench } from 'lucide-react';

interface Props {
  machine: Machine | null;
  onClose: () => void;
}

export const MachineDetailModal: React.FC<Props> = ({ machine, onClose }) => {
  if (!machine) return null;

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
        <div className="modal-header">
          <div className="modal-title-box">
            <div className="serial-tag">{machine.serial}</div>
            <div>
              <h3>{machine.model}</h3>
              <span className="modal-subtitle">Categoría: {machine.category}</span>
            </div>
          </div>
          <button className="btn-close" onClick={onClose}>
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
              <div className="detail-val"><Calendar size={14} /> {machine.createdAt ? new Date(machine.createdAt).toLocaleDateString('es-ES') : 'Reciente'}</div>
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

          {/* Galería de Evidencias */}
          <div className="section-block">
            <h4 className="section-title">
              <Camera size={16} /> Evidencias Fotográficas Vinculadas
            </h4>
            {machine.evidence && machine.evidence.length > 0 ? (
              <div className="evidence-grid">
                {machine.evidence.map((ev) => (
                  <div key={ev.id} className="evidence-item">
                    <img src={ev.url} alt="Evidencia" />
                  </div>
                ))}
              </div>
            ) : (
              <div className="evidence-placeholder">
                <Camera size={28} className="placeholder-icon" />
                <p>Las fotografías tomadas desde la app móvil del operario se sincronizarán aquí automáticamente.</p>
              </div>
            )}
          </div>
        </div>

        <div className="modal-footer">
          <button className="btn-secondary" onClick={onClose}>Cerrar Detalle</button>
        </div>
      </div>
    </div>
  );
};
