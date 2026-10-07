import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../models/evidence_model.dart';
import '../providers/evidence_provider.dart';
import '../services/image_compression_service.dart';
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

  static const List<RequiredAngle> _angles = [
    RequiredAngle(
      key: 'frontal',
      title: 'Vista Frontal',
      description: 'Vista completa de frente, implemento (balde/cuchilla) visible.',
      icon: Icons.front_hand_outlined,
    ),
    RequiredAngle(
      key: 'lateral',
      title: 'Vista Lateral',
      description: 'Costado completo, orugas o neumáticos y chasis.',
      icon: Icons.directions_boat_outlined,
    ),
    RequiredAngle(
      key: 'cabina',
      title: 'Cabina e Interior',
      description: 'Mandos, tablero de control y horómetro visible.',
      icon: Icons.airline_seat_recline_normal_outlined,
    ),
    RequiredAngle(
      key: 'serial',
      title: 'Serial y Plaqueta',
      description: 'Plaqueta metálica del fabricante con serial legible.',
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

  /// Verifica si un ángulo específico ya fue capturado en las evidencias
  EvidenceModel? _findEvidenceForAngle(List<EvidenceModel> list, String angleKey) {
    for (final ev in list) {
      if (ev.url.contains(angleKey) ||
          (ev.uploaderName != null && ev.uploaderName!.contains(angleKey))) {
        return ev;
      }
    }
    return null;
  }

  /// Inicia el flujo de captura con cámara y compresión
  Future<void> _captureEvidence({
    required String angleTitle,
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
          imageQuality: 100, // Tomar a máxima calidad, la compresión la hace nuestro servicio
        );
      }

      if (picked == null || !mounted) return;

      final originalFile = File(picked.path);

      // Compresión automática
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.accentBlue),
                  SizedBox(height: 16),
                  Text('Optimizando y comprimiendo imagen...'),
                ],
              ),
            ),
          ),
        ),
      );

      final compression = await ImageCompressionService.compressImage(originalFile);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Cerrar diálogo de carga

      // Navegar a la pantalla de previsualización y confirmación
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PreviewEvidenceScreen(
            file: compression.file,
            machineId: widget.machineId,
            machineSerial: widget.machineSerial,
            angleTitle: angleTitle,
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
        ),
      );
    }
  }

  /// Permite seleccionar desde la galería
  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    final compression = await ImageCompressionService.compressImage(File(picked.path));
    if (!mounted) return;

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PreviewEvidenceScreen(
          file: compression.file,
          machineId: widget.machineId,
          machineSerial: widget.machineSerial,
          angleTitle: 'Evidencia de Galería',
          phaseId: widget.phaseId,
          phaseName: widget.phaseName,
          compression: compression,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EvidenceProvider>();
    final evidences = provider.evidences;

    // Calcular cuántos ángulos se han cumplido
    int completedAngles = 0;
    for (final a in _angles) {
      if (_findEvidenceForAngle(evidences, a.title) != null ||
          evidences.any((e) => e.url.toLowerCase().contains(a.key))) {
        completedAngles++;
      }
    }
    // Si hay evidencias genéricas, sumarlas al conteo
    if (completedAngles == 0 && evidences.isNotEmpty) {
      completedAngles = evidences.length.clamp(0, 4);
    }

    final double progress = (completedAngles / _angles.length).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evidencias y Checklist',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.machineSerial} · ${widget.machineModel}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined, color: AppColors.accentBlue),
            tooltip: 'Subir desde galería',
            onPressed: _pickFromGallery,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            tooltip: 'Actualizar',
            onPressed: () => provider.fetchEvidences(widget.machineId),
          ),
        ],
      ),
      body: provider.isLoading && evidences.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentBlue),
            )
          : RefreshIndicator(
              onRefresh: () => provider.fetchEvidences(widget.machineId),
              color: AppColors.accentBlue,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Tarjeta de progreso del checklist fotográfico
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Ángulos Obligatorios',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: progress == 1.0
                                    ? AppColors.completedTint
                                    : AppColors.inProgressTint,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$completedAngles / ${_angles.length}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: progress == 1.0
                                      ? AppColors.statusGreen
                                      : AppColors.accentBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: AppColors.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress == 1.0 ? AppColors.statusGreen : AppColors.accentBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          progress == 1.0
                              ? '¡Todos los ángulos obligatorios han sido registrados!'
                              : 'Captura los ángulos requeridos para avalar la fase.',
                          style: TextStyle(
                            fontSize: 12,
                            color: progress == 1.0 ? AppColors.statusGreen : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lista de los 4 ángulos obligatorios
                  const Text(
                    'Checklist Fotográfico de Inspección',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ..._angles.map((angle) {
                    final isDone = evidences.any(
                      (e) => e.url.toLowerCase().contains(angle.key),
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDone ? AppColors.statusGreen.withValues(alpha: 0.3) : AppColors.cardBorder,
                          width: isDone ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Ícono o estado
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDone ? AppColors.completedTint : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isDone ? Icons.check_circle : angle.icon,
                              color: isDone ? AppColors.statusGreen : AppColors.accentBlue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Título y descripción
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  angle.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  angle.description,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Botón para capturar
                          ElevatedButton.icon(
                            onPressed: () => _captureEvidence(angleTitle: angle.title),
                            icon: Icon(
                              isDone ? Icons.refresh : Icons.camera_alt,
                              size: 16,
                            ),
                            label: Text(
                              isDone ? 'Repetir' : 'Tomar',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDone ? AppColors.surfaceVariant : AppColors.accentBlue,
                              foregroundColor: isDone ? AppColors.textSecondary : Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // Sección: Evidencias registradas en Oracle Cloud
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Evidencias Guardadas (${evidences.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (evidences.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.inProgressTint,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_done, color: AppColors.accentBlue, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Oracle Cloud OCI',
                                style: TextStyle(
                                  color: AppColors.accentBlue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (evidences.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.camera_enhance_outlined, size: 40, color: AppColors.textMuted),
                          SizedBox(height: 10),
                          Text(
                            'Aún no hay evidencias registradas.',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Usa los botones superiores para capturar fotos con la cámara.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: evidences.length,
                      itemBuilder: (context, index) {
                        final item = evidences[index];
                        return _buildEvidenceCard(item);
                      },
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildEvidenceCard(EvidenceModel item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen con soporte de carga
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
                // Tipo badge
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isVideo ? Icons.videocam : Icons.photo_camera,
                          color: Colors.white,
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.type.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Pie de tarjeta con uploader y fecha
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.uploaderName ?? 'Operario',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year} ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
