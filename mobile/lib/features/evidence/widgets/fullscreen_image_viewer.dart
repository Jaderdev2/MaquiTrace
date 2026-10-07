import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/evidence_model.dart';

class FullscreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String? subtitle;
  final String? uploaderName;
  final DateTime? date;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.uploaderName,
    this.date,
  });

  /// Abre el visor en pantalla completa de forma estática
  static void open(
    BuildContext context, {
    required String imageUrl,
    required String title,
    String? subtitle,
    String? uploaderName,
    DateTime? date,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) => FullscreenImageViewer(
          imageUrl: imageUrl,
          title: title,
          subtitle: subtitle,
          uploaderName: uploaderName,
          date: date,
        ),
      ),
    );
  }

  /// Abre el visor a partir de un modelo EvidenceModel
  static void openFromModel(BuildContext context, EvidenceModel evidence) {
    open(
      context,
      imageUrl: evidence.url,
      title: evidence.uploaderName != null && evidence.uploaderName!.isNotEmpty
          ? 'Evidencia de ${evidence.uploaderName}'
          : 'Evidencia de Maquinaria',
      subtitle: evidence.phaseName != null ? 'Fase: ${evidence.phaseName}' : null,
      uploaderName: evidence.uploaderName,
      date: evidence.createdAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_done, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'Oracle OCI',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Área de imagen con zoom interactivo (pinch-to-zoom)
            Expanded(
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5.0,
                  panEnabled: true,
                  scaleEnabled: true,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.accentBlue),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
                            SizedBox(height: 12),
                            Text(
                              'No se pudo cargar la imagen de alta resolución',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Barra inferior con metadatos de auditoría
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                border: const Border(top: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (uploaderName != null)
                    Row(
                      children: [
                        const Icon(Icons.person_pin_rounded, color: Colors.white70, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          uploaderName!,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  if (date != null)
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${date!.day}/${date!.month}/${date!.year} ${date!.hour.toString().padLeft(2, '0')}:${date!.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
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
