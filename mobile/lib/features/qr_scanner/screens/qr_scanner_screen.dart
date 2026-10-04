import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../machines/screens/machine_detail_screen.dart';

import '../../machines/services/machines_service.dart';
import '../widgets/manual_search_modal.dart';
import '../widgets/qr_scanner_overlay.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final MachinesService _machinesService = MachinesService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _extractSerial(String rawValue) {
    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is Map<String, dynamic> && decoded.containsKey('serial')) {
        return decoded['serial'].toString().trim().toUpperCase();
      }
    } catch (_) {
      // No es JSON, continuar
    }

    final trimmed = rawValue.trim();
    if (trimmed.contains('serial=')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && uri.queryParameters.containsKey('serial')) {
        return uri.queryParameters['serial']!.trim().toUpperCase();
      }
    }

    return trimmed.toUpperCase();
  }

  Future<void> _handleBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    final serial = _extractSerial(rawValue);

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    // Pausar la cámara temporalmente
    await _controller.stop();

    if (!mounted) return;

    // Mostrar diálogo de carga elegante
    _showLoadingDialog();

    try {
      final machine = await _machinesService.getBySerial(serial);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Cierra el loader

      if (machine != null) {
        // Máquina encontrada en backend: Navegar a su ficha detallada
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MachineDetailScreen(machine: machine),
          ),
        );
      } else {
        _showNotFoundDialog(serial);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Cierra el loader
      _showErrorDialog('Error al consultar con el backend: $e');
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.accentBlue,
                ),
              ),
              SizedBox(width: 18),
              Text(
                'Identificando maquinaria...',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotFoundDialog(String serial) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 28),
            SizedBox(width: 10),
            Text(
              'No Encontrada',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
              ),
            ),
          ],
        ),
        content: Text(
          'No se encontró ninguna maquinaria registrada con el serial "$serial" en la base de datos.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openManualSearch();
            },
            child: const Text('Búsqueda manual'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isProcessing = false);
              await _controller.start();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reintentar escaneo'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Error de Conexión'),
        content: Text(error),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isProcessing = false);
              await _controller.start();
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _openManualSearch() {
    ManualSearchModal.show(context).then((_) {
      if (mounted && !_isProcessing) {
        _controller.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanWindow = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.40),
      width: 260,
      height: 260,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Cámara en vivo con mobile_scanner
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcodeDetected,
          ),

          // 2. Retícula y máscara oscura recortada con animación láser
          QrScannerOverlay(scanWindow: scanWindow),

          // 3. Barra superior con botones translúcidos
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón volver
                    _buildGlassCircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),

                    // Título central
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, color: AppColors.accentBlue, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Identificar Máquina',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Controles de cámara: linterna y rotación
                    Row(
                      children: [
                        ValueListenableBuilder<MobileScannerState>(
                          valueListenable: _controller,
                          builder: (context, state, child) {
                            final torch = state.torchState == TorchState.on;
                            return _buildGlassCircleButton(
                              icon: torch ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                              iconColor: torch ? const Color(0xFFFBBF24) : Colors.white,
                              onTap: () => _controller.toggleTorch(),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildGlassCircleButton(
                          icon: Icons.flip_camera_ios_rounded,
                          onTap: () => _controller.switchCamera(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Panel inferior con instrucción y botón de búsqueda manual
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Instrucción
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Text(
                        'Apunta al código QR grabado en el chasis o cabina de la máquina',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Botón de contingencia: Búsqueda manual por serial
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openManualSearch,
                        icon: const Icon(Icons.edit_note_rounded, size: 22),
                        label: const Text(
                          'Ingresar serial manualmente',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryNavy,
                          elevation: 6,
                          shadowColor: Colors.black.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}
