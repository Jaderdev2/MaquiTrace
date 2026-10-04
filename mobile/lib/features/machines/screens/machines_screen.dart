import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../qr_scanner/screens/qr_scanner_screen.dart';
import '../models/machine_model.dart';
import '../services/machines_service.dart';
import 'machine_detail_screen.dart';

class MachinesScreen extends StatefulWidget {
  final bool showScaffold;

  const MachinesScreen({super.key, this.showScaffold = true});

  @override
  State<MachinesScreen> createState() => _MachinesScreenState();
}

class _MachinesScreenState extends State<MachinesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MachinesService _machinesService = MachinesService();
  String _selectedCategory = 'Todas';
  String _searchQuery = '';
  List<MachineModel> _apiMachines = [];

  final List<String> _categories = const [
    'Todas',
    'Excavadoras',
    'Cargadores',
    'Retroexcavadoras',
    'Volquetas',
    'Motoniveladoras',
  ];

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  Future<void> _loadFromBackend() async {
    try {
      final backendList = await _machinesService.search();
      if (backendList.isNotEmpty && mounted) {
        setState(() {
          _apiMachines = backendList;
        });
      }
    } catch (_) {}
  }


  // Datos reales del patio
  final List<MachineModel> _machines = const [
    MachineModel(
      id: '1',
      name: 'CAT 320D',
      serial: 'ABC123',
      category: 'Excavadoras',
      overallState: OverallState.inProgress,
      phases: [PhaseState.completed, PhaseState.inProgress, PhaseState.pending],
    ),
    MachineModel(
      id: '2',
      name: 'Komatsu WA470',
      serial: 'KMT458',
      category: 'Cargadores',
      overallState: OverallState.pending,
      phases: [PhaseState.pending, PhaseState.pending, PhaseState.pending],
    ),
    MachineModel(
      id: '3',
      name: 'CAT 320D',
      serial: 'DEF789',
      category: 'Excavadoras',
      overallState: OverallState.completed,
      phases: [PhaseState.completed, PhaseState.completed, PhaseState.completed],
    ),
    MachineModel(
      id: '4',
      name: 'John Deere 310L',
      serial: 'JD310-992',
      category: 'Retroexcavadoras',
      overallState: OverallState.inProgress,
      phases: [PhaseState.completed, PhaseState.inProgress, PhaseState.pending],
    ),
    MachineModel(
      id: '5',
      name: 'Kenworth T800',
      serial: 'KW-8841',
      category: 'Volquetas',
      overallState: OverallState.completed,
      phases: [PhaseState.completed, PhaseState.completed, PhaseState.completed],
    ),
    MachineModel(
      id: '6',
      name: 'CAT 140M',
      serial: 'MN-9042',
      category: 'Motoniveladoras',
      overallState: OverallState.inProgress,
      phases: [PhaseState.completed, PhaseState.inProgress, PhaseState.pending],
      location: 'Sede Buenaventura · Patio 2 (B-08)',
      operatingHours: '2,680 h',
      fuelPercent: 82,
    ),
  ];

  List<MachineModel> get _allMachines => _apiMachines.isNotEmpty ? _apiMachines : _machines;

  List<MachineModel> get _filteredMachines {
    return _allMachines.where((m) {
      final matchesSearch = _searchQuery.isEmpty ||
          m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.serial.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == 'Todas' || m.category.toLowerCase().contains(_selectedCategory.toLowerCase());

      return matchesSearch && matchesCategory;
    }).toList();
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredMachines;

    final content = SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Cabecera limpia y respirable
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Máquinas',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Inventario de equipos · Sede Buenaventura',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Barra de búsqueda con botón de filtro integrado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Buscar por modelo o serial...',
                          hintStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.inputIcon,
                            size: 22,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Botón de filtro minimalista
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.tune_rounded,
                        color: AppColors.accentBlue,
                        size: 22,
                      ),
                      onPressed: () {
                        // TODO: abrir bottom sheet de filtros avanzados
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botón de escáner QR rápido
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const QrScannerScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Filtro único por categoría (horizontal scroll limpio)
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat == _selectedCategory;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accentBlue : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.accentBlue : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Lista de tarjetas limpias y espaciosas
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 40,
                            color: AppColors.textMuted.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'No se encontraron máquinas',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Verifica el serial o cambia la categoría.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: list.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final machine = list[index];
                        return _buildCleanCard(machine);
                      },
                    ),
            ),
          ],
        ),
      );

    if (!widget.showScaffold) {
      return content;
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF8FAFC),
      body: content,
    );
  }

  Widget _buildCleanCard(MachineModel machine) {
    // Estado simplificado
    String statusLabel;
    Color statusColor;
    Color statusBg;

    switch (machine.overallState) {
      case OverallState.inProgress:
        statusLabel = 'En alistamiento';
        statusColor = AppColors.accentBlue;
        statusBg = const Color(0xFFEFF6FF);
        break;
      case OverallState.pending:
        statusLabel = 'Pendiente';
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFEF3C7);
        break;
      case OverallState.completed:
        statusLabel = 'Lista para despacho';
        statusColor = const Color(0xFF059669);
        statusBg = const Color(0xFFECFDF5);
        break;
      case OverallState.inTransit:
        statusLabel = 'En tránsito';
        statusColor = const Color(0xFF2563EB);
        statusBg = const Color(0xFFDBEAFE);
        break;
      case OverallState.delivered:
        statusLabel = 'Entregada';
        statusColor = const Color(0xFF059669);
        statusBg = const Color(0xFFECFDF5);
        break;
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MachineDetailScreen(machine: machine),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
            // Miniatura de la máquina amplia y limpia
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 60,
                height: 60,
                color: const Color(0xFFEFF6FF),
                child: Image.asset(
                  machine.displayImage,
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

            // Información esencial: Nombre, Serial y Estado
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    machine.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${machine.category} · Serial: ${machine.serial}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Flecha chevron limpia hacia la pantalla de detalle
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFCBD5E1),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
