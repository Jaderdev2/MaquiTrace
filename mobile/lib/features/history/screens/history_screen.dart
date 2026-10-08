import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../machines/models/machine_model.dart';
import '../../machines/services/machines_service.dart';
import '../../machines/screens/machine_detail_screen.dart';

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

class HistoryScreen extends StatefulWidget {
  final bool showScaffold;

  const HistoryScreen({super.key, this.showScaffold = true});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final MachinesService _machinesService = MachinesService();
  late final PageController _pageController;
  late final ScrollController _tabScrollController;
  late final AnimationController _skeletonController;
  late final Animation<double> _skeletonAnimation;

  int _selectedTabIndex = 0;
  bool _isLoading = true;
  List<MachineModel> _apiMachines = [];

  final List<String> _tabs = const [
    'Todos',
    'En alistamiento',
    'Completados',
    'Pendientes',
  ];

  late final List<GlobalKey> _tabKeys;

  @override
  void initState() {
    super.initState();
    _tabKeys = List.generate(_tabs.length, (_) => GlobalKey());
    _pageController = PageController(initialPage: 0);
    _tabScrollController = ScrollController();
    _skeletonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _skeletonAnimation = Tween<double>(begin: 0.45, end: 0.9).animate(
      CurvedAnimation(parent: _skeletonController, curve: Curves.easeInOut),
    );
    _initHistory();
  }

  Timer? _retryTimer;

  @override
  void dispose() {
    _retryTimer?.cancel();
    _skeletonController.dispose();
    _pageController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  Future<void> _initHistory() async {
    final cached = await _machinesService.getCachedMachines();
    if (cached.isNotEmpty && mounted) {
      setState(() {
        _apiMachines = cached;
        _isLoading = false;
      });
    }
    await _loadFromBackend();
  }

  Future<void> _loadFromBackend({bool isAutoRetry = false}) async {
    if (_apiMachines.isEmpty && !isAutoRetry) {
      setState(() => _isLoading = true);
    }
    try {
      final backendList = await _machinesService.search();
      if (backendList.isNotEmpty && mounted) {
        setState(() {
          _apiMachines = backendList;
          _isLoading = false;
        });
      }
      if (_machinesService.isLastFetchLive) {
        _retryTimer?.cancel();
        _retryTimer = null;
      } else {
        _scheduleAutoRetry();
      }
    } catch (_) {
      _scheduleAutoRetry();
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  void _scheduleAutoRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) _loadFromBackend(isAutoRetry: true);
    });
  }

  List<MachineModel> get _allMachines => _apiMachines;

  List<MachineModel> _getMachinesForTab(String tab) {
    switch (tab) {
      case 'En alistamiento':
        return _allMachines
            .where((m) => m.overallState == OverallState.inProgress)
            .toList();
      case 'Completados':
        return _allMachines
            .where((m) =>
                m.overallState == OverallState.completed ||
                m.overallState == OverallState.delivered)
            .toList();
      case 'Pendientes':
        return _allMachines
            .where((m) => m.overallState == OverallState.pending)
            .toList();
      case 'Todos':
      default:
        return _allMachines;
    }
  }

  void _onTabSelected(int index) {
    setState(() => _selectedTabIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _scrollToTab(index);
  }

  void _scrollToTab(int index) {
    final ctx = _tabKeys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
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

  int _completedPhases(MachineModel m) =>
      m.phases.where((p) => p == PhaseState.completed).length;

  int _totalPhases(MachineModel m) => m.phases.isNotEmpty ? m.phases.length : 3;

  PhaseState _phaseAt(MachineModel m, int i) =>
      i < m.phases.length ? m.phases[i] : PhaseState.pending;

  bool _isPhaseLocked(MachineModel m, int i) {
    if (i == 0) return false;
    return _phaseAt(m, i - 1) != PhaseState.completed &&
        _phaseAt(m, i) == PhaseState.pending;
  }

  IconData _phaseIcon(int i) {
    const icons = [
      Icons.build_rounded,
      Icons.water_drop_rounded,
      Icons.format_paint_rounded,
    ];
    return i < icons.length ? icons[i] : Icons.settings_rounded;
  }

  String _phaseName(int i) {
    const names = ['Ensamblaje', 'Lavado', 'Pintura'];
    return i < names.length ? names[i] : 'Fase ${i + 1}';
  }

  Widget _buildChip(String label, Color fg, Color bg, {bool large = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 8, vertical: large ? 6 : 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(large ? 8 : 6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: large ? 13 : 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildThumbnail(MachineModel m, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          m.displayImage,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: _Ui.lockedBg,
            child: const Icon(
              Icons.precision_manufacturing_rounded,
              color: _Ui.locked,
            ),
          ),
        ),
      ),
    );
  }

  // Mismo indicador circular que usan el detalle y el home.
  Widget _buildNode(PhaseState st, bool locked, int index, double size) {
    final iconSize = size * 0.5;
    if (locked) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _Ui.lockedBg,
          shape: BoxShape.circle,
          border: Border.all(color: _Ui.border, width: 2),
        ),
        child: Icon(Icons.lock_outline_rounded, size: iconSize, color: _Ui.locked),
      );
    }
    if (st == PhaseState.completed) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: _Ui.success, shape: BoxShape.circle),
        child: Icon(Icons.check_rounded, size: iconSize + 4, color: Colors.white),
      );
    }
    if (st == PhaseState.inProgress) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: _Ui.info, shape: BoxShape.circle),
        child: Icon(_phaseIcon(index), size: iconSize, color: Colors.white),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _Ui.surface,
        shape: BoxShape.circle,
        border: Border.all(color: _Ui.warning, width: 2),
      ),
      child: Icon(_phaseIcon(index), size: iconSize, color: _Ui.warning),
    );
  }

  // ---------- Pantalla ----------

  @override
  Widget build(BuildContext context) {
    final bodyContent = SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          _buildTabsRow(),
          const SizedBox(height: 12),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _tabs.length,
              onPageChanged: (index) {
                setState(() => _selectedTabIndex = index);
                _scrollToTab(index);
              },
              itemBuilder: (context, tabIndex) {
                final tab = _tabs[tabIndex];
                final list = _getMachinesForTab(tab);

                return RefreshIndicator(
                  onRefresh: _loadFromBackend,
                  color: AppColors.primaryNavy,
                  child: _isLoading
                      ? _buildSkeletonList()
                      : list.isEmpty
                          ? _buildEmptyState(tab)
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 110),
                              itemCount: list.length,
                              separatorBuilder: (_, _) => const ColoredBox(
                                color: _Ui.surface,
                                child: Divider(height: 1, indent: 88, color: _Ui.divider),
                              ),
                              itemBuilder: (context, index) =>
                                  _buildHistoryRow(list[index]),
                            ),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (!widget.showScaffold) {
      return bodyContent;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _Ui.background,
        body: bodyContent,
      ),
    );
  }

  // --- Cabecera ---
  Widget _buildHeader(BuildContext context) {
    final showBack = Navigator.of(context).canPop() && widget.showScaffold;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_Ui.pagePadding, 18, _Ui.pagePadding, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historial',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Trazabilidad de alistamientos · Sede Buenaventura',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (showBack)
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _Ui.border),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- Pestañas en píldora con conteo ---
  Widget _buildTabsRow() {
    return SizedBox(
      height: 38,
      child: SingleChildScrollView(
        controller: _tabScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _Ui.pagePadding),
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final tab = _tabs[index];
            final isSelected = index == _selectedTabIndex;
            final count = _getMachinesForTab(tab).length;

            return Padding(
              padding: EdgeInsets.only(right: index == _tabs.length - 1 ? 0 : 8),
              child: GestureDetector(
                key: _tabKeys[index],
                onTap: () => _onTabSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accentBlue : Colors.white,
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(
                      color: isSelected ? AppColors.accentBlue : _Ui.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tab,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : _Ui.lockedBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // --- Fila del historial ---
  Widget _buildHistoryRow(MachineModel m) {
    final st = _stateStyle(m);
    final total = _totalPhases(m);
    final done = _completedPhases(m);

    return Material(
      color: _Ui.surface,
      child: InkWell(
        onTap: () => _showHistoryDetailModal(context, m),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _Ui.pagePadding, vertical: 12),
          child: Row(
            children: [
              _buildThumbnail(m, 60),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
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
                      '${m.category} · Serial ${m.serial}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildChip(st.label, st.fg, st.bg),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...List.generate(total, (i) {
                              final p = _phaseAt(m, i);
                              final color = p == PhaseState.completed
                                  ? _Ui.success
                                  : p == PhaseState.inProgress
                                      ? _Ui.info
                                      : _Ui.border;
                              return Container(
                                width: 20,
                                height: 4,
                                margin: const EdgeInsets.only(right: 3),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            }),
                            const SizedBox(width: 5),
                            Text(
                              '$done de $total',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 22, color: _Ui.locked),
            ],
          ),
        ),
      ),
    );
  }

  // --- Ficha de la máquina ---
  void _showHistoryDetailModal(BuildContext context, MachineModel m) {
    final total = _totalPhases(m);
    final done = _completedPhases(m);
    final st = _stateStyle(m);

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

                // Encabezado
                Row(
                  children: [
                    _buildThumbnail(m, 56),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${m.category} · Serial ${m.serial}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildChip(st.label, st.fg, st.bg, large: true),
                ),
                const SizedBox(height: 8),

                // Datos de la máquina
                const Divider(height: 1, color: _Ui.divider),
                _buildMetricRow('Sede operativa', m.location.split('·').first.trim()),
                const Divider(height: 1, color: _Ui.divider),
                _buildMetricRow('Horas de operación', m.operatingHours),
                const Divider(height: 1, color: _Ui.divider),
                _buildMetricRow('Nivel de combustible', '${m.fuelPercent}%'),
                const Divider(height: 1, color: _Ui.divider),
                _buildMetricRow('Operario asignado', m.assignedOperator),
                const Divider(height: 1, color: _Ui.divider),
                const SizedBox(height: 20),

                // Fases
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Fases',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '$done de $total completadas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: done == total ? _Ui.success : _Ui.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildPhaseTimeline(m, total),
                const SizedBox(height: 22),

                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => MachineDetailScreen(machine: m),
                            ),
                          )
                          .then((_) => _loadFromBackend());
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_Ui.radius),
                      ),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Ver ficha técnica y fases'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhaseTimeline(MachineModel m, int total) {
    const double node = 32;
    final rows = <Widget>[];

    for (var i = 0; i < total; i++) {
      final st = _phaseAt(m, i);
      final locked = _isPhaseLocked(m, i);
      final isLast = i == total - 1;

      final String label;
      final Color fg;
      final Color bg;
      if (locked) {
        label = 'Bloqueada';
        fg = _Ui.locked;
        bg = _Ui.lockedBg;
      } else if (st == PhaseState.completed) {
        label = 'Completada';
        fg = _Ui.success;
        bg = _Ui.successBg;
      } else if (st == PhaseState.inProgress) {
        label = 'En proceso';
        fg = _Ui.info;
        bg = _Ui.infoBg;
      } else {
        label = 'Pendiente';
        fg = _Ui.warning;
        bg = _Ui.warningBg;
      }

      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: node,
                child: Column(
                  children: [
                    _buildNode(st, locked, i, node),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 3,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: st == PhaseState.completed ? _Ui.success : _Ui.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                  child: SizedBox(
                    height: node,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _phaseName(i),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: locked ? _Ui.locked : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        _buildChip(label, fg, bg),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildMetricRow(String label, String value) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String tab) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
          child: Column(
            children: [
              const Icon(Icons.inbox_outlined, size: 40, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'Sin registros en "$tab"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'No hay maquinaria con este estado en el patio.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Skeleton con la misma forma que las filas ---
  Widget _buildSkeletonList() {
    return AnimatedBuilder(
      animation: _skeletonAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _skeletonAnimation.value,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 110),
            itemCount: 5,
            separatorBuilder: (_, _) => const ColoredBox(
              color: _Ui.surface,
              child: Divider(height: 1, indent: 88, color: _Ui.divider),
            ),
            itemBuilder: (_, _) => _buildSkeletonRow(),
          ),
        );
      },
    );
  }

  Widget _skeletonBar(double width, double height, {Color color = _Ui.border}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildSkeletonRow() {
    return Container(
      color: _Ui.surface,
      padding: const EdgeInsets.symmetric(horizontal: _Ui.pagePadding, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _Ui.lockedBg,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonBar(130, 14),
                const SizedBox(height: 8),
                _skeletonBar(170, 12, color: _Ui.lockedBg),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _skeletonBar(90, 20, color: _Ui.lockedBg),
                    const SizedBox(width: 10),
                    _skeletonBar(64, 8, color: _Ui.lockedBg),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}