import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/machine_model.dart';
import '../services/machines_service.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'machine_detail_screen.dart';

class MachinesScreen extends StatefulWidget {
  final bool showScaffold;

  const MachinesScreen({super.key, this.showScaffold = true});

  @override
  State<MachinesScreen> createState() => _MachinesScreenState();
}

class _MachinesScreenState extends State<MachinesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _categoryScrollController = ScrollController();
  late final PageController _pageController;
  final MachinesService _machinesService = MachinesService();

  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  List<MachineModel> _apiMachines = [];

  // Filtros operativos seleccionados
  String _selectedStatusFilter = 'Todos'; // 'Todos', 'En alistamiento', 'Pendientes', 'Listas'
  String _selectedSort = 'Por defecto'; // 'Por defecto', 'Modelo (A-Z)', 'Serial'

  final List<String> _categories = const [
    'Todas',
    'Excavadoras',
    'Cargadores',
    'Retroexcavadoras',
    'Volquetas',
    'Motoniveladoras',
  ];

  bool _isLoading = true;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initMachines();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _searchController.dispose();
    _categoryScrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initMachines() async {
    // 1. Cargar caché inmediatamente si existe
    final cached = await _machinesService.getCachedMachines();
    if (cached.isNotEmpty && mounted) {
      setState(() {
        _apiMachines = cached;
        _isLoading = false;
      });
    }
    // 2. Consultar backend para sincronizar
    await _loadFromBackend();
  }

  Future<void> _loadFromBackend({bool isAutoRetry = false}) async {
    if (_apiMachines.isEmpty && !isAutoRetry) {
      setState(() => _isLoading = true);
    }
    try {
      final backendList = await _machinesService.search();
      if (backendList.isNotEmpty && mounted) {
        setState(() {
          _apiMachines = backendList;
          _isLoading = false;
        });
      }
      if (_machinesService.isLastFetchLive) {
        _retryTimer?.cancel();
        _retryTimer = null;
      } else {
        _scheduleAutoRetry();
      }
    } catch (_) {
      _scheduleAutoRetry();
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  void _scheduleAutoRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) _loadFromBackend(isAutoRetry: true);
    });
  }

  List<MachineModel> get _allMachines => _apiMachines;

  bool _matchesCategory(MachineModel m, String category) {
    if (category == 'Todas') return true;
    final catLower = category.toLowerCase().replaceAll(RegExp(r'(es|s)$'), '');
    final mCatLower = m.category.toLowerCase();
    return mCatLower.contains(catLower) || category.toLowerCase().contains(mCatLower);
  }

  List<MachineModel> _getMachinesForCategory(String category) {
    var list = _allMachines.where((m) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          m.name.toLowerCase().contains(query) ||
          m.serial.toLowerCase().contains(query);

      final matchesCat = _matchesCategory(m, category);

      bool matchesStatus = true;
      if (_selectedStatusFilter == 'En alistamiento') {
        matchesStatus = m.overallState == OverallState.inProgress;
      } else if (_selectedStatusFilter == 'Pendientes') {
        matchesStatus = m.overallState == OverallState.pending;
      } else if (_selectedStatusFilter == 'Listas') {
        matchesStatus = m.overallState == OverallState.completed && m.hasAllMandatoryAngles;
      }

      return matchesSearch && matchesCat && matchesStatus;
    }).toList();

    if (_selectedSort == 'Modelo (A-Z)') {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_selectedSort == 'Serial') {
      list.sort((a, b) => a.serial.toLowerCase().compareTo(b.serial.toLowerCase()));
    }

    return list;
  }

  void _onCategorySelected(int index) {
    setState(() {
      _selectedCategoryIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _scrollToCategory(index);
  }

  void _scrollToCategory(int index) {
    if (!_categoryScrollController.hasClients) return;
    final targetOffset = (index * 95.0) - 40.0;
    _categoryScrollController.animateTo(
      targetOffset.clamp(0.0, _categoryScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  bool get _hasActiveFilters =>
      _selectedStatusFilter != 'Todos' || _selectedSort != 'Por defecto';

  void _showFilterModal() {
    String tempStatus = _selectedStatusFilter;
    String tempSort = _selectedSort;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtros de maquinaria',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ESTADO DE ALISTAMIENTO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                        label: 'Todos',
                        isSelected: tempStatus == 'Todos',
                        onTap: () => setModalState(() => tempStatus = 'Todos'),
                      ),
                      _buildFilterChip(
                        label: 'En alistamiento',
                        isSelected: tempStatus == 'En alistamiento',
                        onTap: () => setModalState(() => tempStatus = 'En alistamiento'),
                      ),
                      _buildFilterChip(
                        label: 'Pendientes',
                        isSelected: tempStatus == 'Pendientes',
                        onTap: () => setModalState(() => tempStatus = 'Pendientes'),
                      ),
                      _buildFilterChip(
                        label: 'Listas para despacho',
                        isSelected: tempStatus == 'Listas',
                        onTap: () => setModalState(() => tempStatus = 'Listas'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'ORDENAR POR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                        label: 'Por defecto',
                        isSelected: tempSort == 'Por defecto',
                        onTap: () => setModalState(() => tempSort = 'Por defecto'),
                      ),
                      _buildFilterChip(
                        label: 'Modelo (A-Z)',
                        isSelected: tempSort == 'Modelo (A-Z)',
                        onTap: () => setModalState(() => tempSort = 'Modelo (A-Z)'),
                      ),
                      _buildFilterChip(
                        label: 'Serial',
                        isSelected: tempSort == 'Serial',
                        onTap: () => setModalState(() => tempSort = 'Serial'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedStatusFilter = 'Todos';
                              _selectedSort = 'Por defecto';
                            });
                            Navigator.pop(ctx);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Limpiar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedStatusFilter = tempStatus;
                              _selectedSort = tempSort;
                            });
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Aplicar filtros',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentBlue : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

          // Barra de búsqueda con botón de filtro funcional (QR eliminado porque ya está en el nav central)
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
                                icon: const Icon(Icons.clear_rounded, size: 18),
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
                // Botón de filtro con indicador de estado activo
                GestureDetector(
                  onTap: _showFilterModal,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _hasActiveFilters ? AppColors.accentBlue : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _hasActiveFilters ? AppColors.accentBlue : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                      boxShadow: _hasActiveFilters
                          ? [
                              BoxShadow(
                                color: AppColors.accentBlue.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.tune_rounded,
                        color: _hasActiveFilters ? Colors.white : AppColors.accentBlue,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Pestañas de categoría (desplazables y sincronizadas con el PageView)
          SizedBox(
            height: 38,
            child: ListView.separated(
              controller: _categoryScrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = index == _selectedCategoryIndex;

                return GestureDetector(
                  onTap: () => _onCategorySelected(index),
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

          // PageView que permite deslizar libremente entre categorías
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _categories.length,
              onPageChanged: (index) {
                setState(() {
                  _selectedCategoryIndex = index;
                });
                _scrollToCategory(index);
              },
              itemBuilder: (context, catIndex) {
                final cat = _categories[catIndex];
                final list = _getMachinesForCategory(cat);

                if (_isLoading) {
                  return const SkeletonGroup(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 2, 20, 100),
                      child: Column(
                        children: [
                          MachineCardSkeleton(),
                          SizedBox(height: 12),
                          MachineCardSkeleton(),
                          SizedBox(height: 12),
                          MachineCardSkeleton(),
                        ],
                      ),
                    ),
                  );
                }

                if (list.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _loadFromBackend,
                    color: AppColors.accentBlue,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.16),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 44,
                                color: AppColors.textMuted.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No se encontraron máquinas',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _searchQuery.isNotEmpty || _hasActiveFilters
                                    ? 'Prueba modificando la búsqueda o los filtros.'
                                    : 'No hay equipos registrados en $cat.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadFromBackend,
                  color: AppColors.accentBlue,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 100),
                    itemCount: list.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final machine = list[index];
                      return _buildCleanCard(machine);
                    },
                  ),
                );
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
        if (machine.hasAllMandatoryAngles) {
          statusLabel = 'Lista para despacho';
          statusColor = const Color(0xFF059669);
          statusBg = const Color(0xFFECFDF5);
        } else {
          statusLabel = machine.completedAnglesCount > 0
              ? 'Pendiente fotos (${machine.completedAnglesCount}/4)'
              : 'Pendiente inspección';
          statusColor = const Color(0xFFD97706);
          statusBg = const Color(0xFFFEF3C7);
        }
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
        ).then((_) => _loadFromBackend());
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
                child: machine.buildImage(
                  fit: BoxFit.cover,
                  placeholder: Container(
                    color: const Color(0xFFEFF6FF),
                    child: const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBlue),
                      ),
                    ),
                  ),
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

            // Flecha chevron hacia el detalle
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
