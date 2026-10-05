import 'package:flutter/material.dart';

/// Controlador centralizado de shimmer/pulso para grupos de esqueletos
class SkeletonGroup extends StatefulWidget {
  final Widget child;

  const SkeletonGroup({super.key, required this.child});

  static double of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_SkeletonScope>();
    return scope?.opacity ?? 0.65;
  }

  @override
  State<SkeletonGroup> createState() => _SkeletonGroupState();
}

class _SkeletonGroupState extends State<SkeletonGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.45, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return _SkeletonScope(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

class _SkeletonScope extends InheritedWidget {
  final double opacity;

  const _SkeletonScope({
    required this.opacity,
    required super.child,
  });

  @override
  bool updateShouldNotify(_SkeletonScope oldWidget) =>
      oldWidget.opacity != opacity;
}

/// Caja básica de esqueleto con bordes redondeados y opacidad sutil
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 6,
    this.shape = BoxShape.rectangle,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = SkeletonGroup.of(context);
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          shape: shape,
          borderRadius:
              shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
          color: color ?? const Color(0xFFE2E8F0),
        ),
      ),
    );
  }
}

// ============================================================================
// SKELETONS EXACTOS PARA EL HOME
// ============================================================================

/// Esqueleto fiel a la tarjeta destacada "Continuar alistamiento" del Home
class HomeActiveMachineSkeleton extends StatelessWidget {
  const HomeActiveMachineSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título de la sección 'Continuar alistamiento'
          const SkeletonBox(width: 140, height: 14, borderRadius: 3),
          const SizedBox(height: 12),

          // Fila: Miniatura (56x56) + Nombre y Serial
          Row(
            children: [
              const SkeletonBox(
                width: 56,
                height: 56,
                borderRadius: 6,
                color: Color(0xFFF1F5F9),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 160, height: 17, borderRadius: 4),
                    SizedBox(height: 6),
                    SkeletonBox(
                      width: 95,
                      height: 13,
                      borderRadius: 3,
                      color: Color(0xFFF1F5F9),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // MiniStepper con 3 nodos de 34px y conectores reales
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nodo 1: Ensamblaje
              Expanded(
                child: Column(
                  children: const [
                    SkeletonBox(width: 34, height: 34, shape: BoxShape.circle),
                    SizedBox(height: 6),
                    SkeletonBox(width: 60, height: 12, borderRadius: 3),
                  ],
                ),
              ),
              // Conector 1
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 15.5),
                  child: const SkeletonBox(
                    height: 3,
                    borderRadius: 2,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
              ),
              // Nodo 2: Lavado
              Expanded(
                child: Column(
                  children: const [
                    SkeletonBox(width: 34, height: 34, shape: BoxShape.circle),
                    SizedBox(height: 6),
                    SkeletonBox(width: 50, height: 12, borderRadius: 3),
                  ],
                ),
              ),
              // Conector 2
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 15.5),
                  child: const SkeletonBox(
                    height: 3,
                    borderRadius: 2,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
              ),
              // Nodo 3: Pintura
              Expanded(
                child: Column(
                  children: const [
                    SkeletonBox(width: 34, height: 34, shape: BoxShape.circle),
                    SizedBox(height: 6),
                    SkeletonBox(width: 50, height: 12, borderRadius: 3),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Botón principal 'Continuar' (48px de alto)
          const SkeletonBox(
            width: double.infinity,
            height: 48,
            borderRadius: 10,
          ),
        ],
      ),
    );
  }
}

/// Esqueleto fiel para la lista agrupada de "Mis alistamientos" en el Home
class HomeMachineGroupedListSkeleton extends StatelessWidget {
  final int itemCount;

  const HomeMachineGroupedListSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < itemCount; i++) ...[
            if (i > 0)
              Container(height: 1, color: const Color(0xFFEDF1F5)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const SkeletonBox(
                    width: 56,
                    height: 56,
                    borderRadius: 6,
                    color: Color(0xFFF1F5F9),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonBox(width: 140, height: 15, borderRadius: 3),
                        SizedBox(height: 5),
                        SkeletonBox(
                          width: 85,
                          height: 12,
                          borderRadius: 3,
                          color: Color(0xFFF1F5F9),
                        ),
                        SizedBox(height: 7),
                        SkeletonBox(width: 76, height: 20, borderRadius: 6),
                      ],
                    ),
                  ),
                  const SkeletonBox(
                    width: 16,
                    height: 16,
                    borderRadius: 4,
                    color: Color(0xFFF1F5F9),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// SKELETON EXACTO PARA EL DETALLE DE MÁQUINA
// ============================================================================

/// Esqueleto fiel a la tarjeta de fases de alistamiento en MachineDetailScreen
class MachineDetailProcessSkeleton extends StatelessWidget {
  const MachineDetailProcessSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado: "Alistamiento" y "x de 3 fases"
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: const [
                SkeletonBox(width: 110, height: 16, borderRadius: 4),
                Spacer(),
                SkeletonBox(width: 85, height: 14, borderRadius: 4),
                SizedBox(width: 8),
                SkeletonBox(width: 20, height: 20, shape: BoxShape.circle),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFEDF1F5)),

          // Cuerpo de la línea de tiempo (3 fases operativas reales)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Column(
              children: [
                // Fase 1: Ensamblaje
                _buildTimelineRowSkeleton(
                  isLast: false,
                  titleWidth: 155,
                  chipWidth: 80,
                  descWidth2: 210,
                  railLineHeight: 52,
                ),
                // Fase 2: Lavado (incluye botón simulado de acción en curso)
                _buildTimelineRowSkeleton(
                  isLast: false,
                  titleWidth: 175,
                  chipWidth: 85,
                  descWidth2: 180,
                  railLineHeight: 88,
                  hasActionButton: true,
                ),
                // Fase 3: Pintura
                _buildTimelineRowSkeleton(
                  isLast: true,
                  titleWidth: 145,
                  chipWidth: 70,
                  descWidth2: 160,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRowSkeleton({
    required bool isLast,
    required double titleWidth,
    required double chipWidth,
    required double descWidth2,
    double railLineHeight = 52,
    bool hasActionButton = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Riel: Nodo circular (40x40) y línea vertical conectora
          SizedBox(
            width: 44,
            child: Column(
              children: [
                const SizedBox(height: 2),
                const SkeletonBox(
                  width: 40,
                  height: 40,
                  shape: BoxShape.circle,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Contenido: Título, Chip, Descripción en 2 líneas y Botón opcional
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SkeletonBox(width: titleWidth, height: 16, borderRadius: 4),
                      const Spacer(),
                      SkeletonBox(width: chipWidth, height: 22, borderRadius: 6),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const SkeletonBox(
                    width: double.infinity,
                    height: 12,
                    borderRadius: 3,
                    color: Color(0xFFF1F5F9),
                  ),
                  const SizedBox(height: 5),
                  SkeletonBox(
                    width: descWidth2,
                    height: 12,
                    borderRadius: 3,
                    color: const Color(0xFFF1F5F9),
                  ),
                  if (hasActionButton) ...[
                    const SizedBox(height: 12),
                    const SkeletonBox(
                      width: 135,
                      height: 36,
                      borderRadius: 8,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SKELETON PARA LA PANTALLA DE MÁQUINAS (CATÁLOGO / TABS)
// ============================================================================

/// Esqueleto fiel a las tarjetas de la pantalla de Máquinas (`_buildCleanCard`)
class MachineCardSkeleton extends StatelessWidget {
  const MachineCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Miniatura de 60x60 con radio 12
          const SkeletonBox(
            width: 60,
            height: 60,
            borderRadius: 12,
            color: Color(0xFFEFF6FF),
          ),
          const SizedBox(width: 14),

          // Nombre, Categoría + Serial y Chip de estado
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 145, height: 16, borderRadius: 4),
                SizedBox(height: 6),
                SkeletonBox(
                  width: 175,
                  height: 12,
                  borderRadius: 3,
                  color: Color(0xFFF1F5F9),
                ),
                SizedBox(height: 10),
                SkeletonBox(width: 85, height: 22, borderRadius: 6),
              ],
            ),
          ),
          const SkeletonBox(
            width: 16,
            height: 16,
            borderRadius: 4,
            color: Color(0xFFF1F5F9),
          ),
        ],
      ),
    );
  }
}
