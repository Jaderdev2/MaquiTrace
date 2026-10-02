import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../models/machine_model.dart';

class MachineDetailScreen extends StatefulWidget {
  final MachineModel machine;

  const MachineDetailScreen({
    super.key,
    required this.machine,
  });

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  // Simulación de fotos tomadas por el operario
  final Map<int, bool> _photoUploaded = {
    0: true,  // Frontal
    1: true,  // Lateral
    2: true,  // Cabina
    3: false, // Motor (pendiente)
  };

  @override
  Widget build(BuildContext context) {
    final m = widget.machine;

    // Configuración de estado
    String statusLabel;
    Color statusColor;
    Color statusBg;
    Color statusBorder;

    switch (m.overallState) {
      case OverallState.inProgress:
        statusLabel = 'En alistamiento';
        statusColor = AppColors.accentBlue;
        statusBg = const Color(0xFFEFF6FF);
        statusBorder = const Color(0xFFDBEAFE);
        break;
      case OverallState.pending:
        statusLabel = 'Pendiente de inicio';
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFEF3C7);
        statusBorder = const Color(0xFFFDE68A);
        break;
      case OverallState.completed:
        statusLabel = 'Lista para despacho';
        statusColor = const Color(0xFF059669);
        statusBg = const Color(0xFFECFDF5);
        statusBorder = const Color(0xFFA7F3D0);
        break;
      case OverallState.inTransit:
        statusLabel = 'En tránsito a obra';
        statusColor = const Color(0xFF2563EB);
        statusBg = const Color(0xFFDBEAFE);
        statusBorder = const Color(0xFFBFDBFE);
        break;
      case OverallState.delivered:
        statusLabel = 'Entregada en sitio';
        statusColor = const Color(0xFF059669);
        statusBg = const Color(0xFFECFDF5);
        statusBorder = const Color(0xFFA7F3D0);
        break;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. Barra de navegación superior
              _buildTopBar(context, m),

              // 2. Contenido scrolleable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tarjeta Hero con datos principales de la máquina
                      _buildHeroCard(m, statusLabel, statusColor, statusBg, statusBorder),
                      const SizedBox(height: 18),

                      // Ficha técnica rápida (Métricas operativas)
                      _buildTechnicalSpecsGrid(m),
                      const SizedBox(height: 22),

                      // Fases del Proceso de Alistamiento
                      _buildPhasesTimelineSection(m),
                      const SizedBox(height: 22),

                      // Evidencias fotográficas requeridas
                      _buildEvidenceSection(),
                      const SizedBox(height: 22),

                      // Novedades y observaciones técnicas
                      _buildNotesSection(m),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. Barra de acciones inferior fija
        bottomNavigationBar: _buildStickyBottomBar(context, m),
      ),
    );
  }

  // --- Barra superior limpia ---
  Widget _buildTopBar(BuildContext context, MachineModel machine) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón volver
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
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

          // Título central
          Column(
            children: [
              const Text(
                'Detalle de máquina',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Serial: ${machine.serial}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),

          // Botón ver código QR
          GestureDetector(
            onTap: () => _showMachineQrModal(context, machine),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Tarjeta Hero Principal ---
  Widget _buildHeroCard(
    MachineModel machine,
    String statusLabel,
    Color statusColor,
    Color statusBg,
    Color statusBorder,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Foto de la máquina con badge de categoría superpuesto
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Image.asset(
                    machine.displayImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFEFF6FF),
                        child: const Center(
                          child: Icon(
                            Icons.precision_manufacturing_rounded,
                            size: 48,
                            color: AppColors.accentBlue,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Píldora de Categoría
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xD90F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    machine.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Información descriptiva
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            machine.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Modelo ${machine.modelYear} · Serial: ${machine.serial}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge de Estado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusBorder),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Separador tenue
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Ubicación física en patio
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        machine.location,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Ficha Técnica Rápida (4 Métricas Clave) ---
  Widget _buildTechnicalSpecsGrid(MachineModel machine) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ficha técnica y operatividad',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSpecCard(
                icon: Icons.timer_outlined,
                label: 'Horómetro',
                value: machine.operatingHours,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSpecCard(
                icon: Icons.local_gas_station_outlined,
                label: 'Combustible',
                value: '${machine.fuelPercent}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSpecCard(
                icon: Icons.bolt_rounded,
                label: 'Batería',
                value: '24.2 V (Óptima)',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSpecCard(
                icon: Icons.person_outline_rounded,
                label: 'A cargo',
                value: machine.assignedOperator,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: AppColors.primaryNavy),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Línea de Tiempo de Fases de Alistamiento ---
  Widget _buildPhasesTimelineSection(MachineModel machine) {
    // 4 fases estándar en el flujo operativo de MaquiTrace
    final List<Map<String, dynamic>> phasesData = [
      {
        'phase': 1,
        'title': 'Inspección inicial y fluidos',
        'desc': 'Nivel de aceite, refrigerante, estado de mangueras y batería.',
        'state': PhaseState.completed,
        'detail': 'Completado por Jhon R. · 08:30 AM',
      },
      {
        'phase': 2,
        'title': 'Lavado y descontaminación',
        'desc': 'Desengrase de motor, orugas, chasis y cabina del operador.',
        'state': machine.overallState == OverallState.pending
            ? PhaseState.pending
            : PhaseState.completed,
        'detail': machine.overallState == OverallState.pending
            ? 'Pendiente de inicio'
            : 'Completado · 09:45 AM',
      },
      {
        'phase': 3,
        'title': 'Pruebas funcionales y torque',
        'desc': 'Mandos finales, sistema hidráulico, torque de pernos de oruga.',
        'state': machine.overallState == OverallState.completed
            ? PhaseState.completed
            : (machine.overallState == OverallState.pending
                ? PhaseState.pending
                : PhaseState.inProgress),
        'detail': machine.overallState == OverallState.completed
            ? 'Completado · 11:15 AM'
            : (machine.overallState == OverallState.pending
                ? 'Pendiente'
                : 'En ejecución por el operario'),
      },
      {
        'phase': 4,
        'title': 'Registro de evidencias y firma',
        'desc': 'Toma de 4 fotografías obligatorias y validación de entrega.',
        'state': machine.overallState == OverallState.completed
            ? PhaseState.completed
            : PhaseState.pending,
        'detail': machine.overallState == OverallState.completed
            ? 'Aprobado y sellado'
            : 'Falta 1 evidencia fotográfica',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fases de alistamiento',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  machine.overallState == OverallState.completed
                      ? '4 / 4 Completadas'
                      : (machine.overallState == OverallState.pending
                          ? '0 / 4 Iniciadas'
                          : '2 / 4 Completadas'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Timeline items
          ...List.generate(phasesData.length, (index) {
            final p = phasesData[index];
            final isLast = index == phasesData.length - 1;
            return _buildTimelinePhaseRow(
              phaseNumber: p['phase'] as int,
              title: p['title'] as String,
              desc: p['desc'] as String,
              detail: p['detail'] as String,
              state: p['state'] as PhaseState,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelinePhaseRow({
    required int phaseNumber,
    required String title,
    required String desc,
    required String detail,
    required PhaseState state,
    required bool isLast,
  }) {
    Color indicatorBg;
    Widget indicatorChild;

    switch (state) {
      case PhaseState.completed:
        indicatorBg = AppColors.primaryNavy;
        indicatorChild = const Icon(Icons.check_rounded, size: 14, color: Colors.white);
        break;
      case PhaseState.inProgress:
        indicatorBg = AppColors.accentBlue;
        indicatorChild = Text(
          '$phaseNumber',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        );
        break;
      case PhaseState.pending:
        indicatorBg = const Color(0xFFE2E8F0);
        indicatorChild = Text(
          '$phaseNumber',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        );
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna del indicador y la línea vertical
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: indicatorBg,
                  shape: BoxShape.circle,
                ),
                child: Center(child: indicatorChild),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Contenido de la fase
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: state == PhaseState.pending
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: state == PhaseState.inProgress
                          ? AppColors.accentBlue
                          : AppColors.textMuted,
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

  // --- Sección de Evidencias Fotográficas ---
  Widget _buildEvidenceSection() {
    final List<Map<String, dynamic>> photos = [
      {'index': 0, 'label': '1. Frente y cuchara'},
      {'index': 1, 'label': '2. Oruga izquierda'},
      {'index': 2, 'label': '3. Cabina interior'},
      {'index': 3, 'label': '4. Motor / Fluidos'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Evidencias fotográficas',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                '3 / 4 registradas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Grilla 2x2 de fotos requeridas
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, i) {
              final isUploaded = _photoUploaded[i] ?? false;
              final label = photos[i]['label'] as String;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _photoUploaded[i] = !isUploaded;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isUploaded
                            ? 'Evidencia eliminada'
                            : 'Foto capturada para: $label',
                      ),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isUploaded ? const Color(0xFFF8FAFC) : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUploaded ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (isUploaded)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: SizedBox.expand(
                            child: Image.asset(
                              'assets/images/maqui_trace_bg.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      // Overlay o placeholder
                      if (!isUploaded)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 22,
                                color: AppColors.textMuted,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tomar foto',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Barra inferior de texto
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isUploaded
                                ? const Color(0xCC0F172A)
                                : const Color(0xFFF1F5F9),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(11),
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isUploaded ? Colors.white : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Observaciones técnicas del turno ---
  Widget _buildNotesSection(MachineModel machine) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.notes_rounded, size: 18, color: AppColors.primaryNavy),
              SizedBox(width: 8),
              Text(
                'Observaciones de campo',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              machine.notes ??
                  'Equipo en óptimas condiciones de estructura y mandos hidráulicos. Se completaron 2 litros de refrigerante 50/50 y se verificó tensión de orugas.',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Barra Inferior Fija de Acción ---
  Widget _buildStickyBottomBar(BuildContext context, MachineModel machine) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Botón secundario: Reportar novedad
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Formulario de novedad técnica abierto'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Icon(
              Icons.flag_outlined,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),

          // Botón primario: Continuar Alistamiento
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Alistamiento de ${machine.name} en curso'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.assignment_turned_in_outlined, size: 20),
              label: const Text(
                'Continuar alistamiento',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Modal para Código QR de la Máquina ---
  void _showMachineQrModal(BuildContext context, MachineModel machine) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Identificador QR de Máquina',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${machine.name} · Serial ${machine.serial}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Contenedor visual del QR
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.qr_code_2_rounded,
                        size: 150,
                        color: AppColors.primaryNavy,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'MAQUITRACE-ID-${machine.serial}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
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
                      'Cerrar',
                      style: TextStyle(fontWeight: FontWeight.w700),
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
