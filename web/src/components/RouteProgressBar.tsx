import React, { useEffect, useState } from 'react';
import { useLocation } from 'react-router-dom';

/**
 * Indicador láser superior que anima instantáneamente cada vez que el usuario
 * cambia de ruta (Dashboard -> Máquinas -> Alistamientos, etc.).
 * Brinda respuesta visual inmediata con una animación fluida de 60 FPS.
 */
export const RouteProgressBar: React.FC = () => {
  const location = useLocation();
  const [animating, setAnimating] = useState(false);

  useEffect(() => {
    // Activa la animación en cada cambio de ruta
    setAnimating(true);
    const timer = setTimeout(() => {
      setAnimating(false);
    }, 450);

    return () => clearTimeout(timer);
  }, [location.pathname]);

  if (!animating) return null;

  return (
    <div className="route-progress-bar-container" aria-hidden="true">
      <div className="route-progress-bar-line" />
      <div className="route-progress-bar-glow" />
    </div>
  );
};
