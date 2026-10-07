import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/evidence_provider.dart';
import '../services/image_compression_service.dart';

class PreviewEvidenceScreen extends StatefulWidget {
  final File file;
  final String machineId;
  final String machineSerial;
  final String angleTitle;
  final String? phaseId;
  final String? phaseName;
  final CompressionResult compression;
  final bool isVideo;

  const PreviewEvidenceScreen({
    super.key,
    required this.file,
    required this.machineId,
    required this.machineSerial,
    required this.angleTitle,
    this.phaseId,
    this.phaseName,
    required this.compression,
    this.isVideo = false,
  });

  @override
  State<PreviewEvidenceScreen> createState() => _PreviewEvidenceScreenState();
}

class _PreviewEvidenceScreenState extends State<PreviewEvidenceScreen> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmUpload() async {
    final provider = context.read<EvidenceProvider>();

    final success = await provider.uploadEvidence(
      machineId: widget.machineId,
      file: widget.compression.file,
      phaseId: widget.phaseId,
      type: widget.isVideo ? 'video' : 'foto',
      observations: _notesController.text.trim().isNotEmpty
          ? '[${widget.angleTitle}] ${_notesController.text.trim()}'
          : '[${widget.angleTitle}] Evidencia capturada',
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text('¡Evidencia "${widget.angleTitle}" guardada con éxito en Oracle Cloud!'),
              ),
            ],
          ),
          backgroundColor: AppColors.statusGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Error al subir la evidencia.'),
          backgroundColor: AppColors.statusRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = context.watch<EvidenceProvider>().isUploading;

    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Previsualizar Evidencia',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.machineSerial} · ${widget.angleTitle}',
              style: const TextStyle(color: AppColors.primaryNavyMuted, fontSize: 12),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: isUploading ? null : () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Vista previa de la imagen
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      widget.compression.file,
                      fit: BoxFit.contain,
                    ),
                    // Badge del ángulo en la esquina superior izquierda
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              widget.angleTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Badge de compresión en la esquina superior derecha
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.statusGreen.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.speed, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.compression.compressedFormatted} (-${widget.compression.savedPercentage.toStringAsFixed(0)}%)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tarjeta inferior con observaciones y acciones
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Campo de notas opcionales
                  TextField(
                    controller: _notesController,
                    enabled: !isUploading,
                    decoration: InputDecoration(
                      hintText: 'Observación opcional (ej: sin fugas, pintura uniforme...)',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.edit_note, color: AppColors.accentBlue),
                      filled: true,
                      fillColor: AppColors.surfaceGrey,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.inputBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.accentBlue, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botones de acción
                  Row(
                    children: [
                      // Botón reintentar / descartar
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          onPressed: isUploading ? null : () => Navigator.of(context).pop(false),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Repetir'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.inputBorder),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Botón confirmar y subir
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: isUploading ? null : _handleConfirmUpload,
                          icon: isUploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload_outlined, size: 20),
                          label: Text(
                            isUploading ? 'Subiendo a OCI...' : 'Guardar y Subir',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
      ),
    );
  }
}
