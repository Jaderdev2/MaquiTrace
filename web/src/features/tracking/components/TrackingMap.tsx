import React, { useEffect, useRef, useState, useCallback } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import type { TransportTrip } from '../../../types';
import { getTripColorTheme } from '../utils/tripColors';
import { Maximize2, Mountain, Globe, Navigation, X, Crosshair } from 'lucide-react';

interface TrackingMapProps {
  trips: TransportTrip[];
  selectedTripId?: string | null;
  onSelectTrip?: (trip: TransportTrip) => void;
  onOpenDetails?: (trip: TransportTrip) => void;
  onUpdateLocation?: (tripId: string, lat: number, lng: number) => Promise<void>;
  height?: string | number;
}

type MapLayerType = 'topo' | 'satellite';

// Capas de mapas: Topográfico (por defecto) y Satelital
const TILE_CONFIG: Record<
  MapLayerType,
  {
    url: string;
    options: L.TileLayerOptions;
  }
> = {
  // Capa Topográfica y Vías Nacionales (Esri World Street Map - predeterminada, clara y estable)
  topo: {
    url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
    options: {
      attribution: '&copy; Esri, HERE, Garmin, USGS',
      maxZoom: 18,
    },
  },
  // Capa Satelital de alta resolución (Esri World Imagery)
  satellite: {
    url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    options: {
      attribution: '&copy; Esri, Maxar, Earthstar Geographics',
      maxZoom: 18,
    },
  },
};

// 20+ Regiones y nodos viales estratégicos de Colombia para la generación aleatoria realista
const COLOMBIA_REGIONS = [
  { name: 'Bogotá D.C. (Corredor Central)', lat: 4.6097, lng: -74.0817 },
  { name: 'Medellín, Antioquia (Valle de Aburrá)', lat: 6.2442, lng: -75.5812 },
  { name: 'Cali, Valle del Cauca', lat: 3.4516, lng: -76.5320 },
  { name: 'Buenaventura (Puerto Marítimo)', lat: 3.8826, lng: -77.0311 },
  { name: 'Tuluá, Valle (Centro Logístico)', lat: 4.0847, lng: -76.1954 },
  { name: 'Buga, Valle del Cauca', lat: 3.9009, lng: -76.2978 },
  { name: 'Pereira, Risaralda (Eje Cafetero)', lat: 4.8133, lng: -75.6961 },
  { name: 'Manizales, Caldas', lat: 5.0689, lng: -75.5174 },
  { name: 'Ibagué, Tolima (Paso La Línea)', lat: 4.4389, lng: -75.2322 },
  { name: 'La Pintada, Antioquia (Suroeste)', lat: 5.7481, lng: -75.6052 },
  { name: 'Bolombolo, Antioquia (Pacífico 2)', lat: 5.9723, lng: -75.8341 },
  { name: 'Bucaramanga, Santander', lat: 7.1254, lng: -73.1198 },
  { name: 'Barranquilla, Atlántico', lat: 10.9685, lng: -74.7813 },
  { name: 'Cartagena, Bolívar', lat: 10.3910, lng: -75.4794 },
  { name: 'Villavicencio, Meta (Vía al Llano)', lat: 4.1420, lng: -73.6266 },
  { name: 'Pasto, Nariño (Vía Panamericana)', lat: 1.2136, lng: -77.2811 },
  { name: 'Armenia, Quindío', lat: 4.5339, lng: -75.6811 },
  { name: 'Popayán, Cauca', lat: 2.4448, lng: -76.6147 },
  { name: 'Montería, Córdoba', lat: 8.7479, lng: -75.8814 },
  { name: 'Neiva, Huila', lat: 2.9273, lng: -75.2819 },
  { name: 'Cúcuta, Norte de Santander', lat: 7.8939, lng: -72.5078 },
];

export const TrackingMap: React.FC<TrackingMapProps> = ({
  trips,
  selectedTripId,
  onSelectTrip,
  onOpenDetails,
  onUpdateLocation,
  height = '520px',
}) => {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const layersGroupRef = useRef<L.LayerGroup | null>(null);
  const activeTileLayerRef = useRef<L.TileLayer | null>(null);

  // Iniciar siempre en el mapa topográfico
  const [currentLayer, setCurrentLayer] = useState<MapLayerType>('topo');

  // Estado para la ruta que el usuario elige visualizar en el mapa (por defecto null, sin líneas interpuestas)
  const [activeRouteTripId, setActiveRouteTripId] = useState<string | null>(null);

  // Estado de actualización de posición manual (cuando el usuario da clic en el mapa)
  const [manualLocTripId, setManualLocTripId] = useState<string | null>(null);

  // Sincronizar si se selecciona un viaje desde las tarjetas exteriores
  useEffect(() => {
    if (selectedTripId) {
      setActiveRouteTripId(selectedTripId);
    }
  }, [selectedTripId]);

  // Inicialización del mapa Leaflet
  useEffect(() => {
    if (!mapContainerRef.current) return;
    if (mapInstanceRef.current) return;

    // Centro inicial: Corredor Occidente - Centro de Colombia (Buenaventura a Bogotá / Medellín)
    const map = L.map(mapContainerRef.current, {
      center: [4.65, -75.8],
      zoom: 7,
      zoomControl: false,
      preferCanvas: true,
    });

    L.control.zoom({ position: 'bottomright' }).addTo(map);

    // Cargar capa base inicial: Topográfico
    const config = TILE_CONFIG.topo;
    const initialTiles = L.tileLayer(config.url, config.options);
    initialTiles.addTo(map);
    activeTileLayerRef.current = initialTiles;

    const layersGroup = L.layerGroup().addTo(map);
    layersGroupRef.current = layersGroup;
    mapInstanceRef.current = map;

    // Asegurar redimensionamiento inmediato
    const timer = setTimeout(() => {
      map.invalidateSize();
    }, 200);

    const resizeObserver = new ResizeObserver(() => {
      map.invalidateSize();
    });
    if (mapContainerRef.current) {
      resizeObserver.observe(mapContainerRef.current);
    }

    return () => {
      clearTimeout(timer);
      resizeObserver.disconnect();
      map.remove();
      mapInstanceRef.current = null;
    };
  }, []);

  // Alternar capa base (Topográfico / Satélite)
  const handleChangeLayer = useCallback((newType: MapLayerType) => {
    const map = mapInstanceRef.current;
    if (!map) return;

    if (activeTileLayerRef.current) {
      map.removeLayer(activeTileLayerRef.current);
    }

    const config = TILE_CONFIG[newType];
    const newTiles = L.tileLayer(config.url, config.options);
    newTiles.addTo(map);
    activeTileLayerRef.current = newTiles;
    setCurrentLayer(newType);

    map.invalidateSize();
  }, []);

  // Escuchar clic en el mapa cuando está activo el Modo Manual de Localización
  useEffect(() => {
    const map = mapInstanceRef.current;
    if (!map) return;

    const handleMapClick = (e: L.LeafletMouseEvent) => {
      if (!manualLocTripId) return;

      const lat = Number(e.latlng.lat.toFixed(4));
      const lng = Number(e.latlng.lng.toFixed(4));

      if (onUpdateLocation) {
        onUpdateLocation(manualLocTripId, lat, lng);
      }
      setManualLocTripId(null);
    };

    map.on('click', handleMapClick);
    return () => {
      map.off('click', handleMapClick);
    };
  }, [manualLocTripId, onUpdateLocation]);

  // Manejo de eventos de clic en los botones del popup: [Detalles], [Ruta] y [Localización -> Manual / Aleatoria]
  useEffect(() => {
    const container = mapContainerRef.current;
    if (!container) return;

    const handleContainerClick = (e: MouseEvent) => {
      const target = e.target as HTMLElement;

      // 1. Clic en botón "Detalles"
      const detailsBtn = target.closest('.btn-popup-details') as HTMLElement;
      if (detailsBtn) {
        const tripId = detailsBtn.getAttribute('data-trip-id');
        const found = trips.find((t) => t.id === tripId);
        if (found) {
          if (onOpenDetails) onOpenDetails(found);
          else if (onSelectTrip) onSelectTrip(found);
        }
        return;
      }

      // 2. Clic en botón "Ruta" (alternar mostrar/ocultar ruta en el mapa)
      const routeBtn = target.closest('.btn-popup-route') as HTMLElement;
      if (routeBtn) {
        const tripId = routeBtn.getAttribute('data-trip-id');
        if (tripId) {
          setActiveRouteTripId((prev) => (prev === tripId ? null : tripId));
        }
        return;
      }

      // 3. Clic en botón "Localización" (desplegar sub-opciones Manual / Aleatoria)
      const locToggleBtn = target.closest('.btn-popup-loc-toggle') as HTMLElement;
      if (locToggleBtn) {
        const tripId = locToggleBtn.getAttribute('data-trip-id');
        const subBox = document.getElementById(`loc-suboptions-${tripId}`);
        if (subBox) {
          const isVisible = subBox.style.display !== 'none';
          subBox.style.display = isVisible ? 'none' : 'block';
          locToggleBtn.classList.toggle('is-loc-expanded', !isVisible);
        }
        return;
      }

      // 4. Sub-opción A: Ubicación Manual (esperar clic en el mapa)
      const manualBtn = target.closest('.btn-loc-manual') as HTMLElement;
      if (manualBtn) {
        const tripId = manualBtn.getAttribute('data-trip-id');
        if (tripId) {
          setManualLocTripId(tripId);
          // Cerrar popups para facilitar clic en el mapa
          if (mapInstanceRef.current) {
            mapInstanceRef.current.closePopup();
          }
        }
        return;
      }

      // 5. Sub-opción B: Ubicación Aleatoria dentro del territorio de Colombia
      const randomBtn = target.closest('.btn-loc-random') as HTMLElement;
      if (randomBtn) {
        const tripId = randomBtn.getAttribute('data-trip-id');
        if (tripId && onUpdateLocation) {
          // Seleccionar nodo colombiano y aplicar variación sutil
          const baseRegion = COLOMBIA_REGIONS[Math.floor(Math.random() * COLOMBIA_REGIONS.length)];
          const deltaLat = (Math.random() - 0.5) * 0.15;
          const deltaLng = (Math.random() - 0.5) * 0.15;
          const lat = Number((baseRegion.lat + deltaLat).toFixed(4));
          const lng = Number((baseRegion.lng + deltaLng).toFixed(4));

          onUpdateLocation(tripId, lat, lng);

          if (mapInstanceRef.current) {
            mapInstanceRef.current.flyTo([lat, lng], 10, { duration: 1.2 });
          }
        }
        return;
      }
    };

    container.addEventListener('click', handleContainerClick);
    return () => {
      container.removeEventListener('click', handleContainerClick);
    };
  }, [trips, onOpenDetails, onSelectTrip, onUpdateLocation]);

  // Dibujar marcadores e icono único por vehículo.
  // SOLO se dibuja la línea de ruta para el viaje que el usuario elija ver.
  useEffect(() => {
    const map = mapInstanceRef.current;
    const group = layersGroupRef.current;
    if (!map || !group) return;

    group.clearLayers();

    const activeTrip = trips.find((t) => t.id === activeRouteTripId);

    // 1. DIBUJAR RUTA EXCLUSIVA SOLO SI EL USUARIO ACTIVÓ "VER RUTA" EN UN VEHÍCULO
    if (activeTrip && activeTrip.gpsRecords && activeTrip.gpsRecords.length > 1) {
      const activeIndex = trips.findIndex((t) => t.id === activeRouteTripId);
      const activeTheme = getTripColorTheme(activeTrip, activeIndex >= 0 ? activeIndex : 0);
      const activePathCoords: L.LatLngExpression[] = activeTrip.gpsRecords.map((r) => [r.latitude, r.longitude]);

      // Sombra de contraste para destacar el trazado sobre el mapa
      const shadowPolyline = L.polyline(activePathCoords, {
        color: 'rgba(255, 255, 255, 0.85)',
        weight: 7,
        lineCap: 'round',
        lineJoin: 'round',
      });
      group.addLayer(shadowPolyline);

      // Línea principal de la carretera seguida por el vehículo
      const routePolyline = L.polyline(activePathCoords, {
        color: activeTheme.primary,
        weight: 4.5,
        opacity: 1,
        lineCap: 'round',
        lineJoin: 'round',
      });
      group.addLayer(routePolyline);

      // Marcador de Origen (Puerto de Buenaventura)
      const startGps = activeTrip.gpsRecords[0];
      const startIcon = L.divIcon({
        className: 'custom-map-marker-start',
        html: `
          <div class="map-pin-badge start-pin" title="Punto de Origen: Buenaventura">
            <span class="pin-dot"></span>
          </div>
        `,
        iconSize: [22, 22],
        iconAnchor: [11, 11],
      });
      const startMarker = L.marker([startGps.latitude, startGps.longitude], { icon: startIcon });
      startMarker.bindTooltip(`Origen: Puerto de Buenaventura`);
      group.addLayer(startMarker);

      // Ajustar vista del mapa para encuadrar la ruta completa
      map.fitBounds(L.latLngBounds(activePathCoords), { padding: [50, 50], maxZoom: 11 });
    }

    // 2. DIBUJAR CADA VEHÍCULO ÚNICAMENTE EN SU POSICIÓN ACTUAL (SIN LÍNEAS QUE SE INTERPONGAN)
    trips.forEach((trip, index) => {
      const records = trip.gpsRecords || [];
      if (records.length === 0) return;

      const isTransit = trip.status === 'en_transito';
      const isDelivered = trip.status === 'entregado';
      const isRouteActive = activeRouteTripId === trip.id;
      const theme = getTripColorTheme(trip, index);
      const truckColor = theme.primary;

      // Último punto GPS = Posición actual en tiempo real
      const lastGps = records[records.length - 1];

      const liveIcon = L.divIcon({
        className: 'custom-map-marker-truck',
        html: `
          <div class="map-truck-marker-wrap ${isTransit ? 'is-pulsing' : ''}" style="--truck-color: ${truckColor};">
            <div class="truck-marker-circle" style="background-color: ${truckColor} !important; border: 2.5px solid #FFFFFF; ${isRouteActive ? 'box-shadow: 0 0 0 4px #0F172A;' : ''}">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2"></path>
                <path d="M15 18H9"></path>
                <path d="M19 18h2a1 1 0 0 0 1-1v-3.65a1 1 0 0 0-.22-.624l-3.48-4.35A1 1 0 0 0 17.52 8H14v10Z"></path>
                <circle cx="17" cy="18.5" r="2.5"></circle>
                <circle cx="7" cy="18.5" r="2.5"></circle>
              </svg>
            </div>
            ${isTransit ? `<span class="truck-radar-wave" style="background-color: ${truckColor} !important;"></span>` : ''}
          </div>
        `,
        iconSize: [36, 36],
        iconAnchor: [18, 18],
      });

      const truckMarker = L.marker([lastGps.latitude, lastGps.longitude], {
        icon: liveIcon,
        zIndexOffset: isRouteActive ? 1200 : 500,
      });

      // Contenido del Popup con las opciones: [Detalles], [Ruta] y [Localización]
      const popupHtml = `
        <div class="map-trip-popup">
          <div class="popup-header" style="border-left: 3px solid ${truckColor}; padding-left: 6px; display: flex; align-items: center; justify-content: space-between; gap: 6px;">
            <span class="popup-badge" style="background-color: ${theme.badgeBg}; color: ${theme.badgeText}; font-weight: 700;">
              ${theme.name}
            </span>
            <span class="popup-badge" style="background-color: #F1F5F9; color: #475569;">
              ${isTransit ? 'En Tránsito' : isDelivered ? 'Entregado' : 'Listo'}
            </span>
          </div>
          <h4 class="popup-title" style="color: ${truckColor}; margin-bottom: 2px;">${trip.vehicle}</h4>
          <p class="popup-sub">
            <strong>Máquina:</strong> ${trip.machine ? `${trip.machine.model} (${trip.machine.serial})` : 'Maquinaria Asignada'}
          </p>
          <p class="popup-sub">
            <strong>Destino:</strong> ${trip.destination}
          </p>
          <p class="popup-sub">
            <strong>Conductor:</strong> ${trip.transporter?.name || 'Transportador Oficial'}
          </p>

          <div class="popup-gps-meta">
            <span>Ubicación actual: <strong>${lastGps.latitude.toFixed(4)}, ${lastGps.longitude.toFixed(4)}</strong> (${records.length} pts)</span>
          </div>

          <div class="popup-actions-row">
            <button type="button" class="btn-popup-action btn-popup-details" data-trip-id="${trip.id}" title="Ver ficha técnica completa de máquina, conductor y evidencias">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
                <path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"></path>
                <circle cx="12" cy="12" r="3"></circle>
              </svg>
              <span>Detalles</span>
            </button>

            <button type="button" class="btn-popup-action btn-popup-route ${isRouteActive ? 'is-active-route' : ''}" data-trip-id="${trip.id}" title="${isRouteActive ? 'Ocultar trazado' : 'Ver trazado vial de este camión'}">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
                <polygon points="3 11 22 2 13 21 11 13 3 11"></polygon>
              </svg>
              <span>${isRouteActive ? 'Ocultar' : 'Ruta'}</span>
            </button>

            <button type="button" class="btn-popup-action btn-popup-loc-toggle" data-trip-id="${trip.id}" title="Actualizar ubicación del transportador">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
                <circle cx="12" cy="12" r="10"></circle>
                <circle cx="12" cy="12" r="3"></circle>
              </svg>
              <span>Localización</span>
            </button>
          </div>

          <div class="popup-loc-suboptions" id="loc-suboptions-${trip.id}" style="display: none;">
            <span class="loc-suboptions-title">Actualizar posición satelital:</span>
            <div class="loc-suboptions-grid">
              <button type="button" class="btn-suboption btn-loc-manual" data-trip-id="${trip.id}" title="Hacer clic en cualquier parte del mapa">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
                  <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
                  <circle cx="12" cy="10" r="3"></circle>
                </svg>
                <span>Manual (Clic en mapa)</span>
              </button>

              <button type="button" class="btn-suboption btn-loc-random" data-trip-id="${trip.id}" title="Generar posición aleatoria en Colombia">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
                  <path d="M21.5 2v6h-6M21.34 15.57a10 10 0 1 1-.57-8.38l5.67-5.67"></path>
                </svg>
                <span>Aleatoria (Colombia)</span>
              </button>
            </div>
          </div>
        </div>
      `;

      truckMarker.bindPopup(popupHtml, { maxWidth: 320, className: 'maquitrace-leaflet-popup' });
      group.addLayer(truckMarker);

      // Si este camión tiene la ruta activa, mantener su popup abierto
      if (isRouteActive) {
        truckMarker.openPopup();
      }
    });
  }, [trips, activeRouteTripId]);

  // Centrar en toda la flota de transporte
  const handleFitAll = () => {
    const map = mapInstanceRef.current;
    if (!map) return;
    const allLatLngs: L.LatLngExpression[] = [];
    trips.forEach((t) => {
      const records = t.gpsRecords || [];
      if (records.length > 0) {
        const last = records[records.length - 1];
        allLatLngs.push([last.latitude, last.longitude]);
      }
    });
    if (allLatLngs.length > 0) {
      map.fitBounds(L.latLngBounds(allLatLngs), { padding: [50, 50] });
    } else {
      map.setView([4.65, -75.8], 7);
    }
  };

  const activeTripData = trips.find((t) => t.id === activeRouteTripId);
  const manualTripData = trips.find((t) => t.id === manualLocTripId);

  return (
    <div
      className={`tracking-map-wrapper ${manualLocTripId ? 'is-manual-picking-mode' : ''}`}
      style={{ height }}
    >
      {/* Selector de Capas Flotante: Topográfico (Predeterminado) y Satelital */}
      <div className="tracking-map-controls">
        <div className="map-layer-selector-group">
          <button
            type="button"
            className={`map-control-btn ${currentLayer === 'topo' ? 'is-active-layer' : ''}`}
            onClick={() => handleChangeLayer('topo')}
            title="Vista Topográfica de Carreteras y Relieve Nacional (Predeterminado)"
          >
            <Mountain size={13} />
            <span>Topográfico</span>
          </button>

          <button
            type="button"
            className={`map-control-btn ${currentLayer === 'satellite' ? 'is-active-layer' : ''}`}
            onClick={() => handleChangeLayer('satellite')}
            title="Vista Satelital Fotográfica (Esri World Imagery)"
          >
            <Globe size={13} />
            <span>Satélite</span>
          </button>
        </div>

        <button
          type="button"
          className="map-control-btn"
          onClick={handleFitAll}
          title="Centrar en las ubicaciones de todos los camiones"
        >
          <Maximize2 size={13} />
          <span>Centrar Flota</span>
        </button>
      </div>

      {/* Banner interactivo cuando está activo el Modo Manual de Clic en el Mapa */}
      {manualLocTripId && (
        <div className="map-manual-mode-banner">
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Crosshair size={16} className="pulse-icon" style={{ color: '#EF4444' }} />
            <span>
              <strong>Modo Asignación Manual:</strong> Haz clic en cualquier punto del mapa para posicionar a{' '}
              <strong>{manualTripData?.vehicle || 'este transportador'}</strong>.
            </span>
          </div>
          <button
            type="button"
            className="btn-cancel-manual-mode"
            onClick={() => setManualLocTripId(null)}
          >
            <X size={12} style={{ display: 'inline', marginRight: '3px' }} />
            Cancelar
          </button>
        </div>
      )}

      {/* Cartel flotante cuando se está mostrando la ruta trazada de un camión en el mapa */}
      {activeTripData && !manualLocTripId && (
        <div className="map-active-route-banner">
          <Navigation size={15} style={{ color: '#60A5FA', flexShrink: 0 }} />
          <span>
            Ruta activa: <strong>{activeTripData.vehicle}</strong> (Buenaventura &rarr; {activeTripData.destination})
          </span>
          <button
            type="button"
            className="btn-clear-map-route"
            onClick={() => setActiveRouteTripId(null)}
            title="Ocultar trazado y volver a solo ver camiones"
          >
            <X size={12} style={{ display: 'inline', marginRight: '3px' }} />
            Ocultar Ruta
          </button>
        </div>
      )}

      {/* Contenedor Leaflet */}
      <div ref={mapContainerRef} className="tracking-leaflet-container" />
    </div>
  );
};

export default TrackingMap;
