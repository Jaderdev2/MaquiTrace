import React from 'react';
import type { TransportTrip } from '../../../types';
import { User, Phone, Mail, Award, Clock, ShieldCheck, X, Truck, CreditCard } from 'lucide-react';

interface DriverDetailsModalProps {
  trip: TransportTrip;
  onClose: () => void;
}

export const DriverDetailsModal: React.FC<DriverDetailsModalProps> = ({ trip, onClose }) => {
  const driver = trip.transporter;

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal-content driver-modal-content" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <div className="modal-header-title">
            <div className="register-modal-icon-badge" style={{ backgroundColor: '#EEF2FF', color: '#4F46E5' }}>
              <User size={20} />
            </div>
            <div>
              <h3>Ficha Técnica del Conductor</h3>
              <span className="modal-header-sub">Perfil laboral y credenciales de transporte pesado</span>
            </div>
          </div>
          <button className="btn-close" onClick={onClose}>
            <X size={20} />
          </button>
        </div>

        <div className="modal-body driver-modal-body">
          {/* Cabecera del Conductor con Foto y Estado */}
          <div className="driver-profile-header-card">
            <div className="driver-avatar-container">
              {driver?.avatarUrl ? (
                <img src={driver.avatarUrl} alt={driver.name} className="driver-photo-img" />
              ) : (
                <div className="driver-photo-fallback">
                  <User size={36} />
                </div>
              )}
              <span className="driver-active-badge" title="Conductor activo en ruta" />
            </div>

            <div className="driver-profile-meta">
              <h3 className="driver-full-name">{driver?.name || 'Conductor Oficial MaquiTrace'}</h3>
              <div className="driver-tags-row">
                <span className="driver-role-tag">
                  <ShieldCheck size={12} /> Transportador Certificado
                </span>
                <span className="driver-status-tag">En Operación</span>
              </div>
            </div>
          </div>

          {/* Grid de Información Detallada */}
          <div className="driver-details-grid">
            {/* Cédula */}
            <div className="driver-info-cell">
              <div className="cell-icon-wrap icon-blue">
                <CreditCard size={16} />
              </div>
              <div className="cell-data">
                <span className="cell-label">Cédula de Ciudadanía</span>
                <strong className="cell-value">{driver?.cedula || 'CC 1.094.882.310'}</strong>
              </div>
            </div>

            {/* Tiempo Trabajando */}
            <div className="driver-info-cell">
              <div className="cell-icon-wrap icon-purple">
                <Clock size={16} />
              </div>
              <div className="cell-data">
                <span className="cell-label">Antigüedad en la Empresa</span>
                <strong className="cell-value">{driver?.experienceTime || '3 años y 4 meses'}</strong>
              </div>
            </div>

            {/* Licencia de Conducción */}
            <div className="driver-info-cell">
              <div className="cell-icon-wrap icon-emerald">
                <Award size={16} />
              </div>
              <div className="cell-data">
                <span className="cell-label">Categoría de Licencia</span>
                <strong className="cell-value">{driver?.licenseType || 'Licencia C3 (Carga Pesada)'}</strong>
              </div>
            </div>

            {/* Teléfono */}
            <div className="driver-info-cell">
              <div className="cell-icon-wrap icon-amber">
                <Phone size={16} />
              </div>
              <div className="cell-data">
                <span className="cell-label">Teléfono Móvil</span>
                <strong className="cell-value">{driver?.phone || '+57 312 458 9921'}</strong>
              </div>
            </div>

            {/* Correo Electrónico */}
            <div className="driver-info-cell" style={{ gridColumn: 'span 2' }}>
              <div className="cell-icon-wrap icon-blue">
                <Mail size={16} />
              </div>
              <div className="cell-data">
                <span className="cell-label">Correo Corporativo</span>
                <strong className="cell-value">{driver?.email || 'conductor@maquitrace.com'}</strong>
              </div>
            </div>

            {/* Vehículo Asignado */}
            <div className="driver-info-cell" style={{ gridColumn: 'span 2' }}>
              <div className="cell-icon-wrap icon-purple">
                <Truck size={16} />
              </div>
              <div className="cell-data">
                <span className="cell-label">Vehículo Asignado para este Servicio</span>
                <strong className="cell-value">{trip.vehicle}</strong>
                <span style={{ fontSize: '11px', color: '#64748B' }}>Destino de ruta: {trip.destination}</span>
              </div>
            </div>
          </div>
        </div>

        <div className="modal-footer">
          <button type="button" className="btn-secondary" onClick={onClose}>
            Cerrar Ficha
          </button>
        </div>
      </div>
    </div>
  );
};
