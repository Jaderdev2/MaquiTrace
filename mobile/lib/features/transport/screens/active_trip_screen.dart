import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/mapbox_constants.dart';
import '../../../core/services/mapbox_service.dart';
import '../../../core/theme/app_colors.dart';
import '../models/trip_model.dart';
import '../providers/transport_provider.dart';
import '../widgets/delivery_confirmation_modal.dart';
import '../widgets/edit_trip_modal.dart';
import '../widgets/report_incident_modal.dart';

class _Ui {
  static const background = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFEDF1F5);

  static const success = Color(0xFF15803D);
  static const successBg = Color(0xFFE8F5EC);
  static const danger = Color(0xFFDC2626);
  static const locked = Color(0xFF64748B);
  static const lockedBg = Color(0xFFF1F5F9);

  static const double radius = 10;
  static const double radiusSmall = 6;
  static const double pagePadding = 16;
}

class ActiveTripScreen extends StatefulWidget {
  final TripModel trip;

  const ActiveTripScreen({
    super.key,
    required this.trip,
  });

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  bool _isSendingGps = false;
  late TripModel _currentTrip;
  Timer? _periodicGpsTimer;
  final MapController _mapController = MapController();
  final MapboxService _mapboxService = MapboxService();

  // Estilo de mapa Mapbox activo: 'day', 'night', 'satellite'
  String _mapStyle = 'day';

  // Ruta real calculada por carretera con Mapbox Directions
  MapboxRouteResult? _mapboxRoute;
  bool _isLoadingRoute = false;
  List<ll.LatLng> _realRoutePoints = [];
  ll.LatLng? _destinationCoords;

  int _gpsStep = 0;

  // Corredor de transporte de maquinaria pesada Pacífico - Valle (fallback referencial)
  final List<ll.LatLng> _defaultFallbackWaypoints = [
    const ll.LatLng(3.8833, -77.0167), // Buenaventura (Patio Portuario)
    const ll.LatLng(3.8412, -76.9124), // Córdoba - Cisneros
    const ll.LatLng(3.7333, -76.6833), // Loboguerrero (Paso de montaña)
    const ll.LatLng(3.6558, -76.6917), // Dagua
    const ll.LatLng(3.5833, -76.4833), // Yumbo (Zona Industrial)
    const ll.LatLng(3.4516, -76.5320), // Cali (Destino Obra)
  ];

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip;
    _loadMapboxRoute();

    if (_currentTrip.isInTransit) {
      _startPeriodicGps();
    }
  }

  @override
  void dispose() {
    _stopPeriodicGps();
    super.dispose();
  }

  /// Extrae o geocodifica las coordenadas del destino del viaje
  Future<ll.LatLng> _resolveDestinationCoords(String destination) async {
    // 1. Intentar extraer "(lat, lng)" si el usuario lo seleccionó en el mapa
    final regex = RegExp(r'\((-?\d+\.?\d*),\s*(-?\d+\.?\d*)\)');
    final match = regex.firstMatch(destination);
    if (match != null) {
      final lat = double.tryParse(match.group(1)!);
      final lng = double.tryParse(match.group(2)!);
      if (lat != null && lng != null) {
        return ll.LatLng(lat, lng);
      }
    }

    // 2. Si no tiene coordenadas explícitas, consultar a Mapbox Places Geocoding
    final search = await _mapboxService.searchPlaces(
      destination,
      proximity: const ll.LatLng(3.8833, -77.0167),
    );
    if (search.isNotEmpty) {
      return search.first.center;
    }

    // 3. Fallback: Cali / Yumbo
    return const ll.LatLng(3.4516, -76.5320);
  }

  /// Consulta la ruta real de conducción por carretera a Mapbox Directions API
  Future<void> _loadMapboxRoute() async {
    if (!mounted) return;
    setState(() => _isLoadingRoute = true);

    final lastGps = _currentTrip.lastGps;
    final origin = (lastGps != null && lastGps.latitude != 0)
        ? ll.LatLng(lastGps.latitude, lastGps.longitude)
        : _defaultFallbackWaypoints.first;

    final dest = await _resolveDestinationCoords(_currentTrip.destination);
    _destinationCoords = dest;

    final route = await _mapboxService.getDrivingRoute(
      origin: origin,
      destination: dest,
    );

    if (mounted) {
      setState(() {
        _isLoadingRoute = false;
        if (route != null && route.points.isNotEmpty) {
          _mapboxRoute = route;
          _realRoutePoints = route.points;
        } else {
          _realRoutePoints = _defaultFallbackWaypoints;
        }
      });

      // Centrar el mapa para ver el camión y la ruta
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _realRoutePoints.isNotEmpty) {
          _fitRouteInMap(origin, dest);
        }
      });
    }
  }

  void _fitRouteInMap(ll.LatLng truckPos, ll.LatLng destPos) {
    try {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: [truckPos, destPos],
          padding: const EdgeInsets.all(40),
        ),
      );
    } catch (_) {}
  }

  void _startPeriodicGps() {
    _stopPeriodicGps();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _transmitGpsLocation(context.read<TransportProvider>(), silent: true);
      }
    });

    // Transmisión periódica automática cada 45 segundos en segundo plano
    _periodicGpsTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (mounted && _currentTrip.isInTransit) {
        _transmitGpsLocation(context.read<TransportProvider>(), silent: true);
      }
    });
  }

  void _stopPeriodicGps() {
    _periodicGpsTimer?.cancel();
    _periodicGpsTimer = null;
  }

  TripModel _getUpdatedTrip(TransportProvider provider) {
    return provider.myTrips.firstWhere(
      (t) => t.id == _currentTrip.id,
      orElse: () => _currentTrip,
    );
  }

  Future<void> _transmitGpsLocation(TransportProvider provider, {bool silent = false}) async {
    if (_isSendingGps && silent) return;

    if (!silent) {
      setState(() => _isSendingGps = true);
    }

    // Usar puntos reales calculados por Mapbox Directions a lo largo de la carretera
    ll.LatLng coords;
    if (_realRoutePoints.isNotEmpty) {
      // Avanzar gradualmente a lo largo del trazado real
      final stepIndex = (_gpsStep * 120) % _realRoutePoints.length;
      coords = _realRoutePoints[stepIndex];
    } else {
      coords = _defaultFallbackWaypoints[_gpsStep % _defaultFallbackWaypoints.length];
    }
    _gpsStep++;

    final success = await provider.updateGps(
      tripId: _currentTrip.id,
      latitude: coords.latitude,
      longitude: coords.longitude,
    );

    if (mounted) {
      if (!silent) {
        setState(() => _isSendingGps = false);
      }
      if (success && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _Ui.success,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Posición GPS transmitida: Lat ${coords.latitude.toStringAsFixed(4)}, Lng ${coords.longitude.toStringAsFixed(4)}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _launchExternalMap(String destination) async {
    final query = Uri.encodeComponent(destination);
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$query');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir la app de mapas externa')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enlazar con Google Maps / Waze')),
        );
      }
    }
  }

  Future<void> _handleStartRoute(TransportProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Iniciar ruta de transporte',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        content: const Text(
          '¿Confirmas la salida de la maquinaria hacia su destino? El estado cambiará a "En tránsito" y el GPS iniciará telemetría automática.',
          style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_Ui.radius)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar salida'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await provider.startTrip(machineId: _currentTrip.machineId);
      if (success && mounted) {
        setState(() {
          _currentTrip = _currentTrip.copyWith(status: TripStatus.enTransito);
        });
        _startPeriodicGps();
      }
    }
  }

  Future<void> _handleConfirmDelivery() async {
    // Abre el Acta Oficial de Entrega Digital (POD) como modal bottom sheet
    final delivered = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeliveryConfirmationModal(trip: _currentTrip),
    );

    if (delivered == true && mounted) {
      _stopPeriodicGps();
      setState(() {
        _currentTrip = _currentTrip.copyWith(status: TripStatus.entregado);
      });
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _handleEditTripDetails() async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => EditTripModal(trip: _currentTrip),
    );

    if (updated == true && mounted) {
      final provider = context.read<TransportProvider>();
      setState(() {
        _currentTrip = _getUpdatedTrip(provider);
      });
      // Recalcular la ruta de Mapbox con el nuevo destino
      _loadMapboxRoute();
    }
  }

  // ───────────────────────────── CONSTRUCCIÓN DE UI ─────────────────────────────

  String get _currentMapboxTileUrl {
    switch (_mapStyle) {
      case 'night':
        return MapboxConstants.navigationNight;
      case 'satellite':
        return MapboxConstants.satelliteStreets;
      case 'day':
      default:
        return MapboxConstants.navigationDay;
    }
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _Ui.surface,
      borderRadius: BorderRadius.circular(_Ui.radius),
      border: Border.all(color: _Ui.border),
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Widget _buildChip(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_Ui.radiusSmall),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _buildCardHeader({
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing,
        ],
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildMapCard(TripModel trip) {
    final lastGps = trip.lastGps;
    final truckLat = (lastGps != null && lastGps.latitude != 0) ? lastGps.latitude : _defaultFallbackWaypoints.first.latitude;
    final truckLng = (lastGps != null && lastGps.longitude != 0) ? lastGps.longitude : _defaultFallbackWaypoints.first.longitude;
    final truckPos = ll.LatLng(truckLat, truckLng);

    final destPos = _destinationCoords ?? _defaultFallbackWaypoints.last;
    final polylinePoints = _realRoutePoints.isNotEmpty ? _realRoutePoints : _defaultFallbackWaypoints;

    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera con selector de capas Mapbox
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Navegación Mapbox HD',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (_isLoadingRoute)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accentBlue),
                            ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _mapboxRoute != null
                            ? 'Ruta por carretera: ${_mapboxRoute!.summary}'
                            : (trip.isInTransit ? 'Transmisión activa en carretera' : 'Ruta proyectada en carretera'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Selector de Estilos Mapbox: Día / Noche / Satélite (0 emojis)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStyleChip('day', Icons.wb_sunny_outlined, 'Día'),
                      _buildStyleChip('night', Icons.nightlight_outlined, 'Noche'),
                      _buildStyleChip('satellite', Icons.satellite_alt_outlined, 'Sat'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lienzo interactivo de Mapbox
          SizedBox(
            height: 250,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: truckPos,
                    initialZoom: 12.0,
                    minZoom: 4.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      key: ValueKey(_currentMapboxTileUrl),
                      urlTemplate: _currentMapboxTileUrl,
                      additionalOptions: const {
                        'access_token': MapboxConstants.accessToken,
                      },
                      userAgentPackageName: 'com.example.maquitrace',
                    ),

                    // Trazado de ruta real sobre la carretera con doble capa (efecto neón / contraste)
                    PolylineLayer(
                      polylines: [
                        // Capa base de contraste/resaltado
                        Polyline(
                          points: polylinePoints,
                          color: _mapStyle == 'night'
                              ? const Color(0xFF1E3A8A).withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.9),
                          strokeWidth: 6.5,
                        ),
                        // Capa de ruta activa en azul navegación
                        Polyline(
                          points: polylinePoints,
                          color: const Color(0xFF2563EB),
                          strokeWidth: 4.5,
                        ),
                      ],
                    ),

                    MarkerLayer(
                      markers: [
                        // Marcador de la ubicación del camión
                        Marker(
                          point: truckPos,
                          width: 44,
                          height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                        // Marcador del punto de destino
                        Marker(
                          point: destPos,
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _Ui.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: _Ui.success.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.flag_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Indicador flotante de telemetría GPS en tiempo real
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: trip.isInTransit ? const Color(0xFF16A34A) : AppColors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          trip.isInTransit ? 'GPS en vivo · 45s' : 'GPS en espera',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: trip.isInTransit ? const Color(0xFF15803D) : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Controles de zoom y centrado
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Column(
                    children: [
                      _buildMapButton(
                        icon: Icons.my_location_rounded,
                        onTap: () => _mapController.move(truckPos, 14.0),
                        tooltip: 'Centrar en mi camión',
                      ),
                      const SizedBox(height: 6),
                      _buildMapButton(
                        icon: Icons.fit_screen_rounded,
                        onTap: () => _fitRouteInMap(truckPos, destPos),
                        tooltip: 'Ajustar ruta completa',
                      ),
                      const SizedBox(height: 6),
                      _buildMapButton(
                        icon: Icons.add_rounded,
                        onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                        tooltip: 'Acercar',
                      ),
                      const SizedBox(height: 6),
                      _buildMapButton(
                        icon: Icons.remove_rounded,
                        onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                        tooltip: 'Alejar',
                      ),
                    ],
                  ),
                ),

                // Créditos de Mapbox
                Positioned(
                  bottom: 4,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '© Mapbox · © OpenStreetMap',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── TIRA DE TELEMETRÍA LOGÍSTICA REAL DE MAPBOX ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Métrica 1: Distancia real
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.straighten_rounded, size: 16, color: AppColors.accentBlue),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Distancia',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                ),
                                Text(
                                  _mapboxRoute != null ? _mapboxRoute!.formattedDistance : 'Calculando...',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Métrica 2: Tiempo estimado (ETA)
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5EC),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF15803D)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tiempo est.',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                ),
                                Text(
                                  _mapboxRoute != null ? _mapboxRoute!.formattedDuration : 'En cálculo...',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Botón para navegar por voz con Google Maps o Waze
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_Ui.radiusSmall)),
                      ),
                      icon: const Icon(Icons.near_me_rounded, size: 15),
                      label: const Text('Navegar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      onPressed: () => _launchExternalMap(trip.destination),
                    ),
                  ],
                ),

                // Próxima instrucción o maniobra de la ruta si existe
                if (_mapboxRoute?.steps != null && _mapboxRoute!.steps.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.turn_right_rounded, size: 16, color: AppColors.accentBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _mapboxRoute!.steps.first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleChip(String styleKey, IconData icon, String label) {
    final isSelected = _mapStyle == styleKey;
    return InkWell(
      onTap: () {
        setState(() => _mapStyle = styleKey);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(icon, size: 18, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget? _buildBottomBar(TransportProvider provider, TripModel trip) {
    final Widget button;
    if (trip.isPending) {
      button = FilledButton.icon(
        onPressed: () => _handleStartRoute(provider),
        icon: const Icon(Icons.play_arrow_rounded, size: 22),
        label: const Text('Iniciar marcha en carretera'),
        style: _primaryButtonStyle(AppColors.accentBlue),
      );
    } else if (trip.isInTransit) {
      button = FilledButton.icon(
        onPressed: _handleConfirmDelivery,
        icon: const Icon(Icons.assignment_turned_in_rounded, size: 22),
        label: const Text('Firmar y Confirmar Entrega (POD)'),
        style: _primaryButtonStyle(_Ui.success),
      );
    } else {
      return null;
    }

    return Container(
      decoration: const BoxDecoration(
        color: _Ui.surface,
        border: Border(top: BorderSide(color: _Ui.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(_Ui.pagePadding),
          child: SizedBox(width: double.infinity, child: button),
        ),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle(Color color) {
    return FilledButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_Ui.radius)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransportProvider>();
    final trip = _getUpdatedTrip(provider);

    final machine = trip.machine;
    final departureAt = trip.departureAt;
    final isFinished = !trip.isPending && !trip.isInTransit;

    final departureText = departureAt != null
        ? '${_two(departureAt.hour)}:${_two(departureAt.minute)} · ${_two(departureAt.day)}/${_two(departureAt.month)}'
        : 'No ha iniciado';

    final incidentCount = trip.incidents.length;
    final incidentSubtitle = incidentCount == 0
        ? 'Sin novedades'
        : incidentCount == 1
            ? '1 reportada'
            : '$incidentCount reportadas';

    return Scaffold(
      backgroundColor: _Ui.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          'Cabina de ruta',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: _Ui.pagePadding),
              child: _buildChip(trip.statusLabel, trip.statusColor, trip.statusBgColor),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: _Ui.border),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(provider, trip),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(_Ui.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Aviso cuando el servicio ya fue entregado
            if (isFinished) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _Ui.successBg,
                  borderRadius: BorderRadius.circular(_Ui.radius),
                  border: Border.all(color: _Ui.success.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded, color: _Ui.success, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Servicio Entregado Oficialmente',
                            style: TextStyle(
                              color: _Ui.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'El equipo cuenta con acta de entrega (POD) firmada en destino y registrada a satisfacción.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Ficha de la máquina
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _Ui.lockedBg,
                      borderRadius: BorderRadius.circular(_Ui.radiusSmall),
                      border: Border.all(color: _Ui.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: machine != null
                        ? machine.buildImage(fit: BoxFit.cover)
                        : const Center(
                            child: Icon(
                              Icons.precision_manufacturing_rounded,
                              color: _Ui.locked,
                              size: 28,
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          machine?.model ?? 'Maquinaria pesada',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Serial ${machine?.serial ?? "N/A"} · ${machine?.category ?? "General"}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Remolque: '),
                              TextSpan(
                                text: trip.vehicle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Destino, datos de salida y botón de edición
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.place_outlined, color: AppColors.textSecondary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Destino de entrega',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              trip.destination,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isFinished)
                        IconButton(
                          tooltip: 'Editar destino o remolque',
                          icon: const Icon(Icons.edit_note_rounded, size: 24, color: AppColors.accentBlue),
                          onPressed: _handleEditTripDetails,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: _Ui.divider),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildInfoItem('Hora de salida', departureText),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoItem(
                          'Transportador',
                          trip.transporterName ?? 'Conductor Asignado',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // MAPA INTERACTIVO MAPBOX HD + TIRA DE TELEMETRÍA Y NAVEGACIÓN
            _buildMapCard(trip),
            const SizedBox(height: 16),

            // Novedades e incidencias en ruta
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCardHeader(
                    title: 'Novedades del trayecto',
                    subtitle: incidentSubtitle,
                    trailing: TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => ReportIncidentModal(trip: trip),
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Reportar'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accentBlue,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (trip.incidents.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: _Ui.divider),
                    ...trip.incidents.map((inc) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1),
                              child: Icon(Icons.warning_amber_rounded, size: 20, color: _Ui.danger),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    inc.description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_two(inc.reportedAt.hour)}:${_two(inc.reportedAt.minute)} · ${inc.photoUrl != null ? "Con foto adjunta" : "Sin foto"}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (inc.photoUrl != null) ...[
                              const SizedBox(width: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(_Ui.radiusSmall),
                                child: Image.network(
                                  inc.photoUrl!,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
