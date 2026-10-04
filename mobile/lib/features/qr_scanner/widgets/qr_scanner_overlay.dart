import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class QrScannerOverlay extends StatefulWidget {
  final Rect scanWindow;

  const QrScannerOverlay({
    super.key,
    required this.scanWindow,
  });

  @override
  State<QrScannerOverlay> createState() => _QrScannerOverlayState();
}

class _QrScannerOverlayState extends State<QrScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ScannerOverlayPainter(
            scanWindow: widget.scanWindow,
            laserProgress: _anim.value,
          ),
        );
      },
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final double laserProgress;

  _ScannerOverlayPainter({
    required this.scanWindow,
    required this.laserProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.black.withValues(alpha: 0.65);

    // 1. Dibujar sombra exterior oscura recortando la ventana del escáner
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // 2. Dibujar borde sutil del área de escaneo
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanWindow, const Radius.circular(16)),
      borderPaint,
    );

    // 3. Dibujar esquinas industriales resaltadas (Cyan / Accent Blue)
    final cornerPaint = Paint()
      ..color = AppColors.accentBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    const cornerLength = 28.0;
    const cornerRadius = 16.0;

    // Superior Izquierda
    final tlPath = Path()
      ..moveTo(scanWindow.left, scanWindow.top + cornerLength)
      ..lineTo(scanWindow.left, scanWindow.top + cornerRadius)
      ..arcToPoint(
        Offset(scanWindow.left + cornerRadius, scanWindow.top),
        radius: const Radius.circular(cornerRadius),
      )
      ..lineTo(scanWindow.left + cornerLength, scanWindow.top);
    canvas.drawPath(tlPath, cornerPaint);

    // Superior Derecha
    final trPath = Path()
      ..moveTo(scanWindow.right - cornerLength, scanWindow.top)
      ..lineTo(scanWindow.right - cornerRadius, scanWindow.top)
      ..arcToPoint(
        Offset(scanWindow.right, scanWindow.top + cornerRadius),
        radius: const Radius.circular(cornerRadius),
      )
      ..lineTo(scanWindow.right, scanWindow.top + cornerLength);
    canvas.drawPath(trPath, cornerPaint);

    // Inferior Izquierda
    final blPath = Path()
      ..moveTo(scanWindow.left, scanWindow.bottom - cornerLength)
      ..lineTo(scanWindow.left, scanWindow.bottom - cornerRadius)
      ..arcToPoint(
        Offset(scanWindow.left + cornerRadius, scanWindow.bottom),
        radius: const Radius.circular(cornerRadius),
        clockwise: false,
      )
      ..lineTo(scanWindow.left + cornerLength, scanWindow.bottom);
    canvas.drawPath(blPath, cornerPaint);

    // Inferior Derecha
    final brPath = Path()
      ..moveTo(scanWindow.right - cornerLength, scanWindow.bottom)
      ..lineTo(scanWindow.right - cornerRadius, scanWindow.bottom)
      ..arcToPoint(
        Offset(scanWindow.right, scanWindow.bottom - cornerRadius),
        radius: const Radius.circular(cornerRadius),
        clockwise: false,
      )
      ..lineTo(scanWindow.right, scanWindow.bottom - cornerLength);
    canvas.drawPath(brPath, cornerPaint);

    // 4. Línea de láser animada con gradiente
    final laserY = scanWindow.top + 8 + (scanWindow.height - 16) * laserProgress;
    final laserRect = Rect.fromLTWH(
      scanWindow.left + 8,
      laserY - 1.5,
      scanWindow.width - 16,
      3,
    );

    final laserGradient = LinearGradient(
      colors: [
        AppColors.accentBlue.withValues(alpha: 0.0),
        AppColors.accentBlue,
        AppColors.accentBlue.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final laserPaint = Paint()
      ..shader = laserGradient.createShader(laserRect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(laserRect, const Radius.circular(2)),
      laserPaint,
    );

    // Sutil resplandor del láser
    final glowPaint = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawRect(laserRect, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.laserProgress != laserProgress ||
        oldDelegate.scanWindow != scanWindow;
  }
}
