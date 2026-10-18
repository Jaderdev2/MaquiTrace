import React, { useState } from 'react';
import type { TransportTrip, User } from '../../../types';
import { Truck, MapPin, X, Loader2, CheckCircle2, AlertCircle, Trash2, Edit3, User as UserIcon, ShieldAlert } from 'lucide-react';
import { checkMachineTransitReadiness } from '../utils/transitValidation';

interface EditTripModalProps {
  trip: TransportTrip;
  isOpen: boolean;
  onClose: () => void;
  transporters: User[];
  onUpdate: (
    tripId: string,
    payload: { vehicle?: string; destination?: string; transporterId?: string; status?: string }
  ) => Promise<void>;
  onDelete: (tripId: string) => Promise<void>;
  loading: boolean;
}

export const EditTripModal: React.FC<EditTripModalProps> = ({
  trip,
  isOpen,
  onClose,
  transporters,
  onUpdate,
  onDelete,
  loading,
}) => {
  const [vehicle, setVehicle] = useState<string>(trip.vehicle || '');
  const [destination, setDestination] = useState<string>(trip.destination || '');
  const [transporterId, setTransporterId] = useState<string>(
    trip.transporter?.id || trip.transporterId || ''
  );
  const [status, setStatus] = useState<string>(trip.status || 'pendiente');
  const [error, setError] = useState<string | null>(null);
  const [isDeleting, setIsDeleting] = useState<boolean>(false);

  if (!isOpen) return null;

  const readiness = checkMachineTransitReadiness(trip.machine);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!vehicle.trim()) {
      setError('Por favor ingresa la descripción del vehículo o placa.');
      return;
    }
    if (!destination.trim()) {
      setError('Por favor ingresa el destino de entrega.');
      return;
    }

    // Validación lógica: No pasar a en_transito si el alistamiento está incompleto
    if (status === 'en_transito' && trip.status === 'pendiente' && !readiness.canDepart) {
      setError(`Bloqueo operativo: No se puede cambiar a "En Tránsito". ${readiness.reason}`);
      return;
    }

    // Validación lógica: No pasar directamente de pendiente a entregado sin transitar
    if (status === 'entregado' && trip.status === 'pendiente') {
      setError('Un viaje no puede marcarse directamente como "Entregado" sin antes haber salido a carretera.');
      return;
    }

    setError(null);
    try {
      await onUpdate(trip.id, {
        vehicle: vehicle.trim(),
        destination: destination.trim(),
        transporterId: transporterId || undefined,
        status,
      });
      onClose();
    } catch (err: any) {
      setError(err.message || 'Error al actualizar el viaje de transporte.');
    }
  };

  const handleDelete = async () => {
    if (!window.confirm('¿Estás seguro de que deseas eliminar este viaje de transporte? Esta acción no se puede deshacer.')) {
      return;
    }
    setError(null);
    setIsDeleting(true);
    try {
      await onDelete(trip.id);
      onClose();
    } catch (err: any) {
      setError(err.message || 'Error al eliminar el viaje de transporte.');
    } finally {
      setIsDeleting(false);
    }
  };

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal-content new-trip-modal-content" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <div className="modal-header-title">
            <div className="register-modal-icon-badge" style={{ backgroundColor: '#EFF6FF', color: '#0066FF' }}>
              <Edit3 size={20} />
            </div>
            <div>
              <h3>Editar Viaje de Transporte</h3>
              <span className="modal-header-sub">
                Actualiza datos del vehículo, destino, conductor o estado del servicio.
              </span>
            </div>
          </div>
          <button className="btn-close" onClick={onClose} disabled={loading || isDeleting}>
            <X size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="modal-body new-trip-form">
          {error && (
            <div className="register-alert error">
              <AlertCircle size={16} />
              <span>{error}</span>
            </div>
          )}

          {/* Maquinaria asignada (informativo con validación de alistamiento) */}
          <div className="trip-card-section-box">
            <span className="trip-card-section-label">Maquinaria Asignada</span>
            <div className="trip-card-section-content">
              <strong className="trip-machine-label-text">
                {trip.machine ? `${trip.machine.model} (${trip.machine.serial})` : 'Maquinaria en transporte'}
              </strong>
              <span
                className={`pill-badge ${readiness.canDepart ? 'pill-status-ready' : 'pill-status-process'}`}
                style={{ fontSize: '10.5px' }}
              >
                {readiness.badgeLabel}
              </span>
            </div>
            {!readiness.canDepart && (
              <div className="transit-readiness-warning-box" style={{ marginTop: '8px' }}>
                <ShieldAlert size={15} className="warning-icon" />
                <div>
                  <strong>Alistamiento en Taller no finalizado:</strong>
                  <p>{readiness.reason}</p>
                </div>
              </div>
            )}
          </div>

          {/* Vehículo y Placa */}
          <div className="form-group-field">
            <label htmlFor="editVehicleInput" className="field-label">
              Vehículo de Carga y Placa *
            </label>
            <div className="input-with-icon-wrap">
              <Truck size={16} className="input-leading-icon" />
              <input
                id="editVehicleInput"
                type="text"
                className="form-input-custom has-leading-icon"
                value={vehicle}
                onChange={(e) => setVehicle(e.target.value)}
                disabled={loading || isDeleting}
                required
              />
            </div>
          </div>

          {/* Destino Oficial */}
          <div className="form-group-field">
            <label htmlFor="editDestinationInput" className="field-label">
              Destino Oficial de Entrega *
            </label>
            <div className="input-with-icon-wrap">
              <MapPin size={16} className="input-leading-icon" />
              <input
                id="editDestinationInput"
                type="text"
                className="form-input-custom has-leading-icon"
                value={destination}
                onChange={(e) => setDestination(e.target.value)}
                disabled={loading || isDeleting}
                required
              />
            </div>
          </div>

          {/* Conductor Asignado */}
          <div className="form-group-field">
            <label htmlFor="editTransporterSelect" className="field-label">
              Conductor / Transportador Asignado
            </label>
            <div className="input-with-icon-wrap">
              <UserIcon size={16} className="input-leading-icon" />
              <select
                id="editTransporterSelect"
                className="form-select-custom has-leading-icon"
                value={transporterId}
                onChange={(e) => setTransporterId(e.target.value)}
                disabled={loading || isDeleting}
              >
                <option value="">-- Sin conductor asignado --</option>
                {transporters.map((t) => (
                  <option key={t.id} value={t.id}>
                    {t.name} ({t.phone || t.email})
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Estado del Transporte */}
          <div className="form-group-field">
            <label htmlFor="editStatusSelect" className="field-label">
              Estado del Viaje
            </label>
            <select
              id="editStatusSelect"
              className="form-select-custom"
              value={status}
              onChange={(e) => setStatus(e.target.value)}
              disabled={loading || isDeleting}
            >
              <option value="pendiente">Pendiente de salida</option>
              <option value="en_transito" disabled={!readiness.canDepart && trip.status === 'pendiente'}>
                En tránsito satelital {!readiness.canDepart && trip.status === 'pendiente' ? '(Bloqueado por taller)' : ''}
              </option>
              <option value="entregado" disabled={trip.status === 'pendiente'}>
                Entregado en obra {trip.status === 'pendiente' ? '(Requiere haber salido a ruta)' : ''}
              </option>
            </select>
          </div>

          <div
            className="modal-footer"
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              padding: '16px 0 0 0',
              marginTop: '16px',
            }}
          >
            <button
              type="button"
              className="btn-danger-outline"
              onClick={handleDelete}
              disabled={loading || isDeleting}
              title="Eliminar este registro de transporte"
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                padding: '8px 12px',
                borderRadius: '8px',
                border: '1px solid #FECACA',
                backgroundColor: '#FEF2F2',
                color: '#DC2626',
                cursor: 'pointer',
                fontWeight: 600,
                fontSize: '12px',
              }}
            >
              {isDeleting ? <Loader2 size={14} className="spinner" /> : <Trash2 size={14} />}
              <span>Eliminar Viaje</span>
            </button>

            <div style={{ display: 'flex', gap: '8px' }}>
              <button
                type="button"
                className="btn-secondary"
                onClick={onClose}
                disabled={loading || isDeleting}
              >
                Cancelar
              </button>
              <button type="submit" className="btn-primary-register" disabled={loading || isDeleting}>
                {loading ? (
                  <>
                    <Loader2 size={16} className="spinner" />
                    <span>Guardando cambios...</span>
                  </>
                ) : (
                  <>
                    <CheckCircle2 size={16} />
                    <span>Guardar Cambios</span>
                  </>
                )}
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  );
};

export default EditTripModal;
