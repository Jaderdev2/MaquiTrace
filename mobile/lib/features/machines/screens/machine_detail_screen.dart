import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../preparation/models/preparation_phase_model.dart';
import '../../preparation/services/preparation_service.dart';
import '../../preparation/widgets/phase_action_modal.dart';
import '../../qr_scanner/widgets/qr_display_modal.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../models/machine_model.dart';

/// Colores y medidas propias de esta pantalla.
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

class MachineDetailScreen extends StatefulWidget {
  final MachineModel machine;

  const MachineDetailScreen({
    super.key,
    required this.machine,
  });

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  final PreparationService _prepService = PreparationService();
  List<PreparationPhaseModel> _phases = [];
  bool _isLoadingPhases = true;

  @override
  void initState() {
    super.initState();
    _loadPhases();
  }

  Future<void> _loadPhases() async {
    setState(() => _isLoadingPhases = true);
    try {
      final list = await _prepService.getPhases(widget.machine.id);
      if (mounted) {
        setState(() {
          _phases = list;
          _isLoadingPhases = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPhases = false);
    }
  }

  // Estado general en tiempo real según las fases
  OverallState _effectiveState(MachineModel m) {
    if (_phases.isEmpty) return m.overallState;
    if (_phases.every((p) => p.isCompleted)) return OverallState.completed;
    if (_phases.any((p) => p.isInProgress || p.isCompleted)) {
      return OverallState.inProgress;
    }
    return OverallState.pending;
  }

  ({String label, Color fg, Color bg}) _statusStyle(OverallState state) {
    switch (state) {
      case OverallState.pending:
        return (label: 'Pendiente de inicio', fg: _Ui.warning, bg: _Ui.warningBg);
      case OverallState.inProgress:
        return (label: 'En alistamiento', fg: _Ui.info, bg: _Ui.infoBg);
      case OverallState.completed:
        return (label: 'Lista para despacho', fg: _Ui.success, bg: _Ui.successBg);
      case OverallState.inTransit:
        return (label: 'En tránsito a obra', fg: _Ui.info, bg: _Ui.infoBg);
      case OverallState.delivered:
        return (label: 'Entregada en sitio', fg: _Ui.success, bg: _Ui.successBg);
    }
  }

  // Fases ordenadas: ensamblaje → lavado → pintura
  List<PreparationPhaseModel> _orderedPhases(MachineModel machine) {
    final phases = List<PreparationPhaseModel>.from(_phases);
    phases.sort((a, b) => a.stepNumber.compareTo(b.stepNumber));

    // Si aún no hay fases cargadas, armar plantilla por defecto
    if (phases.isEmpty) {
      phases.addAll([
        PreparationPhaseModel(id: '1', machineId: machine.id, name: 'ensamblaje', status: 'completada'),
        PreparationPhaseModel(id: '2', machineId: machine.id, name: 'lavado', status: 'en_proceso'),
        PreparationPhaseModel(id: '3', machineId: machine.id, name: 'pintura', status: 'pendiente'),
      ]);
    }
    return phases;
  }

  // Regla de negocio: una fase queda bloqueada mientras la anterior
  // no esté completada. La primera nunca se bloquea.
  bool _isLocked(List<PreparationPhaseModel> phases, int index) {
    return index > 0 && !phases[index - 1].isCompleted;
  }

  IconData _phaseIcon(PreparationPhaseModel phase) {
    final n = phase.name.toLowerCase();
    if (n.contains('lav')) return Icons.water_drop_rounded;
    if (n.contains('ensam')) return Icons.build_rounded;
    if (n.contains('pint')) return Icons.format_paint_rounded;
    return Icons.settings_rounded;
  }

  ({String label, Color fg, Color bg}) _phaseStatus(
    PreparationPhaseModel phase,
    bool isLocked,
  ) {
    if (isLocked) return (label: 'Bloqueada', fg: _Ui.locked, bg: _Ui.lockedBg);
    if (phase.isCompleted) return (label: 'Completada', fg: _Ui.success, bg: _Ui.successBg);
    if (phase.isInProgress) return (label: 'En proceso', fg: _Ui.info, bg: _Ui.infoBg);
    return (label: 'Pendiente', fg: _Ui.warning, bg: _Ui.warningBg);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.machine;
    final status = _statusStyle(_effectiveState(m));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _Ui.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTopBar(context, m),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    _Ui.pagePadding,
                    16,
                    _Ui.pagePadding,
                    24 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSummaryCard(m, status),
                      const SizedBox(height: 16),
                      _buildProcessCard(m),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Barra superior ---
  Widget _buildTopBar(BuildContext context, MachineModel machine) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: _Ui.surface,
        border: Border(bottom: BorderSide(color: _Ui.border)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Volver',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          ),
          const Expanded(
            child: Text(
              'Detalle de máquina',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Ver código QR',
            onPressed: () => _showMachineQrModal(context, machine),
            icon: const Icon(Icons.qr_code_2_rounded, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  // --- Resumen de la máquina (con foto) ---
  Widget _buildSummaryCard(
    MachineModel machine,
    ({String label, Color fg, Color bg}) status,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _Ui.surface,
        borderRadius: BorderRadius.circular(_Ui.radius),
        border: Border.all(color: _Ui.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 150,
            child: Image.asset(
              machine.displayImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: _Ui.lockedBg,
                  child: const Center(
                    child: Icon(
                      Icons.precision_manufacturing_rounded,
                      size: 56,
                      color: _Ui.locked,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  machine.category,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  machine.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildChip(status.label, status.fg, status.bg, large: true),
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => _copySerial(machine.serial),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Serial ${machine.serial}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.copy_rounded, size: 16, color: _Ui.locked),
                          ],
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
  }

  void _copySerial(String serial) {
    Clipboard.setData(ClipboardData(text: serial));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Serial copiado'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  Widget _buildChip(
    String label,
    Color fg,
    Color bg, {
    bool large = false,
  }) {
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
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  // --- Alistamiento: línea de tiempo con todas las fases ---
  Widget _buildProcessCard(MachineModel machine) {
    if (_isLoadingPhases) {
      return const SkeletonGroup(
        child: MachineDetailProcessSkeleton(),
      );
    }

    final phases = _orderedPhases(machine);
    final completedCount = phases.where((p) => p.isCompleted).length;
    final total = phases.length;
    final isAllDone = completedCount == total && total > 0;

    return Container(
      decoration: BoxDecoration(
        color: _Ui.surface,
        borderRadius: BorderRadius.circular(_Ui.radius),
        border: Border.all(color: _Ui.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Alistamiento',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '$completedCount de $total fases',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isAllDone ? _Ui.success : _Ui.info,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 22, color: AppColors.textSecondary),
                  tooltip: 'Actualizar fases',
                  onPressed: _loadPhases,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _Ui.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Column(
              children: List.generate(phases.length, (i) {
                return _buildTimelineRow(
                  phases: phases,
                  index: i,
                  isLast: i == phases.length - 1,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(PreparationPhaseModel phase, bool locked) {
    const double size = 40;
    if (locked) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _Ui.lockedBg,
          shape: BoxShape.circle,
          border: Border.all(color: _Ui.border, width: 2),
        ),
        child: const Icon(Icons.lock_outline_rounded, size: 18, color: _Ui.locked),
      );
    }
    if (phase.isCompleted) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: _Ui.success, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, size: 24, color: Colors.white),
      );
    }
    if (phase.isInProgress) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _Ui.info,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _Ui.info.withValues(alpha: 0.2),
              spreadRadius: 4,
              blurRadius: 0,
            ),
          ],
        ),
        child: Icon(_phaseIcon(phase), size: 20, color: Colors.white),
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
      child: Icon(_phaseIcon(phase), size: 20, color: _Ui.warning),
    );
  }

  Widget _buildTimelineRow({
    required List<PreparationPhaseModel> phases,
    required int index,
    required bool isLast,
  }) {
    final phase = phases[index];
    final isLocked = _isLocked(phases, index);
    final prerequisite = isLocked ? phases[index - 1] : null;
    final st = _phaseStatus(phase, isLocked);
    final hasObservations = phase.observations != null && phase.observations!.isNotEmpty;
    final isActionable = !isLocked && !phase.isCompleted;

    void open() {
      if (isLocked) {
        _showLockedPhaseDialog(context, phase, prerequisite!);
      } else {
        PhaseActionModal.show(
          context: context,
          machineId: widget.machine.id,
          phase: phase,
          onPhaseUpdated: _loadPhases,
        );
      }
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Riel: nodo + línea que baja a la siguiente fase
          SizedBox(
            width: 44,
            child: Column(
              children: [
                const SizedBox(height: 2),
                _buildNode(phase, isLocked),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: phase.isCompleted ? _Ui.success : _Ui.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Contenido de la fase, sin caja
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: open,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              phase.displayName,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: isLocked ? _Ui.locked : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildChip(st.label, st.fg, st.bg),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phase.description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isLocked ? _Ui.locked : AppColors.textSecondary,
                    ),
                  ),
                  if (isLocked) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Se habilita al completar "${prerequisite?.displayName ?? 'la fase anterior'}".',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _Ui.locked,
                      ),
                    ),
                  ] else ...[
                    if (hasObservations) ...[
                      const SizedBox(height: 10),
                      Text(
                        phase.observations!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            phase.operatorName != null
                                ? 'Operario: ${phase.operatorName}'
                                : 'Sin operario asignado',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (isActionable)
                      SizedBox(
                        height: 44,
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: open,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryNavy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(_Ui.radius),
                            ),
                            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          child: Text(phase.isInProgress ? 'Continuar fase' : 'Iniciar fase'),
                        ),
                      )
                    else
                      InkWell(
                        onTap: open,
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Ver detalle',
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
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLockedPhaseDialog(
    BuildContext context,
    PreparationPhaseModel phase,
    PreparationPhaseModel prerequisite,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Fase bloqueada',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'No se puede iniciar ni registrar avances en "${phase.displayName}" '
          'hasta completar la fase ${prerequisite.stepNumber}: ${prerequisite.displayName}.',
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_Ui.radius),
              ),
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // --- Modal con el código QR de la máquina ---
  void _showMachineQrModal(BuildContext context, MachineModel machine) {
    QrDisplayModal.show(context, machine);
  }
}