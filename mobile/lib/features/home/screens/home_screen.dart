import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../auth/providers/auth_provider.dart';
import '../../history/screens/history_screen.dart';
import '../../machines/models/machine_model.dart';
import '../../machines/screens/machine_detail_screen.dart';
import '../../machines/screens/machines_screen.dart';
import '../../machines/services/machines_service.dart';
import '../../profile/screens/profile_screen.dart';
import '../../qr_scanner/screens/qr_scanner_screen.dart';
import '../../qr_scanner/widgets/manual_search_modal.dart';
import '../../../core/widgets/skeleton_loader.dart';

/// Colores y medidas compartidas con el resto de pantallas del flujo.
/// Un solo radio, bordes de 1 px y color solo cuando comunica estado.
class _Ui {
  static const background = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFEDF1F5);

  static const success = Color(0xFF15803D);
  static const successBg = Color(0xFFE8F5EC);
  static const warning = Color(0xFFB45309);
  static const warningBg = Color(0xFFFEF3C7);
  static const info = Color(0xFF1D4ED8);
  static const infoBg = Color(0xFFE6EFFE);
  static const locked = Color(0xFF64748B);
  static const lockedBg = Color(0xFFF1F5F9);

  static const double radius = 10;
  static const double pagePadding = 16;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  final MachinesService _machinesService = MachinesService();
  List<MachineModel> _dashboardMachines = [];
  bool _isLoadingDashboard = true;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _initDashboard() async {
    // 1. Mostrar de inmediato la caché de máquinas reales si existe en disco
    final cached = await _machinesService.getCachedMachines();
    if (cached.isNotEmpty && mounted) {
      setState(() {
        _dashboardMachines = cached;
        _isLoadingDashboard = false;
      });
    }
    // 2. Consultar al backend en vivo para sincronizar cambios
    await _loadDashboardMachines();
  }

  Future<void> _loadDashboardMachines({bool isAutoRetry = false}) async {
    if (_dashboardMachines.isEmpty && !isAutoRetry) {
      setState(() => _isLoadingDashboard = true);
    }
    try {
      final list = await _machinesService.search();
      if (list.isNotEmpty && mounted) {
        setState(() {
          _dashboardMachines = list;
          _isLoadingDashboard = false;
        });
      }
      // Si la respuesta provino en vivo del backend, cancelar reintentos
      if (_machinesService.isLastFetchLive) {
        _retryTimer?.cancel();
        _retryTimer = null;
      } else {
        // El servidor aún está en frío/despertando: programar reintento automático
        _scheduleAutoRetry();
      }
    } catch (_) {
      _scheduleAutoRetry();
    } finally {
      if (mounted && _isLoadingDashboard) {
        setState(() => _isLoadingDashboard = false);
      }
    }
  }

  void _scheduleAutoRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) {
        _loadDashboardMachines(isAutoRetry: true);
      }
    });
  }

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

  Widget _buildBody(BuildContext context) {
    switch (_currentNavIndex) {
      case 1:
        return const MachinesScreen(showScaffold: false);
      case 2:
        return const QrScannerScreen();
      case 3:
        return const HistoryScreen(showScaffold: false);
      case 4:
        return ProfileScreen(
          showScaffold: false,
          onNavigateToTab: (index) {
            setState(() => _currentNavIndex = index);
          },
        );
      default:
        return _buildHomeContent(context);
    }
  }

  // ---------- Helpers de estado ----------

  ({String label, Color fg, Color bg}) _stateStyle(MachineModel m) {
    switch (m.overallState) {
      case OverallState.pending:
        return (label: 'Pendiente de inicio', fg: _Ui.warning, bg: _Ui.warningBg);
      case OverallState.inProgress:
        return (label: 'En alistamiento', fg: _Ui.info, bg: _Ui.infoBg);
      case OverallState.completed:
        if (m.hasAllMandatoryAngles) {
          return (label: 'Lista para despacho', fg: _Ui.success, bg: _Ui.successBg);
        }
        return (
          label: m.completedAnglesCount > 0
              ? 'Pendiente fotos (${m.completedAnglesCount}/4)'
              : 'Pendiente inspección',
          fg: _Ui.warning,
          bg: _Ui.warningBg,
        );
      case OverallState.inTransit:
        return (label: 'En tránsito a obra', fg: _Ui.info, bg: _Ui.infoBg);
      case OverallState.delivered:
        return (label: 'Entregada en sitio', fg: _Ui.success, bg: _Ui.successBg);
    }
  }

  // Lo que requiere atención va primero: en alistamiento, pendientes, pendientes de fotos, listas.
  int _priority(MachineModel m) {
    switch (m.overallState) {
      case OverallState.inProgress:
        return 0;
      case OverallState.pending:
        return 1;
      case OverallState.completed:
        return m.hasAllMandatoryAngles ? 3 : 2;
      case OverallState.inTransit:
        return 4;
      case OverallState.delivered:
        return 5;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _openMachine(MachineModel machine) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => MachineDetailScreen(machine: machine),
          ),
        )
        .then((_) => _loadDashboardMachines());
  }

  // ---------- Contenido ----------

  Widget _buildHomeContent(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final displayName =
        (user?.name.trim().isNotEmpty ?? false) ? user!.name.trim() : 'Operario';
    final firstName = displayName.split(' ').first;
    final initials = displayName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final roleLabel = (user?.role.trim().isNotEmpty ?? false)
        ? _capitalize(user!.role.trim())
        : 'Operario de alistamiento';

    final machines = _dashboardMachines;

    MachineModel? activeMachine;
    for (final m in machines) {
      if (m.overallState == OverallState.inProgress) {
        activeMachine = m;
        break;
      }
    }

    final ordered = [
      for (var p = 0; p <= 5; p++)
        ...machines.where((m) => _priority(m) == p),
    ];

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _loadDashboardMachines,
        color: AppColors.accentBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            _Ui.pagePadding,
            16,
            _Ui.pagePadding,
            100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(firstName, initials, roleLabel),
              const SizedBox(height: 16),

              // 1. Búsqueda rápida por serial o código
              _buildQuickSearch(),
              const SizedBox(height: 18),

              // 2. Máquina en alistamiento (lo siguiente por atender)
              if (_isLoadingDashboard) ...[
                const SkeletonGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HomeActiveMachineSkeleton(),
                      SizedBox(height: 22),
                    ],
                  ),
                ),
              ] else if (activeMachine != null) ...[
                _buildActiveMachineCard(activeMachine),
                const SizedBox(height: 22),
              ],

              // 3. Mis alistamientos
              _buildSectionTitle(
                'Mis alistamientos',
                trailing: InkWell(
                  onTap: () => setState(() => _currentNavIndex = 1),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ver todos',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentBlue,
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.accentBlue),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoadingDashboard)
                const SkeletonGroup(
                  child: HomeMachineGroupedListSkeleton(itemCount: 3),
                )
              else
                _buildMachineList(ordered.take(4).toList()),
            ],
          ),
        ),
      ),
    );
  }

  // --- Encabezado ---
  Widget _buildHeader(String firstName, String initials, String roleLabel) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _currentNavIndex = 4),
            borderRadius: BorderRadius.circular(_Ui.radius),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryNavy,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials.isNotEmpty ? initials : 'OP',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        roleLabel,
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
        ),
        IconButton(
          tooltip: 'Notificaciones',
          onPressed: () => _showNotificationsModal(context),
          icon: const Icon(
            Icons.notifications_outlined,
            size: 26,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }

  Widget _buildChip(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _buildThumbnail(MachineModel machine, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: size,
        height: size,
        child: machine.buildImage(fit: BoxFit.cover),
      ),
    );
  }

  // --- Máquina en alistamiento (lo siguiente por hacer) ---
  Widget _buildActiveMachineCard(MachineModel machine) {
    return Material(
      color: _Ui.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_Ui.radius),
        side: const BorderSide(color: _Ui.border),
      ),
      child: InkWell(
        onTap: () => _openMachine(machine),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Continuar alistamiento',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _Ui.info,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildThumbnail(machine, 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          machine.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Serial ${machine.serial}',
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
              if (machine.phases.isNotEmpty) ...[
                const SizedBox(height: 18),
                _buildMiniStepper(machine.phases),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: () => _openMachine(machine),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_Ui.radius),
                    ),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Continuar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mismo recorrido que el detalle, en tamaño compacto.
  Widget _buildMiniStepper(List<PhaseState> phases) {
    const names = ['Ensamblaje', 'Lavado', 'Pintura'];
    const icons = [
      Icons.build_rounded,
      Icons.water_drop_rounded,
      Icons.format_paint_rounded,
    ];
    const double node = 34;

    bool isDone(PhaseState p) =>
        p != PhaseState.inProgress && p != PhaseState.pending;

    final children = <Widget>[];
    for (var i = 0; i < phases.length; i++) {
      final p = phases[i];
      final done = isDone(p);
      final locked = i > 0 && !isDone(phases[i - 1]);
      final icon = i < icons.length ? icons[i] : Icons.settings_rounded;
      final label = i < names.length ? names[i] : 'Fase ${i + 1}';

      Widget circle;
      if (locked) {
        circle = Container(
          width: node,
          height: node,
          decoration: BoxDecoration(
            color: _Ui.lockedBg,
            shape: BoxShape.circle,
            border: Border.all(color: _Ui.border, width: 2),
          ),
          child: const Icon(Icons.lock_outline_rounded, size: 16, color: _Ui.locked),
        );
      } else if (done) {
        circle = Container(
          width: node,
          height: node,
          decoration: const BoxDecoration(color: _Ui.success, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, size: 20, color: Colors.white),
        );
      } else if (p == PhaseState.inProgress) {
        circle = Container(
          width: node,
          height: node,
          decoration: const BoxDecoration(color: _Ui.info, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: Colors.white),
        );
      } else {
        circle = Container(
          width: node,
          height: node,
          decoration: BoxDecoration(
            color: _Ui.surface,
            shape: BoxShape.circle,
            border: Border.all(color: _Ui.warning, width: 2),
          ),
          child: Icon(icon, size: 18, color: _Ui.warning),
        );
      }

      children.add(
        SizedBox(
          width: 84,
          child: Column(
            children: [
              circle,
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: p == PhaseState.inProgress ? FontWeight.w700 : FontWeight.w600,
                  color: locked ? _Ui.locked : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );

      if (i < phases.length - 1) {
        children.add(
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: node / 2 - 1.5),
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: done ? _Ui.success : _Ui.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  // --- Búsqueda rápida por serial o código ---
  Widget _buildQuickSearch() {
    return Material(
      color: _Ui.surface,
      borderRadius: BorderRadius.circular(_Ui.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ManualSearchModal.show(context),
        borderRadius: BorderRadius.circular(_Ui.radius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_Ui.radius),
            border: Border.all(color: _Ui.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, size: 22, color: _Ui.locked),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Buscar máquina por serial o código...',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Icon(Icons.tune_rounded, size: 18, color: _Ui.locked),
            ],
          ),
        ),
      ),
    );
  }

  // --- Mis alistamientos: lista agrupada ---
  Widget _buildMachineList(List<MachineModel> machines) {
    return Material(
      color: _Ui.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_Ui.radius),
        side: const BorderSide(color: _Ui.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < machines.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _Ui.divider),
            _buildMachineRow(machines[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildMachineRow(MachineModel machine) {
    final st = _stateStyle(machine);
    return InkWell(
      onTap: () => _openMachine(machine),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildThumbnail(machine, 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    machine.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Serial ${machine.serial}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildChip(st.label, st.fg, st.bg),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 22, color: _Ui.locked),
          ],
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
                        'Notificaciones',
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
                  'Sin avisos pendientes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'No hay alertas técnicas para tu rol en este momento.',
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
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_Ui.radius),
                      ),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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