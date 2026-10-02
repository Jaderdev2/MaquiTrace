import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/screens/login_screen.dart';
import '../../history/screens/history_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool showScaffold;
  final ValueChanged<int>? onNavigateToTab;

  const ProfileScreen({
    super.key,
    this.showScaffold = true,
    this.onNavigateToTab,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _autoSyncOffline = true;
  bool _highQualityPhotos = false;
  bool _biometricAuth = true;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera sobria y profesional
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Perfil',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.6,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Ficha técnica del operario',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                // Botón discreto para ver credencial QR
                GestureDetector(
                  onTap: _showDigitalCredentialModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_2_rounded,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Credencial',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tarjeta Credencial Industrial (Navy + Azul corporativo MaquiTrace)
            _buildIndustrialCredentialCard(),
            const SizedBox(height: 16),

            // Métricas de Rendimiento en Patio (Monocromáticas y sobrias)
            _buildYardMetricsRow(),
            const SizedBox(height: 28),

            // Sección 1: Ficha del Operario y Patio
            _buildSectionTitle('OPERACIÓN Y PATIO'),
            const SizedBox(height: 10),
            _buildSettingsContainer([
              _buildSimpleTile(
                icon: Icons.badge_outlined,
                title: 'Documento de identidad',
                value: 'CC 1.020.485.912',
                onTap: null,
              ),
              _buildDivider(),
              _buildSimpleTile(
                icon: Icons.location_on_outlined,
                title: 'Sede operativa',
                value: 'Sede Buenaventura · Valle del Cauca',
                onTap: () => _showDetailModal(
                  title: 'Sede y Asignación',
                  body:
                      'Sede Puerto Buenaventura (Terminal Portuario / Vía Alterna Interna).\nJefe de Operaciones: Ing. Carlos Mendoza.\nTurno activo: 07:00 - 16:00 (Lunes a Sábado).',
                ),
              ),
              _buildDivider(),
              _buildSimpleTile(
                icon: Icons.verified_outlined,
                title: 'Licencia técnica de alistamiento',
                value: 'CAT / Komatsu · Vence Dic 2026',
                onTap: () => _showDetailModal(
                  title: 'Certificación Técnica',
                  body:
                      'Operador certificado para inspección de sistemas hidráulicos, prueba de estanqueidad y alistamiento mecánico nivel 2 según normativa técnica nacional.',
                ),
              ),
              _buildDivider(),
              _buildSimpleTile(
                icon: Icons.history_rounded,
                title: 'Historial de alistamientos',
                value: 'Ver registros anteriores',
                isAction: true,
                onTap: () {
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(3); // Ir a pestaña de Historial
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HistoryScreen(showScaffold: true),
                      ),
                    );
                  }
                },
              ),
            ]),
            const SizedBox(height: 28),

            // Sección 2: Ajustes de Alistamiento y Sincronización
            _buildSectionTitle('SINCRONIZACIÓN Y EVIDENCIA EN PATIO'),
            const SizedBox(height: 10),
            _buildSettingsContainer([
              _buildSwitchRow(
                icon: Icons.cloud_sync_outlined,
                title: 'Sincronización en segundo plano',
                subtitle: 'Sube fotos automáticamente al conectar con red estable',
                value: _autoSyncOffline,
                onChanged: (val) => setState(() => _autoSyncOffline = val),
              ),
              _buildDivider(),
              _buildSwitchRow(
                icon: Icons.hd_outlined,
                title: 'Fotos en alta resolución',
                subtitle: 'Mayor detalle visual para reportes de ensamblaje y pintura',
                value: _highQualityPhotos,
                onChanged: (val) => setState(() => _highQualityPhotos = val),
              ),
              _buildDivider(),
              _buildSwitchRow(
                icon: Icons.notifications_none_rounded,
                title: 'Alertas de nueva maquinaria',
                subtitle: 'Notificar en tiempo real cuando ingrese un equipo al patio',
                value: _notifications,
                onChanged: (val) => setState(() => _notifications = val),
              ),
            ]),
            const SizedBox(height: 28),

            // Sección 3: Seguridad y Sistema
            _buildSectionTitle('SEGURIDAD Y SOPORTE'),
            const SizedBox(height: 10),
            _buildSettingsContainer([
              _buildSwitchRow(
                icon: Icons.fingerprint_rounded,
                title: 'Acceso biométrico',
                subtitle: 'Ingreso rápido con huella o reconocimiento facial',
                value: _biometricAuth,
                onChanged: (val) => setState(() => _biometricAuth = val),
              ),
              _buildDivider(),
              _buildSimpleTile(
                icon: Icons.support_agent_rounded,
                title: 'Contactar a supervisor de turno',
                value: 'Ing. Carlos Mendoza',
                isAction: true,
                onTap: _showContactSupervisorModal,
              ),
              _buildDivider(),
              _buildSimpleTile(
                icon: Icons.menu_book_outlined,
                title: 'Manual de alistamiento de maquinaria',
                value: 'Protocolos PDF v2.4',
                isAction: true,
                onTap: () => _showDetailModal(
                  title: 'Manual de Protocolos',
                  body:
                      'El manual contiene las listas de chequeo oficiales para las fases de Ensamblaje, Pintura y Lavado, junto con los ángulos fotográficos obligatorios.',
                ),
              ),
            ]),
            const SizedBox(height: 32),

            // Botón de Cerrar Sesión (Sobrio, fondo gris claro con acento rojo mínimo)
            _buildLogoutTile(),
            const SizedBox(height: 16),

            // Versión de la App al pie
            const Center(
              child: Text(
                'MaquiTrace Mobile · v1.0.0 (Build 104)',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
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

  // Tarjeta Credencial Industrial en Azul Marino MaquiTrace
  Widget _buildIndustrialCredentialCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Marca de agua sutil en esquina
          Positioned(
            right: -16,
            bottom: -16,
            child: Icon(
              Icons.agriculture_rounded,
              size: 130,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila superior: Credencial digital y Empresa
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CREDENCIAL DIGITAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      'MAQUITRACE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Datos del Operario
                Row(
                  children: [
                    // Avatar con foto o iniciales con reborde azul sutil
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accentBlue,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'JR',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Jhon Fredy Restrepo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Operario de Alistamiento',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Separador tenue
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 14),

                // Fila inferior de credencial: Código y Sede
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CÓDIGO DE OPERARIO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'OP-0482',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'SEDE ASIGNADA',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Buenaventura',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
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

  // Fila de Métricas limpia y sin colores estridentes
  Widget _buildYardMetricsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricColumn('48', 'Alistamientos'),
          _buildMetricDivider(),
          _buildMetricColumn('98.4%', 'Cumplimiento'),
          _buildMetricDivider(),
          _buildMetricColumn('164', 'Evidencias'),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      width: 1,
      height: 26,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 52,
      color: Color(0xFFF1F5F9),
    );
  }

  // Fila simple monocromática para datos y enlaces
  Widget _buildSimpleTile({
    required IconData icon,
    required String title,
    required String value,
    bool isAction = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF475569)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isAction ? FontWeight.w600 : FontWeight.w400,
                      color: isAction ? AppColors.accentBlue : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isAction)
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
          ],
        ),
      ),
    );
  }

  // Fila para switches de configuración
  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF475569)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.accentBlue,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFCBD5E1),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  // Botón de Cerrar Sesión profesional y sin estridencias
  Widget _buildLogoutTile() {
    return InkWell(
      onTap: _showLogoutConfirmDialog,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              size: 18,
              color: Color(0xFFDC2626),
            ),
            SizedBox(width: 8),
            Text(
              'Cerrar sesión',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modal para ver credencial digital QR de operario
  void _showDigitalCredentialModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Credencial de Acceso a Patio',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Presenta este código para registrar tu ingreso o firmar entregas de maquinaria.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Contenedor del código QR
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: const [
                    Icon(
                      Icons.qr_code_2_rounded,
                      size: 140,
                      color: AppColors.primaryNavy,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'OP-0482 · JHON FREDY RESTREPO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Listo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDetailModal({required String title, required String body}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showContactSupervisorModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Supervisor de Turno',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ing. Carlos Mendoza · Operaciones Sede Buenaventura',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _showFeedback('Llamando a supervisor...');
                      },
                      icon: const Icon(Icons.phone_outlined, size: 18),
                      label: const Text('Llamar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        foregroundColor: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _showFeedback('Abriendo chat interno...');
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      label: const Text('Mensaje'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
  }

  void _showLogoutConfirmDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '¿Cerrar sesión?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Deberás ingresar tus credenciales nuevamente para acceder.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cerrar sesión',
                        style: TextStyle(fontWeight: FontWeight.w700),
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
  }

  void _showFeedback(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primaryNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
