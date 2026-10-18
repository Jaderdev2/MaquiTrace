import React, { useState } from 'react';
import type { Machine, User } from '../../../types';
import { Truck, MapPin, X, Loader2, CheckCircle2, AlertCircle } from 'lucide-react';

interface NewTripModalProps {
  isOpen: boolean;
  onClose: () => void;
  machines: Machine[];
  transporters: User[];
  onSubmit: (machineId: string, vehicle: string, destination: string) => Promise<void>;
  loading: boolean;
}

export const NewTripModal: React.FC<NewTripModalProps> = ({
  isOpen,
  onClose,
  machines,
  transporters,
  onSubmit,
  loading,
}) => {
  const [selectedMachineId, setSelectedMachineId] = useState<string>('');
  const [selectedTransporterId, setSelectedTransporterId] = useState<string>('');
  const [vehicle, setVehicle] = useState<string>('');
  const [destination, setDestination] = useState<string>('');
  const [error, setError] = useState<string | null>(null);

  if (!isOpen) return null;

  // Filtrar o priorizar máquinas completadas / listas para despacho
  const readyMachines = machines.filter((m) => m.status === 'completada' || m.status === 'pendiente');
  const availableMachines = readyMachines.length > 0 ? readyMachines : machines;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedMachineId) {
      setError('Por favor selecciona la maquinaria que será transportada.');
      return;
    }
    if (!vehicle.trim()) {
      setError('Por favor ingresa la descripción o placa del vehículo de transporte.');
      return;
    }
    if (!destination.trim()) {
      setError('Por favor ingresa el destino oficial de entrega.');
      return;
    }

    setError(null);
    try {
      await onSubmit(selectedMachineId, vehicle.trim(), destination.trim());
      onClose();
    } catch (err: any) {
      setError(err.message || 'Error al programar el viaje de transporte.');
    }
  };

  const quickVehicles = [
    'Camión Cama Baja Kenworth T800 (Placa: WKK-482)',
    'Tractomula Doble Troque Freightliner (Placa: TZN-901)',
    'Camión Plataforma Internacional 7600 (Placa: SQP-314)',
  ];

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal-content new-trip-modal-content" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <div className="modal-header-title">
            <div className="register-modal-icon-badge">
              <Truck size={20} />
            </div>
            <div>
              <h3>Programar Despacho y Transporte</h3>
              <span className="modal-header-sub">
                Asigna maquinaria lista, vehículo de carga y destino de entrega en obra.
              </span>
            </div>
          </div>
          <button className="btn-close" onClick={onClose} disabled={loading}>
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

          {/* Selección de Maquinaria */}
          <div className="form-group-field">
            <label htmlFor="machineSelect" className="field-label">
              Maquinaria para Transporte *
            </label>
            <select
              id="machineSelect"
              className="form-select-custom"
              value={selectedMachineId}
              onChange={(e) => setSelectedMachineId(e.target.value)}
              disabled={loading}
              required
            >
              <option value="">-- Seleccionar maquinaria lista --</option>
              {availableMachines.map((m) => (
                <option key={m.id} value={m.id}>
                  {m.model} (Serial: {m.serial}) · {m.category} · Estado: {m.status.toUpperCase()}
                </option>
              ))}
            </select>
            <span className="field-hint-text">
              Se recomienda seleccionar equipos en estado "COMPLETADA" con alistamiento técnico aprobado.
            </span>
          </div>

          {/* Conductor / Transportador */}
          {transporters.length > 0 && (
            <div className="form-group-field">
              <label htmlFor="transporterSelect" className="field-label">
                Conductor Asignado
              </label>
              <select
                id="transporterSelect"
                className="form-select-custom"
                value={selectedTransporterId}
                onChange={(e) => setSelectedTransporterId(e.target.value)}
                disabled={loading}
              >
                <option value="">-- Seleccionar transportador oficial (opcional) --</option>
                {transporters.map((t) => (
                  <option key={t.id} value={t.id}>
                    {t.name} ({t.phone || t.email})
                  </option>
                ))}
              </select>
            </div>
          )}

          {/* Vehículo / Placa */}
          <div className="form-group-field">
            <label htmlFor="vehicleInput" className="field-label">
              Vehículo de Carga y Placa *
            </label>
            <input
              id="vehicleInput"
              type="text"
              className="form-input-custom"
              placeholder="Ej: Camión Cama Baja Kenworth T800 (Placa: WKK-482)"
              value={vehicle}
              onChange={(e) => setVehicle(e.target.value)}
              disabled={loading}
              required
            />
            {/* Opciones rápidas */}
            <div className="quick-suggestions-row">
              <span className="suggestion-label">Sugerencias:</span>
              {quickVehicles.map((v) => (
                <button
                  key={v}
                  type="button"
                  className="btn-quick-suggestion"
                  onClick={() => setVehicle(v)}
                >
                  {v.split('(')[0].trim()}
                </button>
              ))}
            </div>
          </div>

          {/* Destino Oficial */}
          <div className="form-group-field">
            <label htmlFor="destinationInput" className="field-label">
              Destino Oficial de Entrega (Obra / Cliente) *
            </label>
            <div className="input-with-icon-wrap">
              <MapPin size={16} className="input-leading-icon" />
              <input
                id="destinationInput"
                type="text"
                className="form-input-custom has-leading-icon"
                placeholder="Ej: Proyecto Autopista al Mar 1, Tramo 3 - Medellín, Antioquia"
                value={destination}
                onChange={(e) => setDestination(e.target.value)}
                disabled={loading}
                required
              />
            </div>
          </div>

          <div className="modal-footer" style={{ padding: '16px 0 0 0', marginTop: '16px' }}>
            <button type="button" className="btn-secondary" onClick={onClose} disabled={loading}>
              Cancelar
            </button>
            <button type="submit" className="btn-primary-register" disabled={loading}>
              {loading ? (
                <>
                  <Loader2 size={16} className="spinner" />
                  <span>Programando despacho...</span>
                </>
              ) : (
                <>
                  <CheckCircle2 size={16} />
                  <span>Programar y Despachar Viaje</span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
