import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  static const routeBlue = Color(0xFF2563EB);

  static const double radius = 10;
  static const double radiusSmall = 6;
  static const double pagePadding = 16;

  // Panel deslizable (fracción de la altura disponible)
  static const double sheetInitial = 0.42;
  static const double sheetMax = 0.92;
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

  // Estilo del mapa: 'day', 'night', 'satellite'
  String _mapStyle = 'day';

  // Ruta real calculada por carretera
  MapboxRouteResult? _route;
  bool _isLoadingRoute = false;
  List<ll.LatLng> _realRoutePoints = [];
  ll.LatLng? _destinationCoords;

  // Posición actual del panel, para que los botones del mapa lo sigan
  final ValueNotifier<double> _sheetExtent = ValueNotifier<double>(_Ui.sheetInitial);

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

  static final RegExp _coordsRegex = RegExp(r'\((-?\d+\.?\d*),\s*(-?\d+\.?\d*)\)');

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip;
    _loadRoute();

    if (_currentTrip.isInTransit) {
      _startPeriodicGps();
    }
  }

  @override
  void dispose() {
    _stopPeriodicGps();
    _sheetExtent.dispose();
    super.dispose();
  }

  // ───────────────────────────── LÓGICA ─────────────────────────────

  /// Coordenadas escritas en el destino con formato "(lat, lng)", si existen.
  ll.LatLng? _explicitCoords(String destination) {
    final match = _coordsRegex.firstMatch(destination);
    if (match == null) return null;
    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat == null || lng == null) return null;
    return ll.LatLng(lat, lng);
  }

  /// Destino legible: sin las coordenadas entre paréntesis.
  String _cleanDestination(String destination) {
    final clean = destination.replaceAll(_coordsRegex, '').trim();
    return clean.isEmpty ? 'Punto seleccionado en el mapa' : clean;
  }

  Future<ll.LatLng> _resolveDestinationCoords(String destination) async {
    final explicit = _explicitCoords(destination);
    if (explicit != null) return explicit;

    final search = await _mapboxService.searchPlaces(
      destination,
      proximity: const ll.LatLng(3.8833, -77.0167),
    );
    if (search.isNotEmpty) {
      return search.first.center;
    }

    // Fallback: Cali / Yumbo
    return const ll.LatLng(3.4516, -76.5320);
  }

  ll.LatLng _truckPosition(TripModel trip) {
    final gps = trip.lastGps;
    if (gps != null && gps.latitude != 0 && gps.longitude != 0) {
      return ll.LatLng(gps.latitude, gps.longitude);
    }
    return _defaultFallbackWaypoints.first;
  }

  Future<void> _loadRoute() async {
    if (!mounted) return;
    setState(() => _isLoadingRoute = true);

    final origin = _truckPosition(_currentTrip);
    final dest = await _resolveDestinationCoords(_currentTrip.destination);
    _destinationCoords = dest;

    final route = await _mapboxService.getDrivingRoute(
      origin: origin,
      destination: dest,
    );

    if (!mounted) return;
    setState(() {
      _isLoadingRoute = false;
      if (route != null && route.points.isNotEmpty) {
        _route = route;
        _realRoutePoints = route.points;
      } else {
        _route = null;
        _realRoutePoints = _defaultFallbackWaypoints;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _fitRoute());
  }

  /// Encuadra la ruta completa dejando libre la parte que tapa el panel.
  void _fitRoute() {
    if (!mounted || _realRoutePoints.length < 2) return;
    final height = MediaQuery.of(context).size.height;
    try {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: _realRoutePoints,
          padding: EdgeInsets.fromLTRB(48, 110, 48, height * _Ui.sheetInitial + 48),
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

    ll.LatLng coords;
    if (_realRoutePoints.isNotEmpty) {
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
          const SnackBar(
            backgroundColor: _Ui.success,
            behavior: SnackBarBehavior.floating,
            content: Text('Ubicación actualizada'),
          ),
        );
      }
    }
  }

  Future<void> _launchExternalMap() async {
    final destination = _currentTrip.destination;
    final explicit = _explicitCoords(destination);
    final query = explicit != null
        ? '${explicit.latitude},${explicit.longitude}'
        : Uri.encodeComponent(_cleanDestination(destination));
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$query&travelmode=driving');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la navegación')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la navegación')),
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
          '¿Iniciar viaje?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        content: const Text(
          'El estado cambiará a "En tránsito" y se compartirá tu ubicación durante el recorrido.',
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
            child: const Text('Iniciar'),
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

  /// Actualiza la posición del panel sin provocar setState durante el layout.
  void _onSheetExtent(double extent) {
    if (_sheetExtent.value == extent) return;
    final phase = WidgetsBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sheetExtent.value = extent;
      });
    } else {
      _sheetExtent.value = extent;
    }
  }

  // ───────────────────────────── UI ─────────────────────────────

  String get _currentTileUrl {
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

  String _two(int n) => n.toString().padLeft(2, '0');

  // ── Mapa a pantalla completa ──

  Widget _buildMap(TripModel trip) {
    final truckPos = _truckPosition(trip);
    final destPos = _destinationCoords ?? _defaultFallbackWaypoints.last;
    final polylinePoints = _realRoutePoints.isNotEmpty ? _realRoutePoints : _defaultFallbackWaypoints;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: truckPos,
        initialZoom: 12.0,
        minZoom: 4.0,
        maxZoom: 18.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          key: ValueKey(_currentTileUrl),
          urlTemplate: _currentTileUrl,
          additionalOptions: const {
            'access_token': MapboxConstants.accessToken,
          },
          userAgentPackageName: 'com.example.maquitrace',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: polylinePoints,
              color: _mapStyle == 'day'
                  ? Colors.white.withValues(alpha: 0.9)
                  : const Color(0xFF1E3A8A).withValues(alpha: 0.9),
              strokeWidth: 7,
            ),
            Polyline(
              points: polylinePoints,
              color: _Ui.routeBlue,
              strokeWidth: 4.5,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: destPos,
              width: 38,
              height: 38,
              child: Container(
                decoration: BoxDecoration(
                  color: _Ui.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(color: _Ui.success.withValues(alpha: 0.4), blurRadius: 6),
                  ],
                ),
                child: const Icon(Icons.flag_rounded, color: Colors.white, size: 19),
              ),
            ),
            Marker(
              point: truckPos,
              width: 44,
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  color: _Ui.routeBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: _Ui.routeBlue.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Elementos flotantes ──

  BoxDecoration _floatingDecoration({double radius = 24}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.16),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _floatingPill({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: _floatingDecoration(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color? iconColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        elevation: 3,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, size: 22, color: iconColor ?? AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _styleItem(String key, IconData icon, String label) {
    final selected = _mapStyle == key;
    return PopupMenuItem<String>(
      value: key,
      child: Row(
        children: [
          Icon(icon, size: 20, color: selected ? AppColors.accentBlue : AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayersButton() {
    return Material(
      color: Colors.white,
      elevation: 3,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 48,
        height: 48,
        child: PopupMenuButton<String>(
          tooltip: 'Tipo de mapa',
          padding: EdgeInsets.zero,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_Ui.radius)),
          icon: const Icon(Icons.layers_outlined, size: 22, color: AppColors.textPrimary),
          onSelected: (value) => setState(() => _mapStyle = value),
          itemBuilder: (_) => [
            _styleItem('day', Icons.map_outlined, 'Mapa'),
            _styleItem('satellite', Icons.satellite_alt_outlined, 'Satélite'),
            _styleItem('night', Icons.nightlight_outlined, 'Noche'),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(TripModel trip) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              _circleButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Volver',
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 8),
              if (trip.isInTransit)
                _floatingPill(label: 'Ubicación en vivo', color: _Ui.success),
              const Spacer(),
              _floatingPill(label: trip.statusLabel, color: trip.statusColor),
            ],
          ),
        ),
      ),
    );
  }

  /// Botones del mapa y créditos: suben y bajan junto con el panel.
  Widget _buildMapOverlay(TripModel trip, double height) {
    final truckPos = _truckPosition(trip);
    return Positioned.fill(
      child: ValueListenableBuilder<double>(
        valueListenable: _sheetExtent,
        builder: (context, extent, _) {
          final hidden = extent > 0.7;
          final bottom = extent * height;
          return Stack(
            children: [
              Positioned(
                right: 12,
                bottom: bottom + 12,
                child: IgnorePointer(
                  ignoring: hidden,
                  child: AnimatedOpacity(
                    opacity: hidden ? 0 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLayersButton(),
                        const SizedBox(height: 10),
                        _circleButton(
                          icon: Icons.route_rounded,
                          tooltip: 'Ver ruta completa',
                          onTap: _fitRoute,
                        ),
                        const SizedBox(height: 10),
                        _circleButton(
                          icon: Icons.my_location_rounded,
                          tooltip: 'Mi ubicación',
                          iconColor: _Ui.routeBlue,
                          onTap: () => _mapController.move(truckPos, 15.0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                bottom: bottom + 6,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: hidden ? 0 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        '© Mapbox',
                        style: TextStyle(fontSize: 8, color: Color(0xFF475569)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Panel deslizable ──

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

  Widget _sheetHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 10),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _sheetHeader(TripModel trip) {
    final route = _route;
    final destination = _cleanDestination(trip.destination);
    final durationText = route != null
        ? route.formattedDuration
        : (_isLoadingRoute ? 'Calculando…' : 'Ruta estimada');
    final subtitle = route != null ? '${route.formattedDistance} · $destination' : destination;

    return Padding(
      padding: const EdgeInsets.fromLTRB(_Ui.pagePadding, 0, _Ui.pagePadding, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  durationText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _Ui.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _launchExternalMap,
            icon: const Icon(Icons.near_me_rounded, size: 18),
            label: const Text('Navegar'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextStepRow() {
    final steps = _route?.steps;
    if (steps == null || steps.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(_Ui.pagePadding, 0, _Ui.pagePadding, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _Ui.lockedBg,
          borderRadius: BorderRadius.circular(_Ui.radius),
        ),
        child: Row(
          children: [
            const Icon(Icons.turn_right_rounded, size: 20, color: AppColors.accentBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                steps.first,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _finishedBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_Ui.pagePadding, 0, _Ui.pagePadding, 14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _Ui.successBg,
          borderRadius: BorderRadius.circular(_Ui.radius),
          border: Border.all(color: _Ui.success.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: _Ui.success, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Entrega confirmada',
                    style: TextStyle(color: _Ui.success, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'El acta de entrega quedó firmada y registrada.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _destinationSection(TripModel trip, bool isFinished) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _Ui.pagePadding, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.place_outlined, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 12),
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
                  _cleanDestination(trip.destination),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _Ui.lockedBg,
              borderRadius: BorderRadius.circular(_Ui.radiusSmall),
            ),
            child: const Text(
              'Ruta fijada',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _Ui.locked),
            ),
          ),
        ],
      ),
    );
  }

  Widget _machineSection(TripModel trip) {
    final machine = trip.machine;
    return Padding(
      padding: const EdgeInsets.all(_Ui.pagePadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _Ui.lockedBg,
              borderRadius: BorderRadius.circular(_Ui.radiusSmall),
              border: Border.all(color: _Ui.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: machine != null
                ? machine.buildImage(fit: BoxFit.cover)
                : const Center(
                    child: Icon(Icons.precision_manufacturing_rounded, color: _Ui.locked, size: 26),
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
                    fontSize: 16,
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
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tripInfoSection(TripModel trip) {
    final departureAt = trip.departureAt;
    final departureText = departureAt != null
        ? '${_two(departureAt.hour)}:${_two(departureAt.minute)} · ${_two(departureAt.day)}/${_two(departureAt.month)}'
        : 'No ha iniciado';

    return Padding(
      padding: const EdgeInsets.all(_Ui.pagePadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildInfoItem('Hora de salida', departureText)),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoItem(
              'Transportador',
              trip.transporterName ?? 'Conductor asignado',
            ),
          ),
        ],
      ),
    );
  }

  Widget _incidentsSection(TripModel trip) {
    final count = trip.incidents.length;
    final subtitle = count == 0
        ? 'Sin novedades'
        : count == 1
            ? '1 reportada'
            : '$count reportadas';

    return Padding(
      padding: const EdgeInsets.fromLTRB(_Ui.pagePadding, 12, _Ui.pagePadding, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Novedades del trayecto',
                      style: TextStyle(
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
              TextButton.icon(
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
            ],
          ),
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
                          '${_two(inc.reportedAt.hour)}:${_two(inc.reportedAt.minute)} · ${inc.photoUrl != null ? "Con foto" : "Sin foto"}',
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
      ),
    );
  }

  Widget _buildSheet(TripModel trip, double height) {
    final isFinished = !trip.isPending && !trip.isInTransit;
    final minSize = (130 / height).clamp(0.12, 0.3).toDouble();

    return DraggableScrollableSheet(
      initialChildSize: _Ui.sheetInitial,
      minChildSize: minSize,
      maxChildSize: _Ui.sheetMax,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _Ui.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(color: Color(0x29000000), blurRadius: 14, offset: Offset(0, -2)),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              _sheetHandle(),
              _sheetHeader(trip),
              if (isFinished) _finishedBanner() else _nextStepRow(),
              const Divider(height: 1, color: _Ui.divider),
              _destinationSection(trip, isFinished),
              const Divider(height: 1, color: _Ui.divider),
              _machineSection(trip),
              const Divider(height: 1, color: _Ui.divider),
              _tripInfoSection(trip),
              const Divider(height: 1, color: _Ui.divider),
              _incidentsSection(trip),
              const SizedBox(height: 28),
            ],
          ),
        );
      },
    );
  }

  // ── Botón inferior ──

  Widget? _buildBottomBar(TransportProvider provider, TripModel trip) {
    final Widget button;
    if (trip.isPending) {
      button = FilledButton.icon(
        onPressed: () => _handleStartRoute(provider),
        icon: const Icon(Icons.play_arrow_rounded, size: 22),
        label: const Text('Iniciar viaje'),
        style: _primaryButtonStyle(AppColors.accentBlue),
      );
    } else if (trip.isInTransit) {
      button = FilledButton.icon(
        onPressed: _handleConfirmDelivery,
        icon: const Icon(Icons.check_circle_outline_rounded, size: 22),
        label: const Text('Confirmar entrega'),
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

    return Scaffold(
      backgroundColor: _Ui.background,
      bottomNavigationBar: _buildBottomBar(provider, trip),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          return NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              _onSheetExtent(notification.extent);
              return false;
            },
            child: Stack(
              children: [
                // El mapa ocupa todo el fondo y es independiente del scroll
                Positioned.fill(child: _buildMap(trip)),
                _buildMapOverlay(trip, height),
                _buildTopBar(trip),
                _buildSheet(trip, height),
              ],
            ),
          );
        },
      ),
    );
  }
}