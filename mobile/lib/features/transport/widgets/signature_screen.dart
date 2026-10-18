import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'signature_pad.dart';

class SignatureScreen extends StatefulWidget {
  const SignatureScreen({super.key});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final GlobalKey<SignaturePadState> _padKey = GlobalKey<SignaturePadState>();
  bool _hasSignature = false;

  Future<void> _handleAccept() async {
    if (!_hasSignature) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFDC2626),
          content: Text('Por favor estampe su firma antes de continuar'),
        ),
      );
      return;
    }

    final bytes = await _padKey.currentState?.exportPngBytes(width: 600, height: 350);
    if (mounted && bytes != null) {
      Navigator.of(context).pop(bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Firma Digital de Recepción',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Firme cómodamente con el dedo en toda el área blanca',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          if (_hasSignature)
            TextButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
              label: const Text('Limpiar', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              onPressed: () {
                _padKey.currentState?.clear();
                setState(() => _hasSignature = false);
              },
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Área de lienzo de firma a pantalla completa
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SignaturePad(
                  key: _padKey,
                  height: double.infinity,
                  onSignatureChanged: (has) {
                    setState(() => _hasSignature = has);
                  },
                ),
              ),
            ),

            // Barra inferior con botón de confirmación
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF15803D),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: const Text(
                        'Guardar Firma',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      onPressed: _hasSignature ? _handleAccept : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
