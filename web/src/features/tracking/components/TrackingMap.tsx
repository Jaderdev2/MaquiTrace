import React, { useEffect, useRef, useState, useCallback } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import type { TransportTrip } from '../../../types';
import { getTripColorTheme } from '../utils/tripColors';
import {
  MAPBOX_STYLES,
  getMapboxTileUrl,
  MAPBOX_ACCESS_TOKEN,
} from '../services/mapboxService';
import { Maximize2, Moon, Sun, Globe, Navigation, X } from 'lucide-react';

interface TrackingMapProps {
  trips: TransportTrip[];
  selectedTripId?: string | null;
  onSelectTrip?: (trip: TransportTrip) => void;
  onOpenDetails?: (trip: TransportTrip) => void;
  height?: string | number;
}

type MapLayerType = 'day' | 'night' | 'satellite';

export const TrackingMap: React.FC<TrackingMapProps> = ({
  trips,
  selectedTripId,
  onSelectTrip,
  onOpenDetails,
  height = '520px',
}) => {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const layersGroupRef = useRef<L.LayerGroup | null>(null);
  const activeTileLayerRef = useRef<L.TileLayer | null>(null);

  // Estilo de Mapbox activo: 'day' (Navigation Day), 'night' (Navigation Night), 'satellite' (Satellite Streets)
  const [currentLayer, setCurrentLayer] = useState<MapLayerType>('day');

  // Estado para la ruta que el usuario elige visualizar en el mapa
  const [activeRouteTripId, setActiveRouteTripId] = useState<string | null>(null);

  // Sincronizar si se selecciona un viaje desde las tarjetas exteriores
  useEffect(() => {
    if (selectedTripId) {
      setActiveRouteTripId(selectedTripId);
    }
  }, [selectedTripId]);

  // Obtener URL de teselas según el estilo elegido
  const getTileConfig = (layerType: MapLayerType) => {
    let styleId = MAPBOX_STYLES.navigationDay;
    if (layerType === 'night') styleId = MAPBOX_STYLES.navigationNight;
    if (layerType === 'satellite') styleId = MAPBOX_STYLES.satelliteStreets;

    return {
      url: getMapboxTileUrl(styleId),
      options: {
        attribution: MAPBOX_ACCESS_TOKEN
          ? '&copy; <a href="https://www.mapbox.com/">Mapbox</a> &copy; OpenStreetMap'
          : '&copy; Esri & CartoDB',
        maxZoom: 19,
        tileSize: 256,
      },
    };
  };

  // Inicialización del mapa Leaflet con capa base de Mapbox
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

    // Cargar capa inicial (Navigation Day)
    const initialConfig = getTileConfig('day');
    const initialTiles = L.tileLayer(initialConfig.url, initialConfig.options);
    initialTiles.addTo(map);
    activeTileLayerRef.current = initialTiles;

    const layersGroup = L.layerGroup().addTo(map);
    layersGroupRef.current = layersGroup;
    mapInstanceRef.current = map;

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

  // Alternar estilo de capa de Mapbox (Día, Noche, Satélite)
  const handleChangeLayer = useCallback((newType: MapLayerType) => {
    const map = mapInstanceRef.current;
    if (!map) return;

    if (activeTileLayerRef.current) {
      map.removeLayer(activeTileLayerRef.current);
    }

    const config = getTileConfig(newType);
    const newTiles = L.tileLayer(config.url, config.options);
    newTiles.addTo(map);
    activeTileLayerRef.current = newTiles;
    setCurrentLayer(newType);

    map.invalidateSize();
  }, []);

  // Manejo de eventos de clic en los botones de detalles y ruta del popup
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

      // 2. Clic en botón "Ruta"
      const routeBtn = target.closest('.btn-popup-route') as HTMLElement;
      if (routeBtn) {
        const tripId = routeBtn.getAttribute('data-trip-id');
        if (tripId) {
          setActiveRouteTripId((prev) => (prev === tripId ? null : tripId));
        }
        return;
      }
    };

    container.addEventListener('click', handleContainerClick);
    return () => {
      container.removeEventListener('click', handleContainerClick);
    };
  }, [trips, onOpenDetails, onSelectTrip]);

  // Dibujar marcadores de vehículos e historial GPS transmitido por el celular
  useEffect(() => {
    const map = mapInstanceRef.current;
    const group = layersGroupRef.current;
    if (!map || !group) return;

    group.clearLayers();

    const activeTrip = trips.find((t) => t.id === activeRouteTripId);

    // 1. Trazado de ruta para el viaje seleccionado
    if (activeTrip && activeTrip.gpsRecords && activeTrip.gpsRecords.length > 0) {
      const activeIndex = trips.findIndex((t) => t.id === activeRouteTripId);
      const activeTheme = getTripColorTheme(activeTrip, activeIndex >= 0 ? activeIndex : 0);

      // Si tiene múltiples coordenadas enviadas por el transportador, usarlas
      let routeCoords: [number, number][] = activeTrip.gpsRecords.map((r) => [r.latitude, r.longitude]);

      // Si solo tiene 1 punto reportado o queremos calcular la ruta en carretera vía Mapbox Directions
      if (activeTrip.gpsRecords.length >= 2) {
        // Sombra de contraste para destacar el trazado sobre el mapa
        const shadowPolyline = L.polyline(routeCoords, {
          color: 'rgba(255, 255, 255, 0.85)',
          weight: 7,
          lineCap: 'round',
          lineJoin: 'round',
        });
        group.addLayer(shadowPolyline);

        // Línea principal de la carretera seguida por el vehículo
        const routePolyline = L.polyline(routeCoords, {
          color: activeTheme.primary,
          weight: 4.5,
          opacity: 1,
          lineCap: 'round',
          lineJoin: 'round',
        });
        group.addLayer(routePolyline);

        // Marcador de Origen
        const startGps = activeTrip.gpsRecords[0];
        const startIcon = L.divIcon({
          className: 'custom-map-marker-start',
          html: `
            <div class="map-pin-badge start-pin" title="Punto de Origen">
              <span class="pin-dot"></span>
            </div>
          `,
          iconSize: [22, 22],
          iconAnchor: [11, 11],
        });
        const startMarker = L.marker([startGps.latitude, startGps.longitude], { icon: startIcon });
        startMarker.bindTooltip('Punto de Origen');
        group.addLayer(startMarker);

        // Ajustar vista del mapa
        map.fitBounds(L.latLngBounds(routeCoords), { padding: [50, 50], maxZoom: 11 });
      }
    }

    // 2. Renderizar los marcadores de posición transmitidos por el transportador
    trips.forEach((trip, index) => {
      const records = trip.gpsRecords || [];
      if (records.length === 0) return;

      const isTransit = trip.status === 'en_transito';
      const isDelivered = trip.status === 'entregado';
      const isRouteActive = activeRouteTripId === trip.id;
      const theme = getTripColorTheme(trip, index);
      const truckColor = theme.primary;

      // Último punto GPS = Posición en vivo enviada desde el móvil
      const lastGps = records[records.length - 1];

      // Verificar si tiene incidentes reportados en ruta
      const hasIncidents = trip.incidents && trip.incidents.length > 0;

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
            ${hasIncidents ? `<span class="truck-incident-badge" title="Novedades viales reportadas">!</span>` : ''}
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

      // Contenido del Popup informativo sincronizado con la app móvil
      const popupHtml = `
        <div class="map-trip-popup">
          <div class="popup-header" style="border-left: 3px solid ${truckColor}; padding-left: 6px; display: flex; align-items: center; justify-content: space-between; gap: 6px;">
            <span class="popup-badge" style="background-color: ${theme.badgeBg}; color: ${theme.badgeText}; font-weight: 700;">
              ${theme.name}
            </span>
            <span class="popup-badge" style="background-color: ${isTransit ? '#EFF6FF' : isDelivered ? '#E8F5EC' : '#FEF3C7'}; color: ${isTransit ? '#2563EB' : isDelivered ? '#15803D' : '#B45309'};">
              ${isTransit ? 'En Tránsito (Móvil)' : isDelivered ? 'Entregado (POD)' : 'Pendiente de Salida'}
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
            <strong>Transportador:</strong> ${trip.transporter?.name || 'Conductor Asignado'}
          </p>

          ${hasIncidents ? `
            <div style="background: #FEF2F2; color: #DC2626; border: 1px solid #FEE2E2; border-radius: 6px; padding: 4px 8px; font-size: 11px; margin-top: 6px; display: flex; align-items: center; gap: 4px;">
              <strong>${trip.incidents?.length} novedad(es) reportada(s) desde el celular</strong>
            </div>
          ` : ''}

          <div class="popup-gps-meta">
            <span>Último reporte GPS: <strong>${lastGps.latitude.toFixed(4)}, ${lastGps.longitude.toFixed(4)}</strong> (${records.length} transmisiones)</span>
          </div>

          <div class="popup-actions-row">
            <button type="button" class="btn-popup-action btn-popup-details" data-trip-id="${trip.id}" title="Ver ficha técnica completa de máquina, conductor, actas y novedades">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
                <path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"></path>
                <circle cx="12" cy="12" r="3"></circle>
              </svg>
              <span>Detalles</span>
            </button>

            <button type="button" class="btn-popup-action btn-popup-route ${isRouteActive ? 'is-active-route' : ''}" data-trip-id="${trip.id}" title="${isRouteActive ? 'Ocultar trazado' : 'Ver trazado vial'}">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
                <polygon points="3 11 22 2 13 21 11 13 3 11"></polygon>
              </svg>
              <span>${isRouteActive ? 'Ocultar' : 'Ruta'}</span>
            </button>
          </div>
        </div>
      `;

      truckMarker.bindPopup(popupHtml, { maxWidth: 320, className: 'maquitrace-leaflet-popup' });
      group.addLayer(truckMarker);

      if (isRouteActive) {
        truckMarker.openPopup();
      }
    });
  }, [trips, activeRouteTripId]);

  // Centrar en toda la flota
  const handleFitAll = () => {
    const map = mapInstanceRef.current;
    if (!map) return;
    const allLatLngs: [number, number][] = [];
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

  return (
    <div className="tracking-map-wrapper" style={{ height }}>
      {/* Selector de Estilos Mapbox: Día (Navigation Day), Noche (Navigation Night) y Satélite (Satellite Streets) */}
      <div className="tracking-map-controls">
        <div className="map-layer-selector-group">
          <button
            type="button"
            className={`map-control-btn ${currentLayer === 'day' ? 'is-active-layer' : ''}`}
            onClick={() => handleChangeLayer('day')}
            title="Estilo Mapbox Navigation Day (Día)"
          >
            <Sun size={13} />
            <span>Mapbox Día</span>
          </button>

          <button
            type="button"
            className={`map-control-btn ${currentLayer === 'night' ? 'is-active-layer' : ''}`}
            onClick={() => handleChangeLayer('night')}
            title="Estilo Mapbox Navigation Night (Noche)"
          >
            <Moon size={13} />
            <span>Mapbox Noche</span>
          </button>

          <button
            type="button"
            className={`map-control-btn ${currentLayer === 'satellite' ? 'is-active-layer' : ''}`}
            onClick={() => handleChangeLayer('satellite')}
            title="Estilo Mapbox Satellite Streets (Satélite)"
          >
            <Globe size={13} />
            <span>Satélite</span>
          </button>
        </div>

        <button
          type="button"
          className="map-control-btn"
          onClick={handleFitAll}
          title="Centrar mapa en toda la flota de transporte"
        >
          <Maximize2 size={13} />
          <span>Centrar Flota</span>
        </button>
      </div>

      {/* Banner de ruta activa seleccionada */}
      {activeTripData && (
        <div className="map-active-route-banner">
          <Navigation size={15} style={{ color: '#60A5FA', flexShrink: 0 }} />
          <span>
            Ruta activa: <strong>{activeTripData.vehicle}</strong> (&rarr; {activeTripData.destination})
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

      {/* Contenedor del Mapa */}
      <div ref={mapContainerRef} className="tracking-leaflet-container" />
    </div>
  );
};

export default TrackingMap;
