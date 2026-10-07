import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class CompressionResult {
  final File file;
  final int originalBytes;
  final int compressedBytes;

  const CompressionResult({
    required this.file,
    required this.originalBytes,
    required this.compressedBytes,
  });

  double get savedPercentage {
    if (originalBytes <= 0) return 0.0;
    final saved = ((originalBytes - compressedBytes) / originalBytes) * 100.0;
    return saved > 0 ? saved : 0.0;
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String get originalFormatted => formatBytes(originalBytes);
  String get compressedFormatted => formatBytes(compressedBytes);
}

class ImageCompressionService {
  /// Comprime una imagen fotográfica reduciendo su peso entre un 70% y 90%
  /// manteniendo una resolución nítida y óptima para evidencias industriales.
  static Future<CompressionResult> asyncCompressImage(File originalFile) async {
    return compressImage(originalFile);
  }

  static Future<CompressionResult> compressImage(
    File originalFile, {
    int quality = 80,
    int minWidth = 1600,
    int minHeight = 1200,
  }) async {
    final originalBytes = await originalFile.length();

    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/evidence_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
      );

      if (compressedXFile != null) {
        final compressedFile = File(compressedXFile.path);
        final compressedBytes = await compressedFile.length();

        debugPrint(
          '[Compresión] Original: ${CompressionResult.formatBytes(originalBytes)} -> '
          'Comprimido: ${CompressionResult.formatBytes(compressedBytes)} '
          '(${((originalBytes - compressedBytes) / originalBytes * 100).toStringAsFixed(1)}% ahorro)',
        );

        return CompressionResult(
          file: compressedFile,
          originalBytes: originalBytes,
          compressedBytes: compressedBytes,
        );
      }
    } catch (e) {
      debugPrint('[Compresión] Error al comprimir imagen, usando original: $e');
    }

    // Fallback: Si no se pudo comprimir, retornar el archivo original
    return CompressionResult(
      file: originalFile,
      originalBytes: originalBytes,
      compressedBytes: originalBytes,
    );
  }
}
