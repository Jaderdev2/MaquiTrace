import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../history/screens/history_screen.dart';

/// Colores y medidas compartidas con el resto de pantallas del flujo.
/// Un solo radio, bordes de 1 px y color solo cuando comunica estado.
class _Ui {
  static const background = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFEDF1F5);
  static const handle = Color(0xFFCBD5E1);
  static const locked = Color(0xFF64748B);
  static const danger = Color(0xFFDC2626);

  static const double radius = 10;
  static const double pagePadding = 16;
}

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
  bool _biometricAuth = true;

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    final content = SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          _Ui.pagePadding,
          18,
          _Ui.pagePadding,
          100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera
            const Text(
              'Perfil',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Ficha técnica del operario',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Identidad del operario
            _buildIdentityCard(),
            const SizedBox(height: 28),

            // Sección 1: cuenta
            _buildSectionTitle('Datos de la cuenta'),
            const SizedBox(height: 10),
            _buildGroup([
              _buildTile(
                icon: Icons.alternate_email_rounded,
                title: 'Correo corporativo',
                value: user != null && user.email.isNotEmpty
                    ? user.email
                    : 'operario@maquitrace.com',
              ),
              _buildTile(
                icon: Icons.phone_outlined,
                title: 'Teléfono de contacto',
                value: user?.phone != null && user!.phone!.isNotEmpty
                    ? user.phone!
                    : 'No registrado',
              ),
              _buildTile(
                icon: Icons.location_on_outlined,
                title: 'Sede operativa',
                value: 'Sede Buenaventura · Valle del Cauca',
                onTap: () => _showDetailSheet(
                  title: 'Sede y asignación',
                  body:
                      'Sede Puerto Buenaventura (Terminal Portuario / Vía Alterna Interna).\nJefe de Operaciones: Ing. Carlos Mendoza.\nTurno activo: 07:00 - 16:00 (Lunes a Sábado).',
                ),
              ),
              _buildTile(
                icon: Icons.history_rounded,
                title: 'Historial de alistamientos',
                value: 'Ver registros anteriores',
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

            // Sección 2: seguridad y soporte
            _buildSectionTitle('Seguridad y soporte'),
            const SizedBox(height: 10),
            _buildGroup([
              _buildSwitchRow(
                icon: Icons.fingerprint_rounded,
                title: 'Acceso biométrico',
                subtitle: 'Ingreso rápido con huella o reconocimiento facial',
                value: _biometricAuth,
                onChanged: (val) => setState(() => _biometricAuth = val),
              ),
              _buildTile(
                icon: Icons.support_agent_rounded,
                title: 'Contactar a supervisor de turno',
                value: 'Ing. Carlos Mendoza',
                onTap: _showContactSupervisorSheet,
              ),
              _buildTile(
                icon: Icons.menu_book_outlined,
                title: 'Manual de alistamiento de maquinaria',
                value: 'Protocolos PDF v2.4',
                onTap: () => _showDetailSheet(
                  title: 'Manual de protocolos',
                  body:
                      'El manual contiene las listas de chequeo oficiales para las fases de Ensamblaje, Lavado y Pintura, junto con los ángulos fotográficos obligatorios.',
                ),
              ),
            ]),
            const SizedBox(height: 32),

            _buildLogoutTile(),
            const SizedBox(height: 16),

            const Center(
              child: Text(
                'MaquiTrace Mobile · v1.0.0 (Build 104)',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
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
      backgroundColor: _Ui.background,
      body: content,
    );
  }

  // --- Identidad: avatar, nombre, rol y datos de credencial ---
  Widget _buildIdentityCard() {
    final user = context.watch<AuthProvider>().currentUser;
    final userName = user != null && user.name.isNotEmpty ? user.name : 'Operario';
    final userRole = user != null && user.role.trim().isNotEmpty
        ? _capitalize(user.role.trim())
        : 'Operario de alistamiento';
    final initials = userName
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();
    final identifier = user != null && user.id.isNotEmpty
        ? (user.id.length >= 8
            ? user.id.substring(0, 8).toUpperCase()
            : user.id.toUpperCase())
        : 'OP-ACTIVO';

    return Container(
      decoration: BoxDecoration(
        color: _Ui.surface,
        borderRadius: BorderRadius.circular(_Ui.radius),
        border: Border.all(color: _Ui.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryNavy,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials.isNotEmpty ? initials : 'OP',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userRole,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _Ui.divider),
          _buildInfoRow('Identificador', identifier),
          const Divider(height: 1, color: _Ui.divider),
          _buildInfoRow('Sede asignada', 'Buenaventura'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  // Lista agrupada: intercala divisores entre filas
  Widget _buildGroup(List<Widget> rows) {
    return Material(
      color: _Ui.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_Ui.radius),
        side: const BorderSide(color: _Ui.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 54, color: _Ui.divider),
            rows[i],
          ],
        ],
      ),
    );
  }

  // Fila de dato o enlace; el chevron aparece solo si se puede tocar
  Widget _buildTile({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, size: 22, color: _Ui.locked),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.accentBlue,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: _Ui.handle,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutTile() {
    return Material(
      color: _Ui.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_Ui.radius),
        side: const BorderSide(color: _Ui.border),
      ),
      child: InkWell(
        onTap: _showLogoutConfirmSheet,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 20, color: _Ui.danger),
              SizedBox(width: 8),
              Text(
                'Cerrar sesión',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _Ui.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Sheets ----------

  // Sheet base: tirador, padding y scroll con el mismo estilo del resto de la app
  Future<void> _showSheet(Widget Function(BuildContext ctx) content) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _Ui.handle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              content(ctx),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _filledStyle(Color color) {
    return FilledButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_Ui.radius),
      ),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }

  ButtonStyle get _outlinedStyle {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      minimumSize: const Size.fromHeight(48),
      side: const BorderSide(color: _Ui.handle),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_Ui.radius),
      ),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }

  void _showDetailSheet({required String title, required String body}) {
    _showSheet(
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: _filledStyle(AppColors.accentBlue),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showContactSupervisorSheet() {
    _showSheet(
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Supervisor de turno',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ing. Carlos Mendoza · Operaciones Sede Buenaventura',
            style: TextStyle(
              fontSize: 14,
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
                  icon: const Icon(Icons.phone_outlined, size: 20),
                  label: const Text('Llamar'),
                  style: _outlinedStyle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _showFeedback('Abriendo chat interno...');
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                  label: const Text('Mensaje'),
                  style: _filledStyle(AppColors.accentBlue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmSheet() {
    _showSheet(
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '¿Cerrar sesión?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Deberás ingresar tus credenciales nuevamente para acceder.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: _outlinedStyle,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final authProvider = context.read<AuthProvider>();
                    final navigator = Navigator.of(context);
                    Navigator.of(ctx).pop();
                    await authProvider.logout();
                    if (mounted) {
                      navigator.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  style: _filledStyle(_Ui.danger),
                  child: const Text('Cerrar sesión'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFeedback(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.accentBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}