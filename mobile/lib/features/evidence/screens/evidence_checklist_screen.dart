import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../models/evidence_model.dart';
import '../providers/evidence_provider.dart';
import '../services/image_compression_service.dart';
import '../widgets/fullscreen_image_viewer.dart';
import 'preview_evidence_screen.dart';

class RequiredAngle {
  final String key;
  final String title;
  final String description;
  final IconData icon;

  const RequiredAngle({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class EvidenceChecklistScreen extends StatefulWidget {
  final String machineId;
  final String machineSerial;
  final String machineModel;
  final String? phaseId;
  final String? phaseName;

  const EvidenceChecklistScreen({
    super.key,
    required this.machineId,
    required this.machineSerial,
    required this.machineModel,
    this.phaseId,
    this.phaseName,
  });

  @override
  State<EvidenceChecklistScreen> createState() => _EvidenceChecklistScreenState();
}

class _EvidenceChecklistScreenState extends State<EvidenceChecklistScreen> {
  final ImagePicker _picker = ImagePicker();
  String _selectedPhaseFilter = 'todos'; // 'todos', 'ensamblaje', 'lavado', 'pintura'

  static const List<RequiredAngle> _angles = [
    RequiredAngle(
      key: 'frontal',
      title: 'Vista Frontal',
      description: 'Vista delantera completa, implemento apoyado.',
      icon: Icons.agriculture_outlined,
    ),
    RequiredAngle(
      key: 'lateral',
      title: 'Vista Lateral',
      description: 'Costado completo, orugas/ruedas y chasis.',
      icon: Icons.swap_horiz_rounded,
    ),
    RequiredAngle(
      key: 'cabina',
      title: 'Cabina e Interior',
      description: 'Mandos, palancas, horómetro y controles.',
      icon: Icons.event_seat_outlined,
    ),
    RequiredAngle(
      key: 'serial',
      title: 'Serial y Plaqueta',
      description: 'Plaqueta metálica de fábrica con número de serie.',
      icon: Icons.qr_code_2_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EvidenceProvider>().fetchEvidences(widget.machineId);
    });
  }

  /// Busca de forma precisa si existe una evidencia para un ángulo obligatorio
  EvidenceModel? _findEvidenceForAngle(List<EvidenceModel> list, RequiredAngle angle) {
    for (final ev in list) {
      final urlLower = ev.url.toLowerCase();
      final obsLower = (ev.observations ?? '').toLowerCase();
      final keyLower = angle.key.toLowerCase();
      final titleLower = angle.title.toLowerCase();

      if (urlLower.contains(keyLower) ||
          obsLower.contains('angle:$keyLower') ||
          obsLower.contains(titleLower) ||
          obsLower.contains(keyLower)) {
        return ev;
      }
    }
    return null;
  }

  /// Inicia el flujo de captura con cámara y compresión
  Future<void> _captureEvidence({
    required RequiredAngle angle,
    bool isVideo = false,
  }) async {
    try {
      XFile? picked;
      if (isVideo) {
        picked = await _picker.pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(seconds: 30),
        );
      } else {
        picked = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 100,
        );
      }

      if (picked == null || !mounted) return;

      final originalFile = File(picked.path);

      // Mostrar diálogo de compresión
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.accentBlue,
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Optimizando imagen...',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final compression = await ImageCompressionService.compressImage(
        originalFile,
        filenamePrefix: 'evidence_${angle.key}',
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Cerrar diálogo

      // Abrir pantalla de previsualización
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PreviewEvidenceScreen(
            file: compression.file,
            machineId: widget.machineId,
            machineSerial: widget.machineSerial,
            angleTitle: angle.title,
            angleKey: angle.key,
            phaseId: widget.phaseId,
            phaseName: widget.phaseName,
            compression: compression,
            isVideo: isVideo,
          ),
        ),
      );

      if (saved == true && mounted) {
        context.read<EvidenceProvider>().fetchEvidences(widget.machineId);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al capturar evidencia: $e'),
          backgroundColor: AppColors.statusRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Subida libre desde galería
  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    final compression = await ImageCompressionService.compressImage(
      File(picked.path),
      filenamePrefix: 'evidence_galeria',
    );
    if (!mounted) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PreviewEvidenceScreen(
          file: compression.file,
          machineId: widget.machineId,
          machineSerial: widget.machineSerial,
          angleTitle: 'Evidencia de Inspección',
          angleKey: 'general',
          phaseId: widget.phaseId,
          phaseName: widget.phaseName,
          compression: compression,
        ),
      ),
    );

    if (saved == true && mounted) {
      context.read<EvidenceProvider>().fetchEvidences(widget.machineId);
    }
  }

  // ───────────────────────────── UI REDISEÑADA (UI/UX PRO MAX) ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EvidenceProvider>();
    final allEvidences = provider.evidences;

    // Filtrar evidencias según la fase seleccionada
    final evidences = _selectedPhaseFilter == 'todos'
        ? allEvidences
        : allEvidences.where((e) {
            final ph = (e.phaseName ?? '').toLowerCase();
            return ph.contains(_selectedPhaseFilter);
          }).toList();

    // Contar cuántos de los 4 ángulos obligatorios están registrados
    int completedAngles = 0;
    for (final a in _angles) {
      if (_findEvidenceForAngle(allEvidences, a) != null) {
        completedAngles++;
      }
    }
    final double progress = (completedAngles / _angles.length).clamp(0.0, 1.0);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evidencias y checklist',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.machineSerial} · ${widget.machineModel}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 22),
            tooltip: 'Actualizar',
            onPressed: () => provider.fetchEvidences(widget.machineId),
          ),
          const SizedBox(width: 6),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: provider.isLoading && allEvidences.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentBlue),
            )
          : RefreshIndicator(
              onRefresh: () => provider.fetchEvidences(widget.machineId),
              color: AppColors.accentBlue,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + bottomInset),
                children: [
                  // 1. Tarjeta resumen de inspección con barra segmentada
                  _buildInspectionSummaryCard(completedAngles, progress, allEvidences),
                  const SizedBox(height: 20),

                  // 2. Módulo unificado de checklist técnico (4 ángulos obligatorios)
                  _buildSectionHeader(
                    title: 'Inspección técnica obligatoria',
                    subtitle: 'Los 4 ángulos son indispensables para certificar el activo',
                  ),
                  const SizedBox(height: 10),
                  _buildChecklistModule(allEvidences),
                  const SizedBox(height: 28),

                  // 3. Galería y archivo de evidencias registradas
                  _buildGalleryHeader(allEvidences.length),
                  const SizedBox(height: 12),
                  _buildPhaseFilterRow(),
                  const SizedBox(height: 14),

                  if (evidences.isEmpty)
                    _buildEmptyGalleryState()
                  else
                    _buildEvidenceGrid(evidences),
                ],
              ),
            ),
    );
  }

  /// Encabezado de sección con estilo industrial sobrio
  Widget _buildSectionHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Tarjeta de resumen de inspección con indicador segmentado de 4 pasos
  Widget _buildInspectionSummaryCard(int completed, double progress, List<EvidenceModel> allEvidences) {
    final isComplete = completed == _angles.length;
    final missing = _angles.length - completed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ESTADO DE CERTIFICACIÓN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isComplete
                          ? 'Listo para despacho'
                          : 'Pendiente de fotos obligatorias',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isComplete ? const Color(0xFFE8F5EC) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isComplete ? '4 de 4 completas' : '$completed de 4 completas',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isComplete ? const Color(0xFF15803D) : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Barra segmentada de 4 pasos visuales (1 por cada ángulo)
          Row(
            children: List.generate(_angles.length, (index) {
              final angle = _angles[index];
              final hasEvidence = _findEvidenceForAngle(allEvidences, angle) != null;
              final isLast = index == _angles.length - 1;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: hasEvidence ? const Color(0xFF15803D) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        angle.title.replaceFirst('Vista ', ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: hasEvidence ? FontWeight.w600 : FontWeight.w400,
                          color: hasEvidence ? const Color(0xFF15803D) : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            isComplete
                ? 'Todos los ángulos reglamentarios han sido registrados y validados.'
                : missing == 1
                    ? 'Falta 1 fotografía para completar el protocolo de alistamiento.'
                    : 'Faltan $missing fotografías para completar el protocolo de alistamiento.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Módulo unificado que contiene las 4 filas del checklist en un único bloque limpio
  Widget _buildChecklistModule(List<EvidenceModel> allEvidences) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: List.generate(_angles.length, (index) {
          final angle = _angles[index];
          final evidence = _findEvidenceForAngle(allEvidences, angle);
          final isLast = index == _angles.length - 1;

          return Column(
            children: [
              _buildChecklistRow(angle, evidence),
              if (!isLast)
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9), indent: 76),
            ],
          );
        }),
      ),
    );
  }

  /// Fila de cada ángulo obligatorio dentro del módulo unificado
  Widget _buildChecklistRow(RequiredAngle angle, EvidenceModel? evidence) {
    final isDone = evidence != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Miniatura o placeholder del ángulo (área táctil accesible)
          GestureDetector(
            onTap: isDone ? () => FullscreenImageViewer.openFromModel(context, evidence) : () => _captureEvidence(angle: angle),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDone ? const Color(0xFF15803D).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: isDone
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          evidence.url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(Icons.broken_image_rounded, size: 20, color: AppColors.textMuted),
                          ),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFF15803D),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 10),
                          ),
                        ),
                      ],
                    )
                  : Icon(angle.icon, color: AppColors.textSecondary, size: 24),
            ),
          ),
          const SizedBox(width: 14),

          // Textos informativos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        angle.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isDone)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5EC),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Registrada',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  angle.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Botones de acción ergonómicos (mínimo 48dp de alto)
          if (isDone)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Ver foto completa',
                  onPressed: () => FullscreenImageViewer.openFromModel(context, evidence),
                  icon: const Icon(Icons.visibility_outlined, size: 20, color: AppColors.textSecondary),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
                ),
                IconButton(
                  tooltip: 'Tomar de nuevo',
                  onPressed: () => _captureEvidence(angle: angle),
                  icon: const Icon(Icons.restart_alt_rounded, size: 20, color: AppColors.accentBlue),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
                ),
              ],
            )
          else
            SizedBox(
              height: 38,
              child: FilledButton.icon(
                onPressed: () => _captureEvidence(angle: angle),
                icon: const Icon(Icons.camera_alt_rounded, size: 16),
                label: const Text('Tomar'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Encabezado de galería con botón de subir desde galería
  Widget _buildGalleryHeader(int count) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              const Text(
                'Evidencias registradas',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: _pickFromGallery,
          icon: const Icon(Icons.photo_library_outlined, size: 16),
          label: const Text('Subir foto'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accentBlue,
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  /// Fila de filtros por fase con diseño sobrio y moderno
  Widget _buildPhaseFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('todos', 'Todas'),
          const SizedBox(width: 8),
          _buildFilterChip('ensamblaje', 'Ensamblaje'),
          const SizedBox(width: 8),
          _buildFilterChip('lavado', 'Lavado'),
          const SizedBox(width: 8),
          _buildFilterChip('pintura', 'Pintura'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedPhaseFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedPhaseFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentBlue : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// Estado vacío limpio y técnico
  Widget _buildEmptyGalleryState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.photo_camera_outlined, size: 28, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedPhaseFilter == 'todos'
                ? 'Sin evidencias capturadas'
                : 'Sin evidencias en fase de $_selectedPhaseFilter',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Usa el checklist de arriba o el botón "Subir foto" para adjuntar imágenes.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Grid de evidencias fotográficas registradas
  Widget _buildEvidenceGrid(List<EvidenceModel> evidences) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.84,
      ),
      itemCount: evidences.length,
      itemBuilder: (context, index) {
        final item = evidences[index];
        return _buildEvidenceGridCard(item);
      },
    );
  }

  Widget _buildEvidenceGridCard(EvidenceModel item) {
    final d = item.createdAt;
    final dateText =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return GestureDetector(
      onTap: () => FullscreenImageViewer.openFromModel(context, item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    item.url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: AppColors.accentBlue,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
                        ),
                      );
                    },
                  ),
                  if (item.isVideo)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam_rounded, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Video',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.uploaderName ?? 'Operario',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        dateText,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (item.phaseName != null) ...[
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.phaseName!,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentBlue,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}