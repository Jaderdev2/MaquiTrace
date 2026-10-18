import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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

  // Corredor de transporte de maquinaria pesada Pacífico - Valle (Buenaventura a Cali/Yumbo)
  int _gpsStep = 0;
  final List<List<double>> _routeWaypoints = [
    [3.8833, -77.0167], // Buenaventura (Patio Portuario)
    [3.8412, -76.9124], // Córdoba - Cisneros
    [3.7333, -76.6833], // Loboguerrero (Paso de montaña)
    [3.6558, -76.6917], // Dagua
    [3.5833, -76.4833], // Yumbo (Zona Industrial)
    [3.4516, -76.5320], // Cali (Destino Obra)
  ];

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip;
    if (_currentTrip.isInTransit) {
      _startPeriodicGps();
    }
  }

  @override
  void dispose() {
    _stopPeriodicGps();
    super.dispose();
  }

  void _startPeriodicGps() {
    _stopPeriodicGps();
    // Transmitir primer punto en segundo plano tras renderizar
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

    final coords = _routeWaypoints[_gpsStep % _routeWaypoints.length];
    _gpsStep++;

    final success = await provider.updateGps(
      tripId: _currentTrip.id,
      latitude: coords[0],
      longitude: coords[1],
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
              'Posición GPS transmitida: Lat ${coords[0].toStringAsFixed(4)}, Lng ${coords[1].toStringAsFixed(4)}',
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
    }
  }

  // ───────────────────────────── CONSTRUCCIÓN DE UI ─────────────────────────────

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
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildMapCard(TripModel trip) {
    final lastGps = trip.lastGps;
    final truckLat = lastGps != null && lastGps.latitude != 0 ? lastGps.latitude : _routeWaypoints.first[0];
    final truckLng = lastGps != null && lastGps.longitude != 0 ? lastGps.longitude : _routeWaypoints.first[1];
    final truckPos = ll.LatLng(truckLat, truckLng);

    // Destino geográfico referencial
    final destPos = ll.LatLng(_routeWaypoints.last[0], _routeWaypoints.last[1]);

    final polylinePoints = _routeWaypoints.map((p) => ll.LatLng(p[0], p[1])).toList();

    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mapa de Ruta y Monitoreo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trip.isInTransit ? 'Seguimiento por OpenStreetMap' : 'Ruta proyectada en carretera',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEFF6FF),
                    foregroundColor: AppColors.accentBlue,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_Ui.radiusSmall)),
                  ),
                  icon: const Icon(Icons.near_me_rounded, size: 16),
                  label: const Text('Navegar GPS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  onPressed: () => _launchExternalMap(trip.destination),
                ),
              ],
            ),
          ),

          // Lienzo interactivo de OpenStreetMap
          SizedBox(
            height: 230,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: truckPos,
                    initialZoom: 11.0,
                    minZoom: 4.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.maquitrace',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: polylinePoints,
                          color: AppColors.accentBlue.withValues(alpha: 0.8),
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
                              color: AppColors.accentBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentBlue.withValues(alpha: 0.4),
                                  blurRadius: 8,
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
                                  color: _Ui.success.withValues(alpha: 0.35),
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

                // Controles de zoom y centrado
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Column(
                    children: [
                      _buildMapButton(
                        icon: Icons.my_location_rounded,
                        onTap: () => _mapController.move(truckPos, 13.0),
                        tooltip: 'Centrar en mi camión',
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

                // Créditos de OpenStreetMap
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
                      '© OpenStreetMap contributors',
                      style: TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Enlace directo a Google Maps / Waze
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: [
                const Icon(Icons.directions_outlined, size: 18, color: AppColors.accentBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Destino: ${trip.destination}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: AppColors.accentBlue,
                  ),
                  onPressed: () => _launchExternalMap(trip.destination),
                  child: const Text('Abrir en Google Maps', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
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
    final lastGps = trip.lastGps;
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

            // MAPA INTERACTIVO OPENSTREETMAP + BOTÓN DE NAVEGACIÓN
            _buildMapCard(trip),
            const SizedBox(height: 16),

            // Transmisión de GPS Automática y en Segundo Plano
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCardHeader(
                    title: 'Transmisión GPS',
                    subtitle: trip.isInTransit
                        ? 'Telemetría periódica cada 45s'
                        : 'Sincronización satelital con centro de control',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: trip.isInTransit ? _Ui.successBg : _Ui.lockedBg,
                        borderRadius: BorderRadius.circular(_Ui.radiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 8,
                            height: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: trip.isInTransit ? _Ui.success : _Ui.locked,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            trip.isInTransit ? 'Automático en vivo' : 'En espera',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: trip.isInTransit ? _Ui.success : _Ui.locked,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (lastGps != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _Ui.lockedBg,
                        borderRadius: BorderRadius.circular(_Ui.radius),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Última posición satelital transmitida',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Lat ${lastGps.latitude.toStringAsFixed(4)} · Lng ${lastGps.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_two(lastGps.recordedAt.hour)}:${_two(lastGps.recordedAt.minute)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (trip.isInTransit)
                    OutlinedButton.icon(
                      onPressed: _isSendingGps ? null : () => _transmitGpsLocation(provider),
                      icon: _isSendingGps
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location_rounded, size: 18),
                      label: Text(_isSendingGps ? 'Transmitiendo coordenada...' : 'Forzar actualización inmediata'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentBlue,
                        side: const BorderSide(color: _Ui.border),
                        minimumSize: const Size.fromHeight(46),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_Ui.radius)),
                      ),
                    ),
                ],
              ),
            ),
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