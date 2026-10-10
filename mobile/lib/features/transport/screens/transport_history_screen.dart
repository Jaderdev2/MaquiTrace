import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../machines/screens/machine_detail_screen.dart';
import '../models/trip_model.dart';
import '../providers/transport_provider.dart';
import 'active_trip_screen.dart';

class _Ui {
  static const background = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFEDF1F5);

  static const warning = Color(0xFFB45309);
  static const warningBg = Color(0xFFFEF3C7);
  static const locked = Color(0xFF64748B);
  static const lockedBg = Color(0xFFF1F5F9);

  static const double radius = 10;
  static const double radiusSmall = 6;
  static const double pagePadding = 16;
}

class TransportHistoryScreen extends StatefulWidget {
  final bool showScaffold;

  const TransportHistoryScreen({
    super.key,
    this.showScaffold = true,
  });

  @override
  State<TransportHistoryScreen> createState() => _TransportHistoryScreenState();
}

class _TransportHistoryScreenState extends State<TransportHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _tabs = const [
    'Todos',
    'Entregados',
    'En ruta',
    'Con novedades',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransportProvider>().loadDashboardData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<TripModel> _filterTrips(List<TripModel> trips, int tabIndex) {
    var list = trips;

    // Filtro por pestaña
    switch (tabIndex) {
      case 1: // Entregados
        list = list.where((t) => t.isDelivered).toList();
        break;
      case 2: // En ruta / activos
        list = list.where((t) => t.isInTransit || t.isPending).toList();
        break;
      case 3: // Con novedades
        list = list.where((t) => t.incidents.isNotEmpty).toList();
        break;
      default: // Todos
        break;
    }

    // Filtro por búsqueda
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((t) {
        final machineModel = t.machine?.model.toLowerCase() ?? '';
        final machineSerial = t.machine?.serial.toLowerCase() ?? '';
        final vehicle = t.vehicle.toLowerCase();
        final destination = t.destination.toLowerCase();
        return machineModel.contains(q) ||
            machineSerial.contains(q) ||
            vehicle.contains(q) ||
            destination.contains(q);
      }).toList();
    }

    return list;
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Sin fecha';
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inDays == 0 && dt.day == now.day) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return 'Hoy $h:$m';
    }
    if (difference.inDays <= 1 && dt.day == now.day - 1) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return 'Ayer $h:$m';
    }
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final m = months[dt.month - 1];
    final hr = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $m, $hr:$min';
  }

  @override
  Widget build(BuildContext context) {
    final transportProvider = context.watch<TransportProvider>();
    final allTrips = transportProvider.myTrips;

    final deliveredCount = allTrips.where((t) => t.isDelivered).length;
    final activeCount = allTrips.where((t) => t.isInTransit || t.isPending).length;
    final incidentsCount = allTrips.where((t) => t.incidents.isNotEmpty).length;

    final content = SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Cabecera limpia
          Padding(
            padding: const EdgeInsets.fromLTRB(_Ui.pagePadding, 16, _Ui.pagePadding, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historial de Despachos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Registro histórico de maquinaria trasladada y entregada',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // 2. Buscador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _Ui.pagePadding),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: _Ui.surface,
                borderRadius: BorderRadius.circular(_Ui.radius),
                border: Border.all(color: _Ui.border),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim());
                },
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Buscar por máquina, serial, destino o placa...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Barra de pestañas con contadores numéricos
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.accentBlue,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.accentBlue,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: _Ui.border,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: [
                _buildTab('Todos', allTrips.length),
                _buildTab('Entregados', deliveredCount),
                _buildTab('En ruta', activeCount),
                _buildTab('Con novedades', incidentsCount),
              ],
            ),
          ),

          // 4. Listados filtrados
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_tabs.length, (index) {
                final filtered = _filterTrips(allTrips, index);
                return _buildTripListView(filtered, transportProvider);
              }),
            ),
          ),
        ],
      ),
    );

    if (!widget.showScaffold) {
      return content;
    }

    return Scaffold(
      backgroundColor: _Ui.background,
      body: content,
    );
  }

  Tab _buildTab(String label, int count) {
    return Tab(
      height: 46,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: _Ui.lockedBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripListView(List<TripModel> trips, TransportProvider provider) {
    if (provider.isLoading && trips.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentBlue),
      );
    }

    if (trips.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.loadDashboardData(),
        color: AppColors.accentBlue,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 60),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _Ui.lockedBg,
                  borderRadius: BorderRadius.circular(_Ui.radius),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  size: 32,
                  color: _Ui.locked,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay registros de transporte',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No se encontraron viajes que coincidan con "$_searchQuery".'
                  : 'Los despachos y servicios de traslado que realices quedarán guardados aquí.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadDashboardData(),
      color: AppColors.accentBlue,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(_Ui.pagePadding, 12, _Ui.pagePadding, 100),
        itemCount: trips.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final trip = trips[index];
          return _buildTripCard(trip);
        },
      ),
    );
  }

  Widget _buildTripCard(TripModel trip) {
    final machine = trip.machine;
    final dateStr = trip.isDelivered
        ? 'Entregado: ${_formatDate(trip.arrivalAt)}'
        : (trip.isInTransit
            ? 'Salida: ${_formatDate(trip.departureAt)}'
            : 'En espera de salida');

    return Container(
      decoration: BoxDecoration(
        color: _Ui.surface,
        borderRadius: BorderRadius.circular(_Ui.radius),
        border: Border.all(color: _Ui.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTripDetailModal(trip),
          borderRadius: BorderRadius.circular(_Ui.radius),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Miniatura del equipo
                ClipRRect(
                  borderRadius: BorderRadius.circular(_Ui.radiusSmall),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: _Ui.lockedBg,
                    child: machine != null
                        ? machine.buildImage(fit: BoxFit.cover)
                        : const Icon(Icons.precision_manufacturing_rounded, color: _Ui.locked, size: 24),
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Información del servicio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre y chip de estado
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              machine?.model ?? 'Maquinaria',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: trip.statusBgColor,
                              borderRadius: BorderRadius.circular(_Ui.radiusSmall),
                            ),
                            child: Text(
                              trip.statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: trip.statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Serial y vehículo de remolque
                      Text(
                        'Serial: ${machine?.serial ?? "N/A"} · ${trip.vehicle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Destino
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.accentBlue),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              trip.destination,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Pie: fecha e incidencias si las hubo
                      Row(
                        children: [
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          if (trip.incidents.isNotEmpty) ...[
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: _Ui.warningBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.warning_amber_rounded, size: 12, color: _Ui.warning),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${trip.incidents.length} novedad${trip.incidents.length > 1 ? "es" : ""}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _Ui.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, size: 20, color: _Ui.locked),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Modal de detalle del servicio de transporte ---
  void _showTripDetailModal(TripModel trip) {
    final machine = trip.machine;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Encabezado
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 54,
                        height: 54,
                        color: _Ui.lockedBg,
                        child: machine != null
                            ? machine.buildImage(fit: BoxFit.cover)
                            : const Icon(Icons.local_shipping_rounded, color: _Ui.locked),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            machine?.model ?? 'Servicio de Despacho',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Serial: ${machine?.serial ?? "N/A"} · ${machine?.category ?? ""}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: trip.statusBgColor,
                              borderRadius: BorderRadius.circular(_Ui.radiusSmall),
                            ),
                            child: Text(
                              trip.statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: trip.statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: _Ui.divider),

                // Datos de logística
                _buildModalRow('Destino / Obra', trip.destination),
                const Divider(height: 1, color: _Ui.divider),
                _buildModalRow('Vehículo / Remolque', trip.vehicle),
                const Divider(height: 1, color: _Ui.divider),
                _buildModalRow('Salida en carretera', _formatDate(trip.departureAt)),
                const Divider(height: 1, color: _Ui.divider),
                _buildModalRow(
                  'Entrega en sitio',
                  trip.isDelivered ? _formatDate(trip.arrivalAt) : 'Pendiente de entrega',
                ),
                const Divider(height: 1, color: _Ui.divider),
                _buildModalRow(
                  'Última posición GPS',
                  trip.lastGps != null
                      ? '${trip.lastGps!.latitude.toStringAsFixed(4)}, ${trip.lastGps!.longitude.toStringAsFixed(4)} (${_formatDate(trip.lastGps!.recordedAt)})'
                      : 'Sin coordenadas registradas',
                ),
                const Divider(height: 1, color: _Ui.divider),

                // Sección de novedades si las tiene
                if (trip.incidents.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 18, color: _Ui.warning),
                      const SizedBox(width: 6),
                      Text(
                        'Novedades Reportadas (${trip.incidents.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...trip.incidents.map((inc) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _Ui.warningBg,
                        borderRadius: BorderRadius.circular(_Ui.radiusSmall),
                        border: Border.all(color: _Ui.warning.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inc.description,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(inc.reportedAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (inc.photoUrl != null) ...[
                            const SizedBox(width: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                inc.photoUrl!,
                                width: 40,
                                height: 40,
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

                const SizedBox(height: 20),

                // Botones de acción
                if (trip.isInTransit || trip.isPending) ...[
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_Ui.radius),
                        ),
                      ),
                      icon: const Icon(Icons.speed, size: 20),
                      label: const Text(
                        'Abrir Cabina de Control de Ruta',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ActiveTripScreen(trip: trip),
                          ),
                        );
                      },
                    ),
                  ),
                ] else if (machine != null) ...[
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryNavy,
                        side: const BorderSide(color: _Ui.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_Ui.radius),
                        ),
                      ),
                      icon: const Icon(Icons.info_outline_rounded, size: 20),
                      label: const Text(
                        'Ver Ficha Técnica de la Máquina',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MachineDetailScreen(machine: machine),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
