import 'package:flutter/material.dart';

/// Recorta la parte inferior de los encabezados con una curva orgánica
/// de ola, exactamente igual a la de los diseños en Figma.
class WaveClipper extends CustomClipper<Path> {
  const WaveClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 28);

    // Curva cúbica bezier orgánica
    path.cubicTo(
      size.width * 0.28,
      size.height - 48,
      size.width * 0.68,
      size.height + 4,
      size.width,
      size.height - 26,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
