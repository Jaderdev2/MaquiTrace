import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../machines/models/machine_model.dart';
import '../../machines/screens/machine_detail_screen.dart';

class HistoryItem {
  final MachineModel machine;
  final DateTime timestamp;
  final String duration;
  final String supervisor;
  final int completedPhases;
  final int totalPhases;
  final int photosCount;
  final String? note;

  const HistoryItem({
    required this.machine,
    required this.timestamp,
    required this.duration,
    required this.supervisor,
    this.completedPhases = 4,
    this.totalPhases = 4,
    this.photosCount = 4,
    this.note,
  });
}

class HistoryScreen extends StatefulWidget {
  final bool showScaffold;

  const HistoryScreen({super.key, this.showScaffold = true});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'Todos';

  final List<String> _filters = const [
    'Todos',
    'Hoy',
    'Esta semana',
    'Septiembre',
  ];

  // Datos representativos del historial de alistamientos en Sede Buenaventura
  final List<HistoryItem> _allHistory = [
    // Hoy (25 Septiembre)
    HistoryItem(
      machine: const MachineModel(
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
      timestamp: DateTime(2026, 9, 25, 11, 30),
      duration: '1h 15m',
      supervisor: 'Ing. Carlos Mendoza',
      completedPhases: 2,
      totalPhases: 4,
      photosCount: 3,
      note: 'En proceso de pruebas de torque y mandos hidráulicos.',
    ),
    HistoryItem(
      machine: const MachineModel(
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
      timestamp: DateTime(2026, 9, 25, 9, 15),
      duration: '1h 25m',
      supervisor: 'Ing. Carlos Mendoza',
      completedPhases: 4,
      totalPhases: 4,
      photosCount: 4,
      note: 'Alistamiento aprobado al 100%. Equipo listo para despacho a obra portuaria.',
    ),

    // Ayer (24 Septiembre)
    HistoryItem(
      machine: const MachineModel(
        id: '6',
        name: 'CAT 140M',
        serial: 'MN-9042',
        category: 'Motoniveladoras',
        overallState: OverallState.completed,
        phases: [PhaseState.completed, PhaseState.completed, PhaseState.completed, PhaseState.completed],
        location: 'Sede Buenaventura · Patio 2 (B-08)',
        operatingHours: '2,680 h',
        fuelPercent: 82,
      ),
      timestamp: DateTime(2026, 9, 24, 16, 10),
      duration: '1h 40m',
      supervisor: 'Ing. Carlos Mendoza',
      completedPhases: 4,
      totalPhases: 4,
      photosCount: 4,
      note: 'Se completaron 2 litros de refrigerante 50/50 y se verificó cuchilla vertedera.',
    ),
    HistoryItem(
      machine: const MachineModel(
        id: '2',
        name: 'Komatsu WA470',
        serial: 'KMT458',
        category: 'Cargadores frontales',
        overallState: OverallState.completed,
        phases: [PhaseState.completed, PhaseState.completed, PhaseState.completed, PhaseState.completed],
        location: 'Sede Buenaventura · Patio 1 (C-12)',
        operatingHours: '1,890 h',
        fuelPercent: 90,
      ),
      timestamp: DateTime(2026, 9, 24, 14, 0),
      duration: '1h 10m',
      supervisor: 'Ing. Carlos Mendoza',
      completedPhases: 4,
      totalPhases: 4,
      photosCount: 4,
      note: 'Lavado a presión de orugas y compartimiento de radiador ejecutado con éxito.',
    ),
    HistoryItem(
      machine: const MachineModel(
        id: '4',
        name: 'John Deere 310L',
        serial: 'JD310-992',
        category: 'Retroexcavadoras',
        overallState: OverallState.completed,
        phases: [PhaseState.completed, PhaseState.completed, PhaseState.completed, PhaseState.completed],
        location: 'Sede Buenaventura · Patio 1 (A-05)',
        operatingHours: '3,120 h',
        fuelPercent: 85,
      ),
      timestamp: DateTime(2026, 9, 24, 10, 20),
      duration: '1h 05m',
      supervisor: 'Ing. Carlos Mendoza',
      completedPhases: 4,
      totalPhases: 4,
      photosCount: 4,
      note: 'Inspección de estabilizadores y lubricación de articulaciones terminada.',
    ),

    // 23 Septiembre
    HistoryItem(
      machine: const MachineModel(
        id: '5',
        name: 'Kenworth T800',
        serial: 'KW-8841',
        category: 'Volquetas',
        overallState: OverallState.delivered,
        phases: [PhaseState.completed, PhaseState.completed, PhaseState.completed, PhaseState.completed],
        location: 'Sede Buenaventura · En ruta',
        operatingHours: '5,800 h',
        fuelPercent: 100,
      ),
      timestamp: DateTime(2026, 9, 23, 17, 45),
      duration: '55m',
      supervisor: 'Ing. Carlos Mendoza',
      completedPhases: 4,
      totalPhases: 4,
      photosCount: 4,
      note: 'Despachada a proyecto vial Buenaventura - Buga con remisión firmada.',
    ),
  ];

  List<HistoryItem> get _filteredHistory {
    switch (_selectedFilter) {
      case 'Hoy':
        return _allHistory.where((h) => h.timestamp.day == 25).toList();
      case 'Esta semana':
        return _allHistory;
      case 'Septiembre':
        return _allHistory;
      default:
        return _allHistory;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Cabecera limpia
          _buildHeader(context),

          // 2. Filtros horizontales
          _buildFilterChips(),
          const SizedBox(height: 10),

          // 3. Lista cronológica scrolleable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tarjeta resumen del mes
                  _buildMonthlySummaryCard(),
                  const SizedBox(height: 20),

                  // Bloques cronológicos
                  if (_filteredHistory.isEmpty)
                    _buildEmptyState()
                  else ...[
                    if (_hasDateGroup(25)) ...[
                      _buildDateSectionHeader('Hoy · 25 de Septiembre', _getGroupCount(25)),
                      const SizedBox(height: 10),
                      ..._buildGroupItems(25),
                      const SizedBox(height: 20),
                    ],
                    if (_hasDateGroup(24)) ...[
                      _buildDateSectionHeader('Ayer · 24 de Septiembre', _getGroupCount(24)),
                      const SizedBox(height: 10),
                      ..._buildGroupItems(24),
                      const SizedBox(height: 20),
                    ],
                    if (_hasDateGroup(23)) ...[
                      _buildDateSectionHeader('23 de Septiembre', _getGroupCount(23)),
                      const SizedBox(height: 10),
                      ..._buildGroupItems(23),
                      const SizedBox(height: 20),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (!widget.showScaffold) {
      return bodyContent;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: bodyContent,
      ),
    );
  }

  bool _hasDateGroup(int day) {
    return _filteredHistory.any((h) => h.timestamp.day == day);
  }

  int _getGroupCount(int day) {
    return _filteredHistory.where((h) => h.timestamp.day == day).length;
  }

  List<Widget> _buildGroupItems(int day) {
    final items = _filteredHistory.where((h) => h.timestamp.day == day).toList();
    return items.map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildHistoryCard(item),
      );
    }).toList();
  }

  // --- Cabecera ---
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Historial',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Registros de alistamiento · Sede Buenaventura',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (Navigator.of(context).canPop() && widget.showScaffold)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- Filtros Horizontales ---
  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryNavy : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? AppColors.primaryNavy : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Tarjeta Resumen Mensual ---
  Widget _buildMonthlySummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '38',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Alistamientos en Septiembre',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 38,
            color: const Color(0xFFF1F5F9),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '1h 15m',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tiempo promedio por equipo',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
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

  // --- Encabezado de Sección por Fecha ---
  Widget _buildDateSectionHeader(String dateLabel, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          dateLabel,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$count ${count == 1 ? 'registro' : 'registros'}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // --- Tarjeta de Historial Individual ---
  Widget _buildHistoryCard(HistoryItem item) {
    final m = item.machine;

    // Configuración limpia de etiquetas
    String statusText;
    Color statusBg;
    Color statusColor;

    switch (m.overallState) {
      case OverallState.completed:
        statusText = 'Completado';
        statusBg = const Color(0xFFECFDF5);
        statusColor = const Color(0xFF059669);
        break;
      case OverallState.inProgress:
        statusText = 'En proceso';
        statusBg = const Color(0xFFEFF6FF);
        statusColor = AppColors.accentBlue;
        break;
      case OverallState.delivered:
        statusText = 'Despachado';
        statusBg = const Color(0xFFF1F5F9);
        statusColor = AppColors.textPrimary;
        break;
      default:
        statusText = 'Pendiente';
        statusBg = const Color(0xFFFEF3C7);
        statusColor = const Color(0xFFD97706);
    }

    final hourStr = '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () => _showHistoryDetailModal(context, item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Miniatura real de la máquina
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 64,
                height: 64,
                child: Image.asset(
                  m.displayImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFEFF6FF),
                    child: const Icon(
                      Icons.precision_manufacturing_rounded,
                      color: AppColors.accentBlue,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Información descriptiva del alistamiento
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        m.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${m.category} · Serial: ${m.serial}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Metadata operativa (Hora, Duración, Fases y Fotos)
                  Row(
                    children: [
                      _buildInlineTag(Icons.access_time_rounded, '$hourStr (${item.duration})'),
                      const SizedBox(width: 10),
                      _buildInlineTag(Icons.photo_camera_outlined, '${item.photosCount} fotos'),
                    ],
                  ),
                ],
              ),
            ),

            // Flecha a detalle
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFFCBD5E1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineTag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  // --- Modal de Acta de Inspección / Detalle del Historial ---
  void _showHistoryDetailModal(BuildContext context, HistoryItem item) {
    final m = item.machine;
    final hourStr = '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}';
    final dateStr = '${item.timestamp.day}/${item.timestamp.month}/${item.timestamp.year}';

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
                // Tirador de arrastre
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Acta de alistamiento',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${m.name} · Serial ${m.serial}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
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
                const SizedBox(height: 16),

                // Ficha técnica resumida del acta
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildReceiptRow('Fecha y hora de cierre', '$dateStr · $hourStr'),
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildReceiptRow('Duración del alistamiento', item.duration),
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildReceiptRow('Supervisor validador', item.supervisor),
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildReceiptRow('Fases completadas', '${item.completedPhases} de ${item.totalPhases} requeridas'),
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildReceiptRow('Evidencias fotográficas', '${item.photosCount} fotos anexadas'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Nota del operario
                if (item.note != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes_rounded, size: 16, color: AppColors.accentBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.note!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Botón para ir a la Ficha de la Máquina
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MachineDetailScreen(machine: m),
                      ),
                    );
                  },
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
                    'Ver ficha completa de la máquina',
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

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: const [
          Icon(Icons.history_toggle_off_rounded, size: 48, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text(
            'No hay registros para este filtro',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Prueba seleccionando otro período o "Todos"',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
