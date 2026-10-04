import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../auth/providers/auth_provider.dart';
import '../../history/screens/history_screen.dart';
import '../../machines/models/machine_model.dart';
import '../../machines/screens/machine_detail_screen.dart';
import '../../machines/screens/machines_screen.dart';
import '../../machines/services/machines_service.dart';
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
  final MachinesService _machinesService = MachinesService();
  List<MachineModel> _dashboardMachines = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardMachines();
  }

  Future<void> _loadDashboardMachines() async {
    try {
      final list = await _machinesService.search();
      if (list.isNotEmpty && mounted) {
        setState(() => _dashboardMachines = list);
      }
    } catch (_) {}
  }

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
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final displayName = (user?.name.trim().isNotEmpty ?? false) ? user!.name.trim() : 'Operario';
    final firstName = displayName.split(' ').first;
    final initials = displayName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    final machines = _dashboardMachines.isNotEmpty
        ? _dashboardMachines
        : MachinesService.localCatalog;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _loadDashboardMachines,
        color: AppColors.accentBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // 1. Barra superior: Avatar con iniciales reales + Saludo dinámico al usuario autenticado
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
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryNavy,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initials.isNotEmpty ? initials : 'OP',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, $firstName',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            user?.role.toUpperCase() ?? 'OPERARIO DE ALISTAMIENTO',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Icono de notificaciones
                GestureDetector(
                  onTap: () => _showNotificationsModal(context),
                  child: Container(
                    width: 42,
                    height: 42,
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
                    child: const Center(
                      child: Icon(
                        Icons.notifications_outlined,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Tarjeta de progreso calculada a partir de las máquinas reales
            _buildUnifiedDailyProgressCard(machines),
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

                // Tarjetas de maquinaria reales
                ...machines.take(3).map((machine) {
                  String statusText;
                  Color statusColor;
                  Color statusBg;
                  Color statusBorder;

                  switch (machine.overallState) {
                    case OverallState.inProgress:
                      statusText = 'En proceso';
                      statusColor = AppColors.accentBlue;
                      statusBg = const Color(0xFFEFF6FF);
                      statusBorder = const Color(0xFFDBEAFE);
                      break;
                    case OverallState.completed:
                      statusText = 'Completado';
                      statusColor = const Color(0xFF059669);
                      statusBg = const Color(0xFFECFDF5);
                      statusBorder = const Color(0xFFA7F3D0);
                      break;
                    default:
                      statusText = 'Pendiente';
                      statusColor = const Color(0xFFD97706);
                      statusBg = const Color(0xFFFEF3C7);
                      statusBorder = const Color(0xFFFDE68A);
                      break;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildCleanMachineCard(
                      name: machine.name,
                      serial: machine.serial,
                      statusText: statusText,
                      statusColor: statusColor,
                      statusBg: statusBg,
                      statusBorder: statusBorder,
                      imagePath: machine.displayImage,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MachineDetailScreen(machine: machine),
                          ),
                        ).then((_) => _loadDashboardMachines());
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    }

  // Tarjeta de Alistamientos del Día (Diseño industrial moderno de alto impacto visual)
  Widget _buildUnifiedDailyProgressCard(List<MachineModel> machines) {
    final int total = machines.length;
    final int pending = machines.where((m) => m.overallState == OverallState.pending).length;
    final int inProgress = machines.where((m) => m.overallState == OverallState.inProgress).length;
    final int completed = machines.where((m) => m.overallState == OverallState.completed).length;
    final double progressFraction = total > 0 ? (completed / total) : 0.0;
    final int percent = (progressFraction * 100).toInt();

    final activeMachine = machines.firstWhere(
      (m) => m.overallState == OverallState.inProgress,
      orElse: () => machines.firstWhere(
        (m) => m.overallState == OverallState.pending,
        orElse: () => machines.isNotEmpty
            ? machines.first
            : const MachineModel(
                id: '',
                name: '',
                serial: '',
                category: '',
                overallState: OverallState.pending,
                phases: [],
              ),
      ),
    );

    final bool hasActive = activeMachine.serial.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF334155), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila 1: Indicador de turno en vivo y porcentaje
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x2210B981),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x4410B981)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'TURNO EN VIVO · PATIO BUENAVENTURA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF34D399),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Control de Alistamiento',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Avance general de flota asignada',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                // Cifra de porcentaje heroica
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0x331E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x4438BDF8)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF38BDF8),
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        '$completed de $total listos',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Barra de progreso de alto contraste con gradiente
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 7,
                color: const Color(0xFF334155),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progressFraction.clamp(0.0, 1.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF38BDF8),
                            Color(0xFF2563EB),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Desglose de métricas táctiles en tarjetas oscuras estilizadas
            Row(
              children: [
                _buildDarkHeroMetricPill(
                  label: 'Pendientes',
                  count: '$pending',
                  valueColor: const Color(0xFFFBBF24),
                  onTap: () => setState(() => _currentNavIndex = 1),
                ),
                const SizedBox(width: 8),
                _buildDarkHeroMetricPill(
                  label: 'En proceso',
                  count: '$inProgress',
                  valueColor: const Color(0xFF38BDF8),
                  highlighted: true,
                  onTap: () => setState(() => _currentNavIndex = 1),
                ),
                const SizedBox(width: 8),
                _buildDarkHeroMetricPill(
                  label: 'Listas',
                  count: '$completed',
                  valueColor: const Color(0xFF34D399),
                  onTap: () => setState(() => _currentNavIndex = 1),
                ),
              ],
            ),

            // Banner interactivo de la máquina activa en atención
            if (hasActive) ...[
              const SizedBox(height: 14),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MachineDetailScreen(machine: activeMachine),
                    ),
                  ).then((_) => _loadDashboardMachines());
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0x3D0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: activeMachine.overallState == OverallState.inProgress
                          ? const Color(0x5538BDF8)
                          : const Color(0x33475569),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: activeMachine.overallState == OverallState.inProgress
                              ? const Color(0x3338BDF8)
                              : const Color(0x22FBBF24),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          activeMachine.overallState == OverallState.inProgress
                              ? Icons.play_arrow_rounded
                              : Icons.schedule_rounded,
                          size: 18,
                          color: activeMachine.overallState == OverallState.inProgress
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFFFBBF24),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeMachine.overallState == OverallState.inProgress
                                  ? 'EN ATENCIÓN AHORA'
                                  : 'SIGUIENTE EN FILA',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: activeMachine.overallState == OverallState.inProgress
                                    ? const Color(0xFF38BDF8)
                                    : const Color(0xFFFBBF24),
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${activeMachine.name} · Serial: ${activeMachine.serial}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDarkHeroMetricPill({
    required String label,
    required String count,
    required Color valueColor,
    bool highlighted = false,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: highlighted ? const Color(0x3338BDF8) : const Color(0x221E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlighted ? const Color(0x5538BDF8) : const Color(0x33475569),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: valueColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
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
                    const Text(
                      'Notificaciones operativas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: const [
                      Icon(
                        Icons.verified_outlined,
                        size: 42,
                        color: AppColors.accentBlue,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Jornada al día',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'No hay avisos ni alertas técnicas pendientes para tu rol en este momento.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
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
}
