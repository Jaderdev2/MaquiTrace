import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Barra de navegación inferior unificada con botón central de escaneo
/// sobresaliente, estilo premium y fiel a los estándares de Figma para MaquiTrace.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onScanTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const double barHeight = 64.0;
    const double protrusion = 16.0;

    return SizedBox(
      height: barHeight + bottomPadding + protrusion,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // 1. Contenedor unificado blanco continuo que abraza hasta el borde inferior de la pantalla
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight + bottomPadding,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 18,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // 1. Inicio
                    Expanded(
                      child: _buildNavItem(
                        icon: Icons.home_rounded,
                        label: 'Inicio',
                        index: 0,
                      ),
                    ),
                    // 2. Máquinas
                    Expanded(
                      child: _buildNavItem(
                        icon: Icons.agriculture_outlined,
                        label: 'Máquinas',
                        index: 1,
                      ),
                    ),
                    // Espacio central reservado para el botón flotante
                    const SizedBox(width: 64),
                    // 4. Historial
                    Expanded(
                      child: _buildNavItem(
                        icon: Icons.calendar_month_outlined,
                        label: 'Historial',
                        index: 3,
                      ),
                    ),
                    // 5. Perfil
                    Expanded(
                      child: _buildNavItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Perfil',
                        index: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Botón central de Escaneo: sobresale de forma limpia y equilibrada
          Positioned(
            bottom: bottomPadding + 6,
            child: GestureDetector(
              onTap: onScanTap ?? () => onTap(2),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentBlue.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 3.5),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Escanear',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: currentIndex == 2 ? FontWeight.w700 : FontWeight.w600,
                      color: currentIndex == 2 ? AppColors.accentBlue : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = currentIndex == index;
    final color = isActive ? AppColors.accentBlue : const Color(0xFF94A3B8);

    return InkWell(
      onTap: () => onTap(index),
      splashColor: AppColors.accentBlue.withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
