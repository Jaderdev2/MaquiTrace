import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../models/trip_model.dart';
import '../providers/transport_provider.dart';
import '../widgets/report_incident_modal.dart';

/// Colores y medidas propias de esta pantalla.
/// Un solo radio para tarjetas y botones, uno menor para chips y miniaturas,
/// bordes de 1 px, sin sombras, y color solo cuando comunica estado.
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

  // Coordenadas simuladas realistas si el dispositivo no tiene sensor satelital activo
  int _gpsStep = 0;
  final List<List<double>> _routeWaypoints = [
    [4.6097, -74.0817], // Bogotá
    [4.8143, -74.3541], // Facatativá
    [4.9754, -74.6219], // Villeta
    [5.2045, -74.7412], // Guaduas
    [5.4521, -74.6610], // Honda
  ];

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip;
  }

  TripModel _getUpdatedTrip(TransportProvider provider) {
    return provider.myTrips.firstWhere(
      (t) => t.id == _currentTrip.id,
      orElse: () => _currentTrip,
    );
  }

  Future<void> _transmitGpsLocation(TransportProvider provider) async {
    setState(() => _isSendingGps = true);

    final coords = _routeWaypoints[_gpsStep % _routeWaypoints.length];
    _gpsStep++;

    final success = await provider.updateGps(
      tripId: _currentTrip.id,
      latitude: coords[0],
      longitude: coords[1],
    );

    if (mounted) {
      setState(() => _isSendingGps = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _Ui.success,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Posición GPS transmitida: Lat ${coords[0]}, Lng ${coords[1]}',
            ),
          ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Iniciar ruta de transporte',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          '¿Confirmas la salida de la maquinaria hacia su destino? El estado cambiará a "En tránsito".',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_Ui.radius),
              ),
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
      }
    }
  }

  Future<void> _handleConfirmDelivery(TransportProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Confirmar entrega final',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          '¿Confirmas que el equipo ${_currentTrip.machine?.model ?? "la maquinaria"} fue entregado exitosamente en el destino:\n\n"${_currentTrip.destination}"?',
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _Ui.success,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_Ui.radius),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar entrega'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await provider.completeDelivery(machineId: _currentTrip.machineId);
      if (success && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  // ───────────────────────────── UI ─────────────────────────────

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
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  /// Título + subtítulo de tarjeta, con un widget opcional a la derecha.
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
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Acción principal del viaje, fija abajo para que siempre esté a mano.
  /// Si el servicio ya terminó no hay acción (el aviso va arriba, en el cuerpo).
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
        onPressed: () => _handleConfirmDelivery(provider),
        icon: const Icon(Icons.check_circle_outline_rounded, size: 22),
        label: const Text('Confirmar entrega en destino'),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_Ui.radius),
      ),
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
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded, color: _Ui.success, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Este servicio de transporte ya fue finalizado y entregado.',
                        style: TextStyle(
                          color: _Ui.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 1.35,
                        ),
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

            // Destino y datos de salida
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

            // Transmisión de GPS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCardHeader(
                    title: 'Transmisión GPS',
                    subtitle: 'Sincronización en tiempo real con la web',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _Ui.successBg,
                        borderRadius: BorderRadius.circular(_Ui.radiusSmall),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 8,
                            height: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: _Ui.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'En vivo',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _Ui.success,
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
                                  'Última posición',
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

                  OutlinedButton.icon(
                    onPressed: _isSendingGps ? null : () => _transmitGpsLocation(provider),
                    icon: _isSendingGps
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location_rounded, size: 18),
                    label: Text(_isSendingGps ? 'Transmitiendo coordenada...' : 'Transmitir coordenada GPS'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentBlue,
                      side: const BorderSide(color: _Ui.border),
                      minimumSize: const Size.fromHeight(48),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_Ui.radius),
                      ),
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