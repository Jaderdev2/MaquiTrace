import React, { useState } from 'react';
import { X, Plus, AlertCircle, CheckCircle2, Loader2, Truck } from 'lucide-react';
import { createMachineApi } from '../services/api';
import type { CreateMachineDto, Machine, MachineStatus } from '../types';
import { useAuth } from '../context/AuthContext';

interface Props {
  isOpen: boolean;
  onClose: () => void;
  onMachineCreated: (machine: Machine) => void;
}

const CATEGORY_OPTIONS = [
  'Excavadoras',
  'Cargadores frontales',
  'Retroexcavadoras',
  'Volquetas',
  'Motoniveladoras',
  'Otra...',
];

export const RegisterMachineModal: React.FC<Props> = ({
  isOpen,
  onClose,
  onMachineCreated,
}) => {
  const { token } = useAuth();
  const [serial, setSerial] = useState('');
  const [model, setModel] = useState('');
  const [categorySelect, setCategorySelect] = useState('Excavadoras');
  const [customCategory, setCustomCategory] = useState('');
  const [status, setStatus] = useState<MachineStatus>('pendiente');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    const cleanSerial = serial.trim().toUpperCase();
    const cleanModel = model.trim();
    const finalCategory =
      categorySelect === 'Otra...' ? customCategory.trim() : categorySelect;

    if (!cleanSerial) {
      setError('El número de serie o placa es obligatorio.');
      return;
    }
    if (!cleanModel) {
      setError('El modelo de la maquinaria es obligatorio.');
      return;
    }
    if (!finalCategory) {
      setError('Debe especificar la categoría de la maquinaria.');
      return;
    }

    if (!token) {
      setError('No hay sesión activa para realizar esta acción.');
      return;
    }

    const payload: CreateMachineDto = {
      serial: cleanSerial,
      model: cleanModel,
      category: finalCategory,
      status,
    };

    try {
      setLoading(true);
      const newMachine = await createMachineApi(payload, token);
      setSuccess(true);
      setTimeout(() => {
        onMachineCreated(newMachine);
        handleClose();
      }, 900);
    } catch (err: any) {
      setError(err.message || 'Error al registrar la maquinaria en el backend.');
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    setSerial('');
    setModel('');
    setCategorySelect('Excavadoras');
    setCustomCategory('');
    setStatus('pendiente');
    setError(null);
    setSuccess(false);
    onClose();
  };

  return (
    <div className="modal-backdrop" onClick={handleClose}>
      <div
        className="modal-content register-machine-modal-content"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="modal-header">
          <div className="modal-header-title">
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <div className="register-modal-icon-badge">
                <Truck size={20} />
              </div>
              <div>
                <h3>Registrar Nueva Maquinaria</h3>
                <span className="modal-header-sub">
                  Ingreso oficial de equipo al sistema para alistamiento e inspección
                </span>
              </div>
            </div>
          </div>
          <button className="btn-close" onClick={handleClose} disabled={loading} aria-label="Cerrar modal">
            <X size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="register-machine-form">
          <div className="modal-body">
            {error && (
              <div className="register-alert error">
                <AlertCircle size={18} />
                <span>{error}</span>
              </div>
            )}

            {success && (
              <div className="register-alert success">
                <CheckCircle2 size={18} />
                <span>¡Maquinaria registrada exitosamente en el sistema!</span>
              </div>
            )}

            <div className="form-grid">
              {/* Serial / Placa */}
              <div className="form-group">
                <label htmlFor="reg-serial" className="form-label">
                  Serial / Placa de Identificación <span className="req-star">*</span>
                </label>
                <input
                  id="reg-serial"
                  type="text"
                  className="form-input"
                  placeholder="Ej: ABC123, CAT-EX-200"
                  value={serial}
                  onChange={(e) => setSerial(e.target.value)}
                  disabled={loading || success}
                  autoFocus
                  required
                />
                <span className="form-help-text">
                  Identificador único del equipo según la placa del fabricante.
                </span>
              </div>

              {/* Modelo */}
              <div className="form-group">
                <label htmlFor="reg-model" className="form-label">
                  Modelo del Equipo <span className="req-star">*</span>
                </label>
                <input
                  id="reg-model"
                  type="text"
                  className="form-input"
                  placeholder="Ej: CAT 320D, Komatsu PC200"
                  value={model}
                  onChange={(e) => setModel(e.target.value)}
                  disabled={loading || success}
                  required
                />
                <span className="form-help-text">
                  Marca y especificación técnica comercial.
                </span>
              </div>

              {/* Categoría */}
              <div className="form-group">
                <label htmlFor="reg-category" className="form-label">
                  Categoría de Maquinaria <span className="req-star">*</span>
                </label>
                <select
                  id="reg-category"
                  className="form-select"
                  value={categorySelect}
                  onChange={(e) => setCategorySelect(e.target.value)}
                  disabled={loading || success}
                >
                  {CATEGORY_OPTIONS.map((opt) => (
                    <option key={opt} value={opt}>
                      {opt}
                    </option>
                  ))}
                </select>

                {categorySelect === 'Otra...' && (
                  <input
                    type="text"
                    className="form-input mt-2"
                    placeholder="Escriba la categoría personalizada"
                    value={customCategory}
                    onChange={(e) => setCustomCategory(e.target.value)}
                    disabled={loading || success}
                    required
                  />
                )}
              </div>

              {/* Estado Inicial */}
              <div className="form-group">
                <label htmlFor="reg-status" className="form-label">
                  Estado Operativo Inicial
                </label>
                <select
                  id="reg-status"
                  className="form-select"
                  value={status}
                  onChange={(e) => setStatus(e.target.value as MachineStatus)}
                  disabled={loading || success}
                >
                  <option value="pendiente">Pendiente (Sin iniciar alistamiento)</option>
                  <option value="en_proceso">En proceso (Alistamiento en curso)</option>
                  <option value="completada">Completada (Lista para despacho)</option>
                </select>
                <span className="form-help-text">
                  Normalmente se ingresa como 'Pendiente' hasta que un operario asuma la primera fase.
                </span>
              </div>
            </div>

            <div className="register-info-banner">
              <span className="info-banner-title">Flujo operativo posterior al registro:</span>
              <p>
                Una vez registrada la máquina en esta plataforma, estará disponible de inmediato en la
                app móvil para que los operarios le asignen fases de preparación y capturen las
                fotografías de inspección en los 4 ángulos obligatorios.
              </p>
            </div>
          </div>

          <div className="modal-footer">
            <button
              type="button"
              className="btn-secondary"
              onClick={handleClose}
              disabled={loading}
            >
              Cancelar
            </button>
            <button
              type="submit"
              className="btn-primary-register"
              disabled={loading || success}
            >
              {loading ? (
                <>
                  <Loader2 size={16} className="spinner" />
                  <span>Guardando en Servidor...</span>
                </>
              ) : (
                <>
                  <Plus size={16} />
                  <span>Registrar Maquinaria</span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
