import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../preparation/models/preparation_phase_model.dart';
import '../../preparation/services/preparation_service.dart';
import '../../preparation/widgets/phase_action_modal.dart';
import '../../qr_scanner/widgets/qr_display_modal.dart';
import '../models/machine_model.dart';

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

  // Simulación de fotos tomadas por el operario
  final Map<int, bool> _photoUploaded = {
    0: true,  // Frontal
    1: true,  // Lateral
    2: true,  // Cabina
    3: false, // Motor (pendiente)
  };


  @override
  Widget build(BuildContext context) {
    final m = widget.machine;

    // Configuración de estado
    String statusLabel;
    Color statusColor;
    Color statusBg;
    Color statusBorder;

    switch (m.overallState) {
      case OverallState.inProgress:
        statusLabel = 'En alistamiento';
        statusColor = AppColors.accentBlue;
        statusBg = const Color(0xFFEFF6FF);
        statusBorder = const Color(0xFFDBEAFE);
        break;
      case OverallState.pending:
        statusLabel = 'Pendiente de inicio';
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFEF3C7);
        statusBorder = const Color(0xFFFDE68A);
        break;
      case OverallState.completed:
        statusLabel = 'Lista para despacho';
        statusColor = const Color(0xFF059669);
        statusBg = const Color(0xFFECFDF5);
        statusBorder = const Color(0xFFA7F3D0);
        break;
      case OverallState.inTransit:
        statusLabel = 'En tránsito a obra';
        statusColor = const Color(0xFF2563EB);
        statusBg = const Color(0xFFDBEAFE);
        statusBorder = const Color(0xFFBFDBFE);
        break;
      case OverallState.delivered:
        statusLabel = 'Entregada en sitio';
        statusColor = const Color(0xFF059669);
        statusBg = const Color(0xFFECFDF5);
        statusBorder = const Color(0xFFA7F3D0);
        break;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. Barra de navegación superior
              _buildTopBar(context, m),

              // 2. Contenido scrolleable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tarjeta Hero con datos principales de la máquina
                      _buildHeroCard(m, statusLabel, statusColor, statusBg, statusBorder),
                      const SizedBox(height: 18),

                      // Ficha técnica esencial (Métricas operativas)
                      _buildTechnicalSpecsGrid(m),
                      const SizedBox(height: 20),

                      // Progreso y avance de alistamiento
                      _buildPreparationProgressCard(),
                      const SizedBox(height: 16),

                      // Fases Secuenciales de Alistamiento
                      _buildSequentialPhasesSection(m),
                      const SizedBox(height: 22),


                      // Evidencias fotográficas requeridas
                      _buildEvidenceSection(),
                      const SizedBox(height: 22),

                      // Novedades y observaciones técnicas
                      _buildNotesSection(m),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. Barra de acciones inferior fija
        bottomNavigationBar: _buildStickyBottomBar(context, m),
      ),
    );
  }

  // --- Barra superior limpia ---
  Widget _buildTopBar(BuildContext context, MachineModel machine) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón volver
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Título central
          Column(
            children: [
              const Text(
                'Detalle de máquina',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Serial: ${machine.serial}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),

          // Botón ver código QR
          GestureDetector(
            onTap: () => _showMachineQrModal(context, machine),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Tarjeta Hero Principal ---
  Widget _buildHeroCard(
    MachineModel machine,
    String statusLabel,
    Color statusColor,
    Color statusBg,
    Color statusBorder,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Foto de la máquina con badge de categoría superpuesto
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Image.asset(
                    machine.displayImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFEFF6FF),
                        child: const Center(
                          child: Icon(
                            Icons.precision_manufacturing_rounded,
                            size: 48,
                            color: AppColors.accentBlue,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Píldora de Categoría
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xD90F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    machine.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Información descriptiva
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            machine.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Modelo ${machine.modelYear} · Serial: ${machine.serial}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge de Estado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusBorder),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Separador tenue
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Ubicación física en patio
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        machine.location,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
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

  // --- Ficha Técnica Esencial (Métricas Operativas) ---
  Widget _buildTechnicalSpecsGrid(MachineModel machine) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ficha técnica y operatividad',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSpecCard(
                icon: Icons.timer_outlined,
                label: 'Horómetro',
                value: machine.operatingHours,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSpecCard(
                icon: Icons.local_gas_station_outlined,
                label: 'Combustible',
                value: '${machine.fuelPercent}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSpecCard(
                icon: Icons.calendar_today_outlined,
                label: 'Año / Modelo',
                value: machine.modelYear,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSpecCard(
                icon: Icons.person_outline_rounded,
                label: 'Operario asignado',
                value: machine.assignedOperator,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: AppColors.primaryNavy),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Tarjeta de Progreso General de Alistamiento ---
  Widget _buildPreparationProgressCard() {
    final completedCount = _phases.where((p) => p.isCompleted).length;
    final total = _phases.isEmpty ? 3 : _phases.length;
    final progress = (completedCount / total).clamp(0.0, 1.0);
    final percentInt = (progress * 100).toInt();

    final isAllDone = completedCount == total && total > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isAllDone ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAllDone ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
          width: isAllDone ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isAllDone ? Icons.verified_rounded : Icons.pending_actions_rounded,
                    color: isAllDone ? const Color(0xFF16A34A) : AppColors.accentBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Progreso de Alistamiento',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAllDone ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$completedCount / $total Fases ($percentInt%)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isAllDone ? const Color(0xFF16A34A) : AppColors.accentBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Barra de progreso lineal
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isAllDone ? const Color(0xFF16A34A) : AppColors.accentBlue,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            isAllDone
                ? 'Todas las fases completadas. La máquina está lista para despacho a transporte.'
                : 'Se requiere completar la secuencia obligatoria de fases para habilitar el despacho.',
            style: TextStyle(
              fontSize: 12,
              color: isAllDone ? const Color(0xFF15803D) : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- Línea de Tiempo Secuencial de las 3 Fases Oficiales ---
  Widget _buildSequentialPhasesSection(MachineModel machine) {
    if (_isLoadingPhases) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Column(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.accentBlue),
              ),
              SizedBox(height: 12),
              Text(
                'Consultando fases de alistamiento...',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    // Asegurar las 3 fases ordenadas: 1. lavado -> 2. ensamblaje -> 3. pintura
    final phases = List<PreparationPhaseModel>.from(_phases);
    phases.sort((a, b) => a.stepNumber.compareTo(b.stepNumber));

    // Si aún no hay fases cargadas, armar plantilla por defecto
    if (phases.isEmpty) {
      phases.addAll([
        PreparationPhaseModel(id: '1', machineId: machine.id, name: 'lavado', status: 'completada'),
        PreparationPhaseModel(id: '2', machineId: machine.id, name: 'ensamblaje', status: 'en_proceso'),
        PreparationPhaseModel(id: '3', machineId: machine.id, name: 'pintura', status: 'pendiente'),
      ]);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fases de Alistamiento Obligatorio',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.accentBlue),
                tooltip: 'Actualizar fases',
                onPressed: _loadPhases,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const Text(
            'Avance secuencial: Cada fase debe completarse antes de iniciar la siguiente.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 18),

          // Renderizar los 3 pasos secuenciales con evaluación de restricción
          ...List.generate(phases.length, (index) {
            final phase = phases[index];
            final isLast = index == phases.length - 1;

            // REGLA DE NEGOCIO ESTRICTA:
            // Fase 1 (Lavado): Nunca está bloqueada.
            // Fase 2 (Ensamblaje): Bloqueada si Fase 1 no está completada.
            // Fase 3 (Pintura): Bloqueada si Fase 2 no está completada.
            bool isLocked = false;
            PreparationPhaseModel? prerequisitePhase;

            if (index > 0) {
              final prev = phases[index - 1];
              if (!prev.isCompleted) {
                isLocked = true;
                prerequisitePhase = prev;
              }
            }

            return _buildSequentialPhaseItem(
              phase: phase,
              isLocked: isLocked,
              prerequisitePhase: prerequisitePhase,
              isLast: isLast,
              onTap: () {
                if (isLocked) {
                  _showLockedPhaseDialog(context, phase, prerequisitePhase!);
                } else {
                  PhaseActionModal.show(
                    context: context,
                    machineId: widget.machine.id,
                    phase: phase,
                    onPhaseUpdated: _loadPhases,
                  );
                }
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSequentialPhaseItem({
    required PreparationPhaseModel phase,
    required bool isLocked,
    required PreparationPhaseModel? prerequisitePhase,
    required bool isLast,
    required VoidCallback onTap,
  }) {
    Color indicatorBg;
    Widget indicatorChild;
    Color cardBg;
    Color borderColor;

    if (isLocked) {
      indicatorBg = const Color(0xFFE2E8F0);
      indicatorChild = const Icon(Icons.lock_rounded, size: 14, color: Color(0xFF94A3B8));
      cardBg = const Color(0xFFF8FAFC);
      borderColor = const Color(0xFFE2E8F0);
    } else if (phase.isCompleted) {
      indicatorBg = const Color(0xFF059669);
      indicatorChild = const Icon(Icons.check_rounded, size: 16, color: Colors.white);
      cardBg = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFFBBF7D0);
    } else if (phase.isInProgress) {
      indicatorBg = AppColors.accentBlue;
      indicatorChild = Text(
        '${phase.stepNumber}',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
      );
      cardBg = const Color(0xFFEFF6FF);
      borderColor = const Color(0xFFBFDBFE);
    } else {
      indicatorBg = const Color(0xFFD97706);
      indicatorChild = Text(
        '${phase.stepNumber}',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
      );
      cardBg = Colors.white;
      borderColor = const Color(0xFFE2E8F0);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna de indicador y línea vertical conectora
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: indicatorBg,
                  shape: BoxShape.circle,
                ),
                child: Center(child: indicatorChild),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: phase.isCompleted ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Tarjeta interactiva de la fase
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              phase.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isLocked ? AppColors.textMuted : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          _buildPhaseStatusBadge(phase, isLocked),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phase.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isLocked ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                      if (isLocked) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Bloqueada: Requiere finalizar "${prerequisitePhase?.displayName ?? 'fase anterior'}".',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (!isLocked && phase.observations != null && phase.observations!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.comment_outlined, size: 14, color: AppColors.accentBlue),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  phase.observations!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textPrimary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!isLocked) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              phase.operatorName != null
                                  ? 'Operario: ${phase.operatorName}'
                                  : 'Tocar para gestionar fase',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accentBlue,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: AppColors.accentBlue,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseStatusBadge(PreparationPhaseModel phase, bool isLocked) {
    if (isLocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 12, color: Color(0xFF94A3B8)),
            SizedBox(width: 4),
            Text(
              'Bloqueada',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    Color bg;
    Color fg;
    String label;

    if (phase.isCompleted) {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
      label = 'Completada';
    } else if (phase.isInProgress) {
      bg = const Color(0xFFDBEAFE);
      fg = const Color(0xFF1D4ED8);
      label = 'En Proceso';
    } else {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFB45309);
      label = 'Pendiente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, color: Color(0xFFD97706), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Fase Bloqueada',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No puedes iniciar ni registrar avances en la fase de "${phase.displayName}".',
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.35),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.accentBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Debes completar primero la fase #${prerequisite.stepNumber}: ${prerequisite.displayName}.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }


  // --- Sección de Evidencias Fotográficas ---
  Widget _buildEvidenceSection() {
    final List<Map<String, dynamic>> photos = [
      {'index': 0, 'label': '1. Frente y cuchara'},
      {'index': 1, 'label': '2. Oruga izquierda'},
      {'index': 2, 'label': '3. Cabina interior'},
      {'index': 3, 'label': '4. Motor / Fluidos'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Evidencias fotográficas',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                '3 / 4 registradas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Grilla 2x2 de fotos requeridas
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, i) {
              final isUploaded = _photoUploaded[i] ?? false;
              final label = photos[i]['label'] as String;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _photoUploaded[i] = !isUploaded;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isUploaded
                            ? 'Evidencia eliminada'
                            : 'Foto capturada para: $label',
                      ),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isUploaded ? const Color(0xFFF8FAFC) : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUploaded ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (isUploaded)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: SizedBox.expand(
                            child: Image.asset(
                              'assets/images/maqui_trace_bg.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      // Overlay o placeholder
                      if (!isUploaded)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 22,
                                color: AppColors.textMuted,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tomar foto',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Barra inferior de texto
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isUploaded
                                ? const Color(0xCC0F172A)
                                : const Color(0xFFF1F5F9),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(11),
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isUploaded ? Colors.white : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Observaciones técnicas del turno ---
  Widget _buildNotesSection(MachineModel machine) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.notes_rounded, size: 18, color: AppColors.primaryNavy),
              SizedBox(width: 8),
              Text(
                'Observaciones de campo',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              machine.notes ??
                  'Equipo en óptimas condiciones de estructura y mandos hidráulicos. Se completaron 2 litros de refrigerante 50/50 y se verificó tensión de orugas.',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Barra Inferior Fija de Acción ---
  Widget _buildStickyBottomBar(BuildContext context, MachineModel machine) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Botón secundario: Reportar novedad
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Formulario de novedad técnica abierto'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Icon(
              Icons.flag_outlined,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),

          // Botón primario: Continuar Alistamiento
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Alistamiento de ${machine.name} en curso'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.assignment_turned_in_outlined, size: 20),
              label: const Text(
                'Continuar alistamiento',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Modal para Código QR de la Máquina ---
  void _showMachineQrModal(BuildContext context, MachineModel machine) {
    QrDisplayModal.show(context, machine);
  }
}

