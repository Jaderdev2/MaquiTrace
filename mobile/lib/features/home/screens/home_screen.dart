import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../history/screens/history_screen.dart';
import '../../machines/models/machine_model.dart';
import '../../machines/screens/machine_detail_screen.dart';
import '../../machines/screens/machines_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../qr_scanner/screens/qr_scanner_screen.dart';
import '../../qr_scanner/widgets/manual_search_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentNavIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentNavIndex != 0) {
          setState(() {
            _currentNavIndex = 0;
          });
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // Iconos oscuros nítidos
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          extendBody: true,
          backgroundColor: const Color(0xFFF8FAFC),
          bottomNavigationBar: _buildBottomNav(),
          body: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_currentNavIndex) {
      case 1:
        return const MachinesScreen(showScaffold: false);
      case 2:
        return const QrScannerScreen();
      case 3:
        return const HistoryScreen(showScaffold: false);
      case 4:
        return ProfileScreen(
          showScaffold: false,
          onNavigateToTab: (index) {
            setState(() => _currentNavIndex = index);
          },
        );
      default:
        return _buildHomeContent(context);
    }
  }


  Widget _buildHomeContent(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Barra superior: Avatar pulido + "Hola, Jhon" a la izquierda, Notificaciones a la derecha
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() => _currentNavIndex = 4);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      // Avatar pulido en Deep Navy con iniciales
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryNavy,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'JR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Hola, Jhon',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Icono de notificaciones a la derecha
                GestureDetector(
                  onTap: () => _showNotificationsModal(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          size: 22,
                          color: AppColors.textPrimary,
                        ),
                        Positioned(
                          top: 10,
                          right: 11,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.accentBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

                // 3. Tarjeta Unificada de Progreso y Alistamientos del Día
                _buildUnifiedDailyProgressCard(),
                const SizedBox(height: 24),

                // 5. Acciones rápidas (Diseño limpio en blanco con icono enmarcado y chevron azul)
                const Text(
                  'Acciones rápidas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 14),

                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.qr_code_scanner_rounded,
                          title: 'Escanear QR',
                          subtitle: 'Identifica la máquina con su código QR',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const QrScannerScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.search_rounded,
                          title: 'Buscar por serial',
                          subtitle: 'Consulta una máquina por su número de serie',
                          onTap: () {
                            ManualSearchModal.show(context);
                          },
                        ),
                      ),

                    ],
                  ),
                ),
                const SizedBox(height: 26),

                // 6. Mis alistamientos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mis alistamientos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentNavIndex = 1;
                        });
                      },
                      child: const Text(
                        'Ver todos >',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 7. Tarjetas de maquinaria limpias con miniatura enfocada en maquinaria
                _buildCleanMachineCard(
                  name: 'CAT 320D',
                  serial: 'ABC123',
                  statusText: 'En proceso',
                  statusColor: AppColors.accentBlue,
                  statusBg: const Color(0xFFEFF6FF),
                  statusBorder: const Color(0xFFDBEAFE),
                  imagePath: 'assets/images/categories/Excavadoras.webp',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MachineDetailScreen(
                          machine: MachineModel(
                            id: '1',
                            name: 'CAT 320D',
                            serial: 'ABC123',
                            category: 'Excavadoras',
                            overallState: OverallState.inProgress,
                            phases: [PhaseState.completed, PhaseState.inProgress, PhaseState.pending, PhaseState.pending],
                            location: 'Sede Buenaventura · Patio 2 (B-04)',
                            operatingHours: '3,420 h',
                            fuelPercent: 75,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildCleanMachineCard(
                  name: 'Komatsu WA470',
                  serial: 'KMT458',
                  statusText: 'Pendiente',
                  statusColor: const Color(0xFFD97706),
                  statusBg: const Color(0xFFFEF3C7),
                  statusBorder: const Color(0xFFFDE68A),
                  imagePath: 'assets/images/categories/Cargadores frontales.webp',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MachineDetailScreen(
                          machine: MachineModel(
                            id: '2',
                            name: 'Komatsu WA470',
                            serial: 'KMT458',
                            category: 'Cargadores',
                            overallState: OverallState.pending,
                            phases: [PhaseState.pending, PhaseState.pending, PhaseState.pending, PhaseState.pending],
                            location: 'Sede Buenaventura · Patio 1 (C-12)',
                            operatingHours: '1,890 h',
                            fuelPercent: 40,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildCleanMachineCard(
                  name: 'CAT 320D',
                  serial: 'DEF789',
                  statusText: 'Completado',
                  statusColor: const Color(0xFF059669),
                  statusBg: const Color(0xFFECFDF5),
                  statusBorder: const Color(0xFFA7F3D0),
                  imagePath: 'assets/images/categories/Excavadoras.webp',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MachineDetailScreen(
                          machine: MachineModel(
                            id: '3',
                            name: 'CAT 320D',
                            serial: 'DEF789',
                            category: 'Excavadoras',
                            overallState: OverallState.completed,
                            phases: [PhaseState.completed, PhaseState.completed, PhaseState.completed, PhaseState.completed],
                            location: 'Sede Buenaventura · Zona Despacho',
                            operatingHours: '4,150 h',
                            fuelPercent: 95,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 8. Banner informativo de tareas pendientes
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x04000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.description_outlined,
                        color: AppColors.accentBlue,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tienes 2 tareas pendientes de registro de evidencia.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }

  // Tarjeta de Alistamientos del Día (Diseño limpio, luminoso e industrial)
  Widget _buildUnifiedDailyProgressCard() {
    const int pending = 3;
    const int inProgress = 2;
    const int completed = 5;
    const int total = pending + inProgress + completed; // 10
    final double progressFraction = completed / total; // 0.5
    final int percent = (progressFraction * 100).toInt();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Título operativo + Contador tipográfico
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Alistamientos de hoy',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sede Buenaventura · Jornada activa',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: const [
                        Text(
                          '$completed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          ' / $total',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$percent% completado',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Barra de progreso continua (monocromática, sin colores de semáforo)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 5,
                color: const Color(0xFFF1F5F9),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progressFraction,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Píldoras de desglose de estado (Neutras, sobrias)
            Row(
              children: [
                _buildLightMetricPill(
                  label: 'Pendientes',
                  count: '$pending',
                  onTap: () => setState(() => _currentNavIndex = 1),
                ),
                const SizedBox(width: 8),
                _buildLightMetricPill(
                  label: 'En proceso',
                  count: '$inProgress',
                  highlighted: true,
                  onTap: () => setState(() => _currentNavIndex = 1),
                ),
                const SizedBox(width: 8),
                _buildLightMetricPill(
                  label: 'Listas',
                  count: '$completed',
                  onTap: () => setState(() => _currentNavIndex = 1),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Acceso directo al equipo activo del turno
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MachineDetailScreen(
                      machine: MachineModel(
                        id: '1',
                        name: 'CAT 320D',
                        serial: 'ABC123',
                        category: 'Excavadoras',
                        overallState: OverallState.inProgress,
                        phases: [
                          PhaseState.completed,
                          PhaseState.inProgress,
                          PhaseState.pending,
                          PhaseState.pending,
                        ],
                        location: 'Sede Buenaventura · Patio 2 (B-04)',
                        operatingHours: '3,420 h',
                        fuelPercent: 75,
                      ),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.play_circle_outline_rounded,
                      size: 16,
                      color: AppColors.accentBlue,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'En atención: CAT 320D · Bahía B-04',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.accentBlue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLightMetricPill({
    required String label,
    required String count,
    bool highlighted = false,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: highlighted ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: highlighted ? const Color(0xFFDBEAFE) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: highlighted ? AppColors.accentBlue : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: highlighted ? AppColors.accentBlue : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tarjetas de acciones rápidas (Blanco puro, badge con icono azul, chevron azul y tipografía nítida)
  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: const Color(0xFF0066FF),
                          size: 24,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF3B82F6),
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // Tarjeta de maquinaria con imagen real de categoría y etiqueta de estado limpia
  Widget _buildCleanMachineCard({
    required String name,
    required String serial,
    required String statusText,
    required Color statusColor,
    required Color statusBg,
    required Color statusBorder,
    required VoidCallback onTap,
    String? imagePath,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
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
            // Miniatura enfocada en la maquinaria pesada real
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 58,
                height: 58,
                child: Image.asset(
                  imagePath ?? 'assets/images/categories/Excavadoras.webp',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFEFF6FF),
                      child: const Icon(
                        Icons.precision_manufacturing_rounded,
                        color: AppColors.accentBlue,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Información: Nombre, Serial y Tag de Estado
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Serial: $serial',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusBorder),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Flecha de navegación a detalle
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFCBD5E1),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return AppBottomNav(
      currentIndex: _currentNavIndex,
      onTap: (index) {
        setState(() {
          _currentNavIndex = index;
        });
      },
      onScanTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const QrScannerScreen(),
          ),
        );
      },
    );
  }


  void _showNotificationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tirador superior de arrastre
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Encabezado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Notificaciones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Text(
                            '2 nuevas',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Lista de notificaciones (estilo industrial unificado, sin tricolor)
                _buildNotificationTile(
                  icon: Icons.assignment_outlined,
                  title: 'Nueva asignación de máquina',
                  body: 'CAT 320D (ABC123) programada para alistamiento en Sede Buenaventura (Patio 2).',
                  time: 'Hace 15 min',
                  isUnread: true,
                ),
                const SizedBox(height: 10),
                _buildNotificationTile(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Checklist validado',
                  body: 'El supervisor validó el alistamiento de la Komatsu WA470.',
                  time: 'Hace 1 hora',
                  isUnread: true,
                ),
                const SizedBox(height: 10),
                _buildNotificationTile(
                  icon: Icons.access_time_rounded,
                  title: 'Recordatorio de evidencia',
                  body: 'Recuerda subir las 4 fotos de inspección antes del cierre.',
                  time: 'Hace 3 horas',
                  isUnread: false,
                ),
                const SizedBox(height: 20),

                // Botón de acción
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required String title,
    required String body,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnread ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnread ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
          width: isUnread ? 1.2 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 19,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
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
