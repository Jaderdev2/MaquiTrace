import React, { useState } from 'react';
import { X, Plus, AlertCircle, CheckCircle2, Loader2, Truck, Camera, Upload, Trash2 } from 'lucide-react';
import { createMachineApi, uploadMachineAvatarApi } from '../services/api';
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
  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [avatarPreview, setAvatarPreview] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  if (!isOpen) return null;

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      setAvatarFile(file);
      setAvatarPreview(URL.createObjectURL(file));
    }
  };

  const handleRemoveAvatar = () => {
    setAvatarFile(null);
    if (avatarPreview) {
      URL.revokeObjectURL(avatarPreview);
      setAvatarPreview(null);
    }
  };

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

      // Si el administrador seleccionó una foto de avatar, subirla a Oracle Cloud mediante el nuevo endpoint dedicado
      if (avatarFile) {
        try {
          const res = await uploadMachineAvatarApi(newMachine.id, avatarFile, token);
          if (res?.imageUrl) {
            newMachine.imageUrl = res.imageUrl;
          }
        } catch (uploadErr) {
          console.warn('Detalle al subir avatar a OCI:', uploadErr);
        }
      }

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
    handleRemoveAvatar();
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
                  Ingreso oficial de equipo y asignación de foto de perfil
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

            {/* SECCIÓN DE AVATAR / FOTO DE PERFIL DE LA MÁQUINA */}
            <div className="avatar-picker-section">
              <label className="form-label" style={{ marginBottom: '8px', display: 'block' }}>
                <Camera size={14} style={{ display: 'inline', marginRight: '5px', verticalAlign: 'middle' }} />
                Foto de Perfil / Avatar del Equipo (Opcional)
              </label>

              <div className="avatar-picker-wrapper">
                <div className="avatar-preview-box">
                  {avatarPreview ? (
                    <img src={avatarPreview} alt="Preview avatar" className="avatar-preview-image" />
                  ) : (
                    <div className="avatar-preview-empty">
                      <Truck size={32} />
                      <span>Sin imagen</span>
                    </div>
                  )}
                </div>

                <div className="avatar-picker-controls">
                  <label className="btn-upload-avatar">
                    <Upload size={14} />
                    <span>{avatarPreview ? 'Cambiar imagen...' : 'Seleccionar foto...'}</span>
                    <input
                      type="file"
                      accept="image/png, image/jpeg, image/jpg, image/webp"
                      onChange={handleFileChange}
                      disabled={loading || success}
                      style={{ display: 'none' }}
                    />
                  </label>

                  {avatarPreview && (
                    <button
                      type="button"
                      className="btn-remove-avatar"
                      onClick={handleRemoveAvatar}
                      disabled={loading || success}
                      title="Quitar imagen seleccionada"
                    >
                      <Trash2 size={14} /> Quitar
                    </button>
                  )}
                  <span className="avatar-helper-text">
                    La imagen se guardará en Oracle Cloud y servirá como el avatar principal del equipo.
                  </span>
                </div>
              </div>
            </div>

            <div className="form-grid" style={{ marginTop: '16px' }}>
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
              </div>
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
