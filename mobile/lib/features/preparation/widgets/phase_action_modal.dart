import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/preparation_phase_model.dart';
import '../services/preparation_service.dart';

/// Paleta del sheet (la misma que usa la pantalla de detalle de máquina).
class _Ui {
  static const border = Color(0xFFE2E8F0);
  static const mutedSurface = Color(0xFFF8FAFC);
  static const handle = Color(0xFFCBD5E1);

  static const success = Color(0xFF15803D);
  static const successBg = Color(0xFFE8F5EC);
  static const warning = Color(0xFFB45309);
  static const warningBg = Color(0xFFFEF3C7);
  static const info = Color(0xFF1D4ED8);
  static const infoBg = Color(0xFFE6EFFE);

  static const error = Color(0xFFB91C1C);
  static const errorBg = Color(0xFFFEF2F2);
  static const errorBorder = Color(0xFFFCA5A5);

  static const double radius = 10;
}

class PhaseActionModal extends StatefulWidget {
  final String machineId;
  final PreparationPhaseModel phase;
  final VoidCallback onPhaseUpdated;

  const PhaseActionModal({
    super.key,
    required this.machineId,
    required this.phase,
    required this.onPhaseUpdated,
  });

  static Future<void> show({
    required BuildContext context,
    required String machineId,
    required PreparationPhaseModel phase,
    required VoidCallback onPhaseUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PhaseActionModal(
        machineId: machineId,
        phase: phase,
        onPhaseUpdated: onPhaseUpdated,
      ),
    );
  }

  @override
  State<PhaseActionModal> createState() => _PhaseActionModalState();
}

class _PhaseActionModalState extends State<PhaseActionModal> {
  final PreparationService _prepService = PreparationService();
  late final TextEditingController _obsController;

  bool _isLoading = false;

  /// Acción en curso, para mostrar el spinner solo en el botón pulsado.
  String? _activeAction;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _obsController = TextEditingController(text: widget.phase.observations ?? '');
  }

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _isLoading = true;
      _activeAction = newStatus;
      _errorMessage = null;
    });

    try {
      final updated = await _prepService.updatePhase(
        machineId: widget.machineId,
        phaseId: widget.phase.id,
        status: newStatus,
        observations: _obsController.text.trim().isNotEmpty ? _obsController.text.trim() : null,
      );

      if (!mounted) return;

      if (updated != null) {
        widget.onPhaseUpdated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'completada'
                  ? 'Fase "${widget.phase.displayName}" completada con éxito.'
                  : 'Fase "${widget.phase.displayName}" iniciada en proceso.',
            ),
            backgroundColor: newStatus == 'completada' ? _Ui.success : AppColors.accentBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Fallback local simulado para cuando el backend está fuera de línea
        widget.onPhaseUpdated();
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _activeAction = null;
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  Future<void> _saveObservationsOnly() async {
    setState(() {
      _isLoading = true;
      _activeAction = 'nota';
      _errorMessage = null;
    });

    try {
      await _prepService.updatePhase(
        machineId: widget.machineId,
        phaseId: widget.phase.id,
        status: widget.phase.status,
        observations: _obsController.text.trim(),
      );

      if (!mounted) return;
      widget.onPhaseUpdated();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Observaciones guardadas correctamente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _activeAction = null;
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  IconData _phaseIcon(PreparationPhaseModel phase) {
    final n = phase.name.toLowerCase();
    if (n.contains('lav')) return Icons.water_drop_rounded;
    if (n.contains('ensam')) return Icons.build_rounded;
    if (n.contains('pint')) return Icons.format_paint_rounded;
    return Icons.settings_rounded;
  }

  // Mismo indicador circular que la línea de tiempo de la pantalla.
  Widget _buildNode(PreparationPhaseModel phase) {
    const double size = 44;
    if (phase.isCompleted) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: _Ui.success, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, size: 26, color: Colors.white),
      );
    }
    if (phase.isInProgress) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: _Ui.info, shape: BoxShape.circle),
        child: Icon(_phaseIcon(phase), size: 22, color: Colors.white),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: _Ui.warning, width: 2),
      ),
      child: Icon(_phaseIcon(phase), size: 22, color: _Ui.warning),
    );
  }

  Widget _buildStatusChip(PreparationPhaseModel phase) {
    final Color fg;
    final Color bg;
    final String label;

    if (phase.isCompleted) {
      fg = _Ui.success;
      bg = _Ui.successBg;
      label = 'Completada';
    } else if (phase.isInProgress) {
      fg = _Ui.info;
      bg = _Ui.infoBg;
      label = 'En proceso';
    } else {
      fg = _Ui.warning;
      bg = _Ui.warningBg;
      label = 'Pendiente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _spinner(Color color) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2.4, color: color),
    );
  }

  Widget _primaryButton({
    required String action,
    required String label,
    required String loadingLabel,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final busy = _isLoading && _activeAction == action;
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: _isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_Ui.radius)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            busy ? _spinner(Colors.white) : Icon(icon, size: 22),
            const SizedBox(width: 10),
            Text(busy ? loadingLabel : label),
          ],
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required String action,
    required String label,
    required VoidCallback onPressed,
  }) {
    final busy = _isLoading && _activeAction == action;
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: _isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryNavy,
          side: const BorderSide(color: _Ui.handle),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_Ui.radius)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy) ...[
              _spinner(AppColors.primaryNavy),
              const SizedBox(width: 10),
            ],
            Text(busy ? 'Guardando...' : label),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(PreparationPhaseModel phase) {
    if (phase.isPending) {
      return _primaryButton(
        action: 'en_proceso',
        label: 'Iniciar fase',
        loadingLabel: 'Iniciando...',
        icon: Icons.play_arrow_rounded,
        color: AppColors.accentBlue,
        onPressed: () => _updateStatus('en_proceso'),
      );
    }

    if (phase.isInProgress) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _primaryButton(
            action: 'completada',
            label: 'Finalizar fase',
            loadingLabel: 'Finalizando...',
            icon: Icons.check_circle_rounded,
            color: _Ui.success,
            onPressed: () => _updateStatus('completada'),
          ),
          const SizedBox(height: 10),
          _secondaryButton(
            action: 'nota',
            label: 'Guardar nota',
            onPressed: _saveObservationsOnly,
          ),
        ],
      );
    }

    // Ya completada: solo se pueden actualizar las observaciones
    return _primaryButton(
      action: 'nota',
      label: 'Guardar observaciones',
      loadingLabel: 'Guardando...',
      icon: Icons.save_rounded,
      color: AppColors.accentBlue,
      onPressed: _saveObservationsOnly,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final phase = widget.phase;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tirador
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _Ui.handle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Encabezado: indicador de la fase + nombre + estado
              Row(
                children: [
                  _buildNode(phase),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fase ${phase.stepNumber}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          phase.displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(phase),
                ],
              ),
              const SizedBox(height: 14),

              Text(
                phase.description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Observaciones
              const Text(
                'Observaciones',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _obsController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 5,
                style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Estado, novedades o piezas intervenidas',
                  hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: _Ui.mutedSurface,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_Ui.radius),
                    borderSide: const BorderSide(color: _Ui.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_Ui.radius),
                    borderSide: const BorderSide(color: _Ui.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_Ui.radius),
                    borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _Ui.errorBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _Ui.errorBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: _Ui.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: _Ui.error,
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              _buildActions(phase),
            ],
          ),
        ),
      ),
    );
  }
}