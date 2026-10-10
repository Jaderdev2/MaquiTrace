import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../auth/providers/auth_provider.dart';
import 'transport_history_screen.dart';
import '../../machines/screens/machines_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../qr_scanner/screens/qr_scanner_screen.dart';
import '../models/trip_model.dart';
import '../providers/transport_provider.dart';
import '../widgets/receive_machine_modal.dart';
import 'active_trip_screen.dart';

/// Colores y medidas compartidas con el resto de pantallas del flujo.
/// Un solo radio para tarjetas y botones, uno menor para chips y miniaturas,
/// bordes de 1 px, sin sombras y color solo cuando comunica estado.
class _Ui {
  static const background = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFEDF1F5);

  static const success = Color(0xFF15803D);
  static const successBg = Color(0xFFE8F5EC);
  static const infoBg = Color(0xFFE6EFFE);
  static const locked = Color(0xFF64748B);
  static const lockedBg = Color(0xFFF1F5F9);

  static const double radius = 10;
  static const double radiusSmall = 6;
  static const double pagePadding = 16;
}

class TransportHomeScreen extends StatefulWidget {
  const TransportHomeScreen({super.key});

  @override
  State<TransportHomeScreen> createState() => _TransportHomeScreenState();
}

class _TransportHomeScreenState extends State<TransportHomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentNavIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransportProvider>().loadDashboardData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  // ───────────────────────────── ESTRUCTURA DEL SHELL ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentNavIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentNavIndex != 0) {
          setState(() {
            _currentNavIndex = 0;
          });
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          extendBody: true,
          backgroundColor: _Ui.background,
          bottomNavigationBar: _buildBottomNav(),
          body: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return AppBottomNav(
      currentIndex: _currentNavIndex,
      onTap: (index) {
        setState(() {
          _currentNavIndex = index;
        });
      },
      onScanTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const QrScannerScreen(),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_currentNavIndex) {
      case 1:
        return const MachinesScreen(showScaffold: false);
      case 2:
        return const QrScannerScreen();
      case 3:
        return const TransportHistoryScreen(showScaffold: false);
      case 4:
        return ProfileScreen(
          showScaffold: false,
          onNavigateToTab: (index) {
            setState(() => _currentNavIndex = index);
          },
        );
      default:
        return _buildTransportHomeTab(context);
    }
  }

  // ───────────────────────────── PESTAÑA PRINCIPAL: INICIO DE TRANSPORTE ─────────────────────────────

  Widget _buildTransportHomeTab(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final transportProvider = context.watch<TransportProvider>();
    final user = authProvider.currentUser;

    final inTransitTrip = transportProvider.currentTripInTransit;

    final name = (user?.name.trim().isNotEmpty ?? false) ? user!.name.trim() : 'Transportador';
    final firstName = name.split(' ').first;
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => transportProvider.loadDashboardData(),
        color: AppColors.accentBlue,
        child: transportProvider.isLoading && transportProvider.myTrips.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accentBlue),
              )
            : CustomScrollView(
                slivers: [
                  // 1. Cabecera idéntica a la vista de operario con iniciales y rol
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _Ui.pagePadding,
                        16,
                        _Ui.pagePadding,
                        12,
                      ),
                      child: _buildHeader(firstName, initials),
                    ),
                  ),

                  // 2. Banner de Viaje en Marcha (si hay uno activo)
                  if (inTransitTrip != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          _Ui.pagePadding,
                          0,
                          _Ui.pagePadding,
                          12,
                        ),
                        child: _buildInTransitBanner(inTransitTrip),
                      ),
                    ),

                  // 3. Barra de pestañas operativas (Despachos, Por recibir, Entregados)
                  SliverToBoxAdapter(
                    child: Container(
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
                          _buildTab('Despachos', transportProvider.activeTrips.length),
                          _buildTab('Por recibir', transportProvider.readyMachines.length),
                          _buildTab('Entregados', transportProvider.deliveredTrips.length),
                        ],
                      ),
                    ),
                  ),

                  // 5. Contenido de las sub-pestañas
                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildActiveTripsSubTab(transportProvider),
                        _buildReadyMachinesSubTab(transportProvider),
                        _buildDeliveredTripsSubTab(transportProvider),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // --- Cabecera de usuario ---
  Widget _buildHeader(String firstName, String initials) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryNavy,
            borderRadius: BorderRadius.circular(_Ui.radiusSmall),
          ),
          alignment: Alignment.center,
          child: Text(
            initials.isNotEmpty ? initials : 'T',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $firstName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'Transportador',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Notificaciones',
          icon: const Icon(Icons.notifications_none_rounded, size: 24, color: AppColors.textPrimary),
          onPressed: () => _showNotificationsModal(context),
        ),
      ],
    );
  }

  // --- Banner de viaje en curso ---
  Widget _buildInTransitBanner(TripModel trip) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _Ui.infoBg,
        borderRadius: BorderRadius.circular(_Ui.radius),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentBlue,
              borderRadius: BorderRadius.circular(_Ui.radius),
            ),
            child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Viaje actualmente en marcha',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Hacia ${trip.destination}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_Ui.radius),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ActiveTripScreen(trip: trip),
                ),
              );
            },
            child: const Text('Ir a cabina'),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────── SUB-PESTAÑAS ─────────────────────────────

  Widget _buildTab(String label, int count) {
    return Tab(
      height: 48,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: _Ui.lockedBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _Ui.locked,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTripsSubTab(TransportProvider provider) {
    final trips = provider.activeTrips;

    if (trips.isEmpty) {
      return _buildEmptyState(
        icon: Icons.assignment_outlined,
        title: 'No tienes despachos activos',
        message: 'Ve a "Por recibir" para tomar una máquina alistada y asignarle tu vehículo.',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        _Ui.pagePadding,
        _Ui.pagePadding,
        _Ui.pagePadding,
        96 + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: trips.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final trip = trips[index];
        final machine = trip.machine;

        return Container(
          decoration: _cardDecoration(),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(_Ui.radius),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ActiveTripScreen(trip: trip)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildThumb(
                          child: machine != null
                              ? machine.buildImage(fit: BoxFit.cover)
                              : const Center(
                                  child: Icon(
                                    Icons.precision_manufacturing_rounded,
                                    color: _Ui.locked,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      machine?.model ?? 'Maquinaria',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildChip(
                                    trip.statusLabel,
                                    trip.statusColor,
                                    trip.statusBgColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Serial ${machine?.serial ?? "N/A"} · ${machine?.category ?? "General"}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              _buildLabelValue('Remolque', trip.vehicle),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: _Ui.divider),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            trip.destination,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReadyMachinesSubTab(TransportProvider provider) {
    final machines = provider.readyMachines;

    if (machines.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'No hay maquinaria por despachar',
        message: 'Cuando el taller termine las 3 fases de alistamiento, los equipos aparecerán aquí para recibirlos.',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        _Ui.pagePadding,
        _Ui.pagePadding,
        _Ui.pagePadding,
        96 + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: machines.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final m = machines[index];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildThumb(child: m.buildImage(fit: BoxFit.cover)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                m.model,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildChip('Alistada', _Ui.success, _Ui.successBg),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Serial ${m.serial} · ${m.category}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_Ui.radius),
                  ),
                ),
                icon: const Icon(Icons.move_to_inbox_outlined, size: 18),
                label: const Text('Recibir y asignar ruta'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ReceiveMachineModal(machine: m),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveredTripsSubTab(TransportProvider provider) {
    final trips = provider.deliveredTrips;

    if (trips.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_rounded,
        title: 'Aún no hay entregas',
        message: 'Los viajes finalizados y entregados en destino quedarán archivados aquí.',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        _Ui.pagePadding,
        _Ui.pagePadding,
        _Ui.pagePadding,
        96 + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: trips.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final trip = trips[index];
        final machine = trip.machine;
        final arrival = trip.arrivalAt;

        final deliveredText = arrival != null
            ? 'Entregado el ${_two(arrival.day)}/${_two(arrival.month)}/${arrival.year} a las ${_two(arrival.hour)}:${_two(arrival.minute)}'
            : 'Entregado en destino';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThumb(
                child: machine != null
                    ? machine.buildImage(fit: BoxFit.cover)
                    : const Center(
                        child: Icon(Icons.check_rounded, color: _Ui.success),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      machine?.model ?? 'Maquinaria',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Destino: ${trip.destination}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 14, color: _Ui.success),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            deliveredText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────────── UTILIDADES VISUALES ─────────────────────────────

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _Ui.surface,
      borderRadius: BorderRadius.circular(_Ui.radius),
      border: Border.all(color: _Ui.border),
    );
  }

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

  Widget _buildThumb({required Widget child}) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _Ui.lockedBg,
        borderRadius: BorderRadius.circular(_Ui.radiusSmall),
        border: Border.all(color: _Ui.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _buildLabelValue(String label, String value) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
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
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Notificaciones de Despacho',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Icon(Icons.check_circle_outline_rounded, size: 40, color: _Ui.success),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Todo en orden en carretera',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'No hay alertas viales ni cierres de ruta reportados en este momento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_Ui.radius)),
                    ),
                    child: const Text('Entendido'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}