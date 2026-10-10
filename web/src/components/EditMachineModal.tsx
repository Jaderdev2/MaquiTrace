import React, { useState, useEffect } from 'react';
import { X, Check, AlertCircle, CheckCircle2, Loader2, Truck, Camera, Upload, Trash2, Edit } from 'lucide-react';
import { updateMachineApi, uploadMachineAvatarApi } from '../services/api';
import type { CreateMachineDto, Machine, MachineStatus } from '../types';
import { useAuth } from '../context/AuthContext';
import { getMachineProfileImage } from '../utils/evidence';

interface Props {
  isOpen: boolean;
  machine: Machine | null;
  onClose: () => void;
  onMachineUpdated: (machine: Machine) => void;
}

const CATEGORY_OPTIONS = [
  'Excavadoras',
  'Cargadores frontales',
  'Retroexcavadoras',
  'Volquetas',
  'Motoniveladoras',
  'Otra...',
];

export const EditMachineModal: React.FC<Props> = ({
  isOpen,
  machine,
  onClose,
  onMachineUpdated,
}) => {
  const { token } = useAuth();
  const [serial, setSerial] = useState('');
  const [model, setModel] = useState('');
  const [categorySelect, setCategorySelect] = useState('Excavadoras');
  const [customCategory, setCustomCategory] = useState('');
  const [status, setStatus] = useState<MachineStatus>('pendiente');
  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [avatarPreview, setAvatarPreview] = useState<string | null>(null);
  const [currentAvatarUrl, setCurrentAvatarUrl] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  useEffect(() => {
    if (machine) {
      setSerial(machine.serial || '');
      setModel(machine.model || '');
      setStatus(machine.status || 'pendiente');

      if (CATEGORY_OPTIONS.includes(machine.category)) {
        setCategorySelect(machine.category);
        setCustomCategory('');
      } else {
        setCategorySelect('Otra...');
        setCustomCategory(machine.category || '');
      }

      const existingPhoto = getMachineProfileImage(machine);
      setCurrentAvatarUrl(existingPhoto);
      setAvatarFile(null);
      setAvatarPreview(null);
      setError(null);
      setSuccess(false);
    }
  }, [machine, isOpen]);

  if (!isOpen || !machine) return null;

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      setAvatarFile(file);
      setAvatarPreview(URL.createObjectURL(file));
    }
  };

  const handleRemoveNewAvatar = () => {
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
      setError('El serial o placa es obligatorio.');
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

    const payload: Partial<CreateMachineDto> = {
      serial: cleanSerial,
      model: cleanModel,
      category: finalCategory,
      status,
    };

    try {
      setLoading(true);
      let updated = await updateMachineApi(machine.id, payload, token);

      // Si se seleccionó una nueva foto de avatar, subirla a Oracle Cloud y actualizar imageUrl
      if (avatarFile) {
        try {
          const evidence = await uploadMachineAvatarApi(machine.id, avatarFile, token);
          if (evidence) {
            updated = await updateMachineApi(machine.id, { imageUrl: evidence.url }, token);
            updated.imageUrl = evidence.url;
            updated.evidence = [evidence, ...(updated.evidence || machine.evidence || [])];
          }
        } catch (uploadErr) {
          console.warn('Datos guardados, pero hubo un detalle al subir la foto a OCI:', uploadErr);
        }
      } else {
        // Mantener las evidencias previas si la respuesta no las incluye
        if (!updated.evidence && machine.evidence) {
          updated.evidence = machine.evidence;
        }
      }

      setSuccess(true);
      setTimeout(() => {
        onMachineUpdated(updated);
        handleClose();
      }, 800);
    } catch (err: any) {
      setError(err.message || 'Error al actualizar la maquinaria en el backend.');
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    handleRemoveNewAvatar();
    setError(null);
    setSuccess(false);
    onClose();
  };

  const displayAvatar = avatarPreview || currentAvatarUrl;

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
                <Edit size={20} />
              </div>
              <div>
                <h3>Editar Maquinaria</h3>
                <span className="modal-header-sub">
                  Actualización de ficha y foto de perfil del equipo {machine.serial}
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
                <span>¡Maquinaria actualizada con éxito!</span>
              </div>
            )}

            {/* SECCIÓN DE AVATAR / FOTO DE PERFIL */}
            <div className="avatar-picker-section">
              <label className="form-label" style={{ marginBottom: '8px', display: 'block' }}>
                <Camera size={14} style={{ display: 'inline', marginRight: '5px', verticalAlign: 'middle' }} />
                Foto de Perfil / Avatar del Equipo
              </label>

              <div className="avatar-picker-wrapper">
                <div className="avatar-preview-box">
                  {displayAvatar ? (
                    <img src={displayAvatar} alt="Avatar de maquinaria" className="avatar-preview-image" />
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
                    <span>{avatarPreview ? 'Cambiar imagen...' : currentAvatarUrl ? 'Reemplazar foto...' : 'Seleccionar foto...'}</span>
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
                      onClick={handleRemoveNewAvatar}
                      disabled={loading || success}
                    >
                      <Trash2 size={14} /> Deshacer cambio
                    </button>
                  )}
                  <span className="avatar-helper-text">
                    La fotografía se almacenará en Oracle Cloud y servirá como el avatar principal del equipo.
                  </span>
                </div>
              </div>
            </div>

            <div className="form-grid" style={{ marginTop: '16px' }}>
              {/* Serial / Placa */}
              <div className="form-group">
                <label htmlFor="edit-serial" className="form-label">
                  Serial / Placa <span className="req-star">*</span>
                </label>
                <input
                  id="edit-serial"
                  type="text"
                  className="form-input"
                  value={serial}
                  onChange={(e) => setSerial(e.target.value)}
                  disabled={loading || success}
                  required
                />
              </div>

              {/* Modelo */}
              <div className="form-group">
                <label htmlFor="edit-model" className="form-label">
                  Modelo del Equipo <span className="req-star">*</span>
                </label>
                <input
                  id="edit-model"
                  type="text"
                  className="form-input"
                  value={model}
                  onChange={(e) => setModel(e.target.value)}
                  disabled={loading || success}
                  required
                />
              </div>

              {/* Categoría */}
              <div className="form-group">
                <label htmlFor="edit-category" className="form-label">
                  Categoría <span className="req-star">*</span>
                </label>
                <select
                  id="edit-category"
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
                    placeholder="Categoría personalizada"
                    value={customCategory}
                    onChange={(e) => setCustomCategory(e.target.value)}
                    disabled={loading || success}
                    required
                  />
                )}
              </div>

              {/* Estado */}
              <div className="form-group">
                <label htmlFor="edit-status" className="form-label">
                  Estado Operativo
                </label>
                <select
                  id="edit-status"
                  className="form-select"
                  value={status}
                  onChange={(e) => setStatus(e.target.value as MachineStatus)}
                  disabled={loading || success}
                >
                  <option value="pendiente">Pendiente</option>
                  <option value="en_proceso">En proceso</option>
                  <option value="completada">Completada</option>
                  <option value="en_transito">En tránsito</option>
                  <option value="entregada">Entregada</option>
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
                  <span>Guardando Cambios...</span>
                </>
              ) : (
                <>
                  <Check size={16} />
                  <span>Actualizar Maquinaria</span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
