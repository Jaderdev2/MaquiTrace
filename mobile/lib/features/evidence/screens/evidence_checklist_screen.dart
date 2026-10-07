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

  // ───────────────────────────── UI ─────────────────────────────

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.cardBorder),
    );
  }

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
      backgroundColor: AppColors.surfaceGrey,
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
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.machineSerial} · ${widget.machineModel}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            tooltip: 'Actualizar',
            onPressed: () => provider.fetchEvidences(widget.machineId),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
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
                padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
                children: [
                  _buildProgressCard(completedAngles, progress),
                  const SizedBox(height: 24),

                  const Text(
                    'Fotos obligatorias',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ..._angles.map(
                    (angle) => _buildAngleCard(
                      angle,
                      _findEvidenceForAngle(allEvidences, angle),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Encabezado de la galería + acción de subir desde galería
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Evidencias registradas (${allEvidences.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: const Text(
                          'Subir de galería',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accentBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Filtros horizontales
                  SingleChildScrollView(
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
                  ),
                  const SizedBox(height: 16),

                  if (evidences.isEmpty)
                    _buildEmptyState()
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: evidences.length,
                      itemBuilder: (context, index) {
                        final item = evidences[index];
                        return _buildEvidenceGridCard(item);
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressCard(int completed, double progress) {
    final isComplete = progress == 1.0;
    final accent = isComplete ? AppColors.statusGreen : AppColors.accentBlue;
    final missing = _angles.length - completed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso del checklist',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$completed de ${_angles.length}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isComplete
                ? 'Todos los ángulos obligatorios están registrados.'
                : missing == 1
                    ? 'Falta 1 foto para certificar el estado del activo.'
                    : 'Faltan $missing fotos para certificar el estado del activo.',
            style: TextStyle(
              fontSize: 13,
              color: isComplete ? AppColors.statusGreen : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAngleCard(RequiredAngle angle, EvidenceModel? evidence) {
    final ev = evidence;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAngleThumb(angle, ev),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      angle.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      angle.description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ev != null)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => FullscreenImageViewer.openFromModel(context, ev),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Ver'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentBlue,
                      side: BorderSide(color: AppColors.inputBorder),
                      minimumSize: const Size.fromHeight(44),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _captureEvidence(angle: angle),
                    icon: const Icon(Icons.cached_rounded, size: 18),
                    label: const Text('Retomar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: AppColors.inputBorder),
                      minimumSize: const Size.fromHeight(44),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _captureEvidence(angle: angle),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Tomar foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(44),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAngleThumb(RequiredAngle angle, EvidenceModel? evidence) {
    final ev = evidence;

    return GestureDetector(
      onTap: ev != null ? () => FullscreenImageViewer.openFromModel(context, ev) : null,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: ev != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    ev.url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.image_outlined, color: AppColors.textMuted),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.statusGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 12),
                    ),
                  ),
                ],
              )
            : Icon(angle.icon, color: AppColors.textSecondary, size: 28),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Icon(Icons.photo_camera_outlined, size: 36, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            _selectedPhaseFilter == 'todos'
                ? 'Aún no hay evidencias'
                : 'No hay evidencias en esta fase',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Toma una foto desde el checklist o súbela desde la galería.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedPhaseFilter == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedPhaseFilter = key),
      selectedColor: AppColors.accentBlue,
      backgroundColor: Colors.white,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.accentBlue : AppColors.inputBorder,
        ),
      ),
    );
  }

  Widget _buildEvidenceGridCard(EvidenceModel item) {
    final d = item.createdAt;
    final dateText =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return GestureDetector(
      onTap: () => FullscreenImageViewer.openFromModel(context, item),
      child: Container(
        decoration: _cardDecoration(),
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
                        color: AppColors.surfaceVariant,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
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
                        color: AppColors.surfaceVariant,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
                        ),
                      );
                    },
                  ),
                  // Solo se marca cuando es video; las fotos no necesitan etiqueta
                  if (item.isVideo)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam, color: Colors.white, size: 13),
                            SizedBox(width: 4),
                            Text(
                              'Video',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (item.phaseName != null) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.phaseName!,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
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