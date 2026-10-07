import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../preparation/models/preparation_phase_model.dart';
import '../../preparation/services/preparation_service.dart';
import '../../preparation/widgets/phase_action_modal.dart';
import '../../qr_scanner/widgets/qr_display_modal.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../models/machine_model.dart';
import '../../evidence/screens/evidence_checklist_screen.dart';
import '../../evidence/providers/evidence_provider.dart';
import '../../evidence/widgets/fullscreen_image_viewer.dart';

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
  static const warning = Color(0xFFB45309);
  static const warningBg = Color(0xFFFEF3C7);
  static const info = Color(0xFF1D4ED8);
  static const infoBg = Color(0xFFE6EFFE);
  static const locked = Color(0xFF64748B);
  static const lockedBg = Color(0xFFF1F5F9);

  static const double radius = 10;
  static const double radiusSmall = 6;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EvidenceProvider>().fetchEvidences(widget.machine.id);
      }
    });
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

  // Estado general en tiempo real según fases y evidencias obligatorias
  ({String label, Color fg, Color bg, bool isPhotosPending, int completedAngles}) _effectiveStatus(
    BuildContext context,
    MachineModel m,
  ) {
    if (m.overallState == OverallState.inTransit) {
      return (
        label: 'En tránsito a obra',
        fg: _Ui.info,
        bg: _Ui.infoBg,
        isPhotosPending: false,
        completedAngles: 4,
      );
    }
    if (m.overallState == OverallState.delivered) {
      return (
        label: 'Entregada en sitio',
        fg: _Ui.success,
        bg: _Ui.successBg,
        isPhotosPending: false,
        completedAngles: 4,
      );
    }

    final allPhasesCompleted = _phases.isNotEmpty && _phases.every((p) => p.isCompleted);
    final anyPhaseStarted = _phases.any((p) => p.isInProgress || p.isCompleted);

    // Conteo de los 4 ángulos obligatorios
    final evidenceProvider = context.watch<EvidenceProvider>();
    final evidences = evidenceProvider.getEvidencesForMachine(m.id);
    const mandatoryKeys = ['frontal', 'lateral', 'cabina', 'serial'];
    final completedAngles = mandatoryKeys.where((key) {
      return evidences.any((e) {
        final lowerUrl = e.url.toLowerCase();
        final lowerObs = (e.observations ?? '').toLowerCase();
        return lowerUrl.contains(key) || lowerObs.contains(key);
      });
    }).length;
    final allAnglesCompleted = completedAngles >= mandatoryKeys.length;

    // Regla MaquiTrace: Solo está Lista para despacho si terminó fases Y tiene los 4 ángulos
    if (allPhasesCompleted && allAnglesCompleted) {
      return (
        label: 'Lista para despacho',
        fg: _Ui.success,
        bg: _Ui.successBg,
        isPhotosPending: false,
        completedAngles: completedAngles,
      );
    }

    // Fases mecánicas terminadas pero faltan fotos -> Pendiente de inspección fotográfica
    if (allPhasesCompleted && !allAnglesCompleted) {
      return (
        label: 'Pendiente inspección ($completedAngles/4 fotos)',
        fg: _Ui.warning,
        bg: _Ui.warningBg,
        isPhotosPending: true,
        completedAngles: completedAngles,
      );
    }

    if (anyPhaseStarted) {
      return (
        label: 'En alistamiento',
        fg: _Ui.info,
        bg: _Ui.infoBg,
        isPhotosPending: false,
        completedAngles: completedAngles,
      );
    }

    // Fallback inteligente según el estado global de la máquina si _phases aún no está cargada
    if (_phases.isEmpty) {
      if (m.overallState == OverallState.completed) {
        final isReady = m.isReadyForDispatch || allAnglesCompleted;
        return (
          label: isReady
              ? 'Lista para despacho'
              : 'Pendiente inspección ($completedAngles/4 fotos)',
          fg: isReady ? _Ui.success : _Ui.warning,
          bg: isReady ? _Ui.successBg : _Ui.warningBg,
          isPhotosPending: !isReady,
          completedAngles: completedAngles,
        );
      }
      if (m.overallState == OverallState.inProgress) {
        return (
          label: 'En alistamiento',
          fg: _Ui.info,
          bg: _Ui.infoBg,
          isPhotosPending: false,
          completedAngles: completedAngles,
        );
      }
    }

    return (
      label: 'Pendiente de inicio',
      fg: _Ui.warning,
      bg: _Ui.warningBg,
      isPhotosPending: false,
      completedAngles: completedAngles,
    );
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
    final status = _effectiveStatus(context, m);

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
                      _buildSummaryCard(context, m, status),
                      const SizedBox(height: 16),
                      _buildEvidenceButtonCard(context, m),
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

  Future<void> _openEvidenceChecklist(BuildContext context, MachineModel machine) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EvidenceChecklistScreen(
          machineId: machine.id,
          machineSerial: machine.serial,
          machineModel: machine.name,
        ),
      ),
    );
    if (context.mounted) {
      context.read<EvidenceProvider>().fetchEvidences(machine.id);
    }
  }

  // --- Tarjeta de checklist fotográfico ---
  Widget _buildEvidenceButtonCard(BuildContext context, MachineModel machine) {
    final evidenceProvider = context.watch<EvidenceProvider>();
    final evidences = evidenceProvider.getEvidencesForMachine(machine.id);
    final isLoading = (evidenceProvider.isLoading && evidences.isEmpty) || _isLoadingPhases;

    if (isLoading) {
      return const SkeletonGroup(
        child: MachineDetailEvidenceSkeleton(),
      );
    }

    // Conteo de ángulos obligatorios cubiertos
    const mandatoryKeys = ['frontal', 'lateral', 'cabina', 'serial'];
    final completedCount = mandatoryKeys.where((key) {
      return evidences.any((e) {
        final lowerUrl = e.url.toLowerCase();
        final lowerObs = (e.observations ?? '').toLowerCase();
        return lowerUrl.contains(key) || lowerObs.contains(key);
      });
    }).length;

    final isAllDone = completedCount >= mandatoryKeys.length;
    final progress = (completedCount / mandatoryKeys.length).clamp(0.0, 1.0);
    final missing = mandatoryKeys.length - completedCount;

    final Color stateFg = isAllDone
        ? _Ui.success
        : completedCount > 0
            ? _Ui.info
            : _Ui.locked;
    final Color stateBg = isAllDone
        ? _Ui.successBg
        : completedCount > 0
            ? _Ui.infoBg
            : _Ui.lockedBg;

    final String subtitle = isAllDone
        ? 'Los 4 ángulos obligatorios están capturados.'
        : completedCount > 0
            ? (missing == 1
                ? 'Falta 1 ángulo obligatorio por capturar.'
                : 'Faltan $missing ángulos obligatorios por capturar.')
            : 'Aún sin fotos. Registra los 4 ángulos obligatorios.';

    return Container(
      decoration: BoxDecoration(
        color: _Ui.surface,
        borderRadius: BorderRadius.circular(_Ui.radius),
        border: Border.all(color: _Ui.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openEvidenceChecklist(context, machine),
          borderRadius: BorderRadius.circular(_Ui.radius),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: stateBg,
                        borderRadius: BorderRadius.circular(_Ui.radius),
                      ),
                      child: Icon(
                        isAllDone ? Icons.verified_rounded : Icons.camera_alt_rounded,
                        color: stateFg,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Checklist y evidencias',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '$completedCount/${mandatoryKeys.length}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: stateFg,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Barra de progreso
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: _Ui.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isAllDone ? _Ui.success : _Ui.info,
                    ),
                  ),
                ),

                // Miniaturas si existen evidencias
                if (evidences.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 56,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: evidences.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final ev = evidences[index];
                        return InkWell(
                          onTap: () {
                            FullscreenImageViewer.openFromModel(context, ev);
                          },
                          borderRadius: BorderRadius.circular(_Ui.radiusSmall),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _Ui.lockedBg,
                              borderRadius: BorderRadius.circular(_Ui.radiusSmall),
                              border: Border.all(color: _Ui.border),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              ev.url,
                              fit: BoxFit.cover,
                              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                if (wasSynchronouslyLoaded) return child;
                                return AnimatedOpacity(
                                  opacity: frame == null ? 0 : 1,
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                  child: child,
                                );
                              },
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.8,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(
                                  Icons.image_not_supported_rounded,
                                  size: 20,
                                  color: _Ui.locked,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1, color: _Ui.divider),

                // Pie: contador de evidencias + llamada a la acción
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      Expanded(
                        child: evidences.isNotEmpty
                            ? Text(
                                evidences.length == 1
                                    ? '1 evidencia registrada'
                                    : '${evidences.length} evidencias registradas',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      Text(
                        isAllDone ? 'Gestionar' : 'Completar checklist',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentBlue,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.accentBlue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Resumen de la máquina (con foto) ---
  Widget _buildSummaryCard(
    BuildContext context,
    MachineModel machine,
    ({String label, Color fg, Color bg, bool isPhotosPending, int completedAngles}) status,
  ) {
    if (_isLoadingPhases) {
      return const SkeletonGroup(
        child: MachineDetailSummarySkeleton(),
      );
    }

    final heroTag = 'machine-photo-${machine.id}';

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
            height: 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: heroTag,
                  child: GestureDetector(
                    onTap: () => _openMachinePhotoViewer(context, machine, heroTag),
                    child: Image.asset(
                      machine.displayImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: _Ui.lockedBg,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.precision_manufacturing_rounded,
                                  size: 44,
                                  color: _Ui.locked,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Sin imagen disponible',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _Ui.locked,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Pista de "toca para ampliar"
                Positioned(
                  right: 10,
                  top: 10,
                  child: IgnorePointer(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fullscreen_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
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
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  machine.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(_Ui.radiusSmall),
                  onTap: () => _copySerial(machine.serial),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Serial  ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextSpan(
                                text: machine.serial,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.copy_rounded, size: 16, color: _Ui.locked),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildChip(status.label, status.fg, status.bg, large: true),
                if (status.isPhotosPending) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _Ui.warningBg,
                      borderRadius: BorderRadius.circular(_Ui.radius),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: _Ui.warning, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Alistamiento terminado. Registra los 4 ángulos obligatorios para autorizar el despacho (${status.completedAngles}/4 listos).',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _Ui.warning,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
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

  // --- Vista de pantalla completa de la foto principal de la máquina ---
  void _openMachinePhotoViewer(BuildContext context, MachineModel machine, String heroTag) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: Stack(
                  children: [
                    Center(
                      child: Hero(
                        tag: heroTag,
                        child: InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 4,
                          child: Image.asset(
                            machine.displayImage,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.precision_manufacturing_rounded,
                              size: 64,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 20,
                      right: 16,
                      child: Text(
                        '${machine.name} · ${machine.serial}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
          behavior: SnackBarBehavior.floating,
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
        borderRadius: BorderRadius.circular(_Ui.radiusSmall),
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
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '$completedCount de $total fases',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
          border: Border.all(color: _Ui.border, width: 1.5),
        ),
        child: const Icon(Icons.lock_outline_rounded, size: 18, color: _Ui.locked),
      );
    }
    if (phase.isCompleted) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: _Ui.success, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, size: 22, color: Colors.white),
      );
    }
    if (phase.isInProgress) {
      // Relleno sólido: se distingue de "pendiente" (aro) sin halos ni brillos
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: _Ui.info, shape: BoxShape.circle),
        child: Icon(_phaseIcon(phase), size: 20, color: Colors.white),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _Ui.surface,
        shape: BoxShape.circle,
        border: Border.all(color: _Ui.warning, width: 1.5),
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
          machineSerial: widget.machine.serial,
          phase: phase,
          onPhaseUpdated: () {
            _loadPhases();
            if (context.mounted) {
              context.read<EvidenceProvider>().fetchEvidences(widget.machine.id);
            }
          },
        );
      }
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Riel: nodo + línea que baja a la siguiente fase
          SizedBox(
            width: 40,
            child: Column(
              children: [
                const SizedBox(height: 2),
                _buildNode(phase, isLocked),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: phase.isCompleted ? _Ui.success : _Ui.border,
                        borderRadius: BorderRadius.circular(1),
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
                    borderRadius: BorderRadius.circular(_Ui.radiusSmall),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              phase.displayName,
                              style: TextStyle(
                                fontSize: 16,
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _Ui.lockedBg,
                          borderRadius: BorderRadius.circular(_Ui.radius),
                        ),
                        child: Text(
                          phase.observations!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.textPrimary,
                          ),
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
                            backgroundColor: AppColors.accentBlue,
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
                      TextButton(
                        onPressed: open,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accentBlue,
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.only(right: 8),
                          alignment: Alignment.centerLeft,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Ver detalle'),
                            Icon(Icons.chevron_right_rounded, size: 20),
                          ],
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
        surfaceTintColor: Colors.transparent,
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
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
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