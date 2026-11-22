import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../models/trip_model.dart';
import '../providers/transport_provider.dart';
import 'signature_screen.dart';

class DeliveryConfirmationModal extends StatefulWidget {
  final TripModel trip;

  const DeliveryConfirmationModal({
    super.key,
    required this.trip,
  });

  @override
  State<DeliveryConfirmationModal> createState() => _DeliveryConfirmationModalState();
}

class _DeliveryConfirmationModalState extends State<DeliveryConfirmationModal> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _docController = TextEditingController();
  final _roleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  Uint8List? _signatureBytes;
  File? _deliveryPhoto;
  bool _isSubmitting = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _docController.dispose();
    _roleController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _openSignatureScreen() async {
    final bytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => const SignatureScreen(),
        fullscreenDialog: true,
      ),
    );

    if (bytes != null && mounted) {
      setState(() {
        _signatureBytes = bytes;
      });
    }
  }

  Future<void> _pickDeliveryPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() {
          _deliveryPhoto = File(picked.path);
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo capturar la fotografía')),
        );
      }
    }
  }

  Future<File?> _saveSignatureToFile() async {
    if (_signatureBytes == null || _signatureBytes!.isEmpty) return null;
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/pod_sig_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(_signatureBytes!);
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_signatureBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFDC2626),
          content: Text('La firma digital del receptor es obligatoria para validar la entrega.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final signatureFile = await _saveSignatureToFile();
      if (signatureFile == null) throw StateError('No se pudo guardar la firma. Intenta de nuevo.');
      if (!mounted) return;
      final provider = context.read<TransportProvider>();

      final success = await provider.completeDeliveryWithPod(
        machineId: widget.trip.machineId,
        tripId: widget.trip.id,
        receiverName: _nameController.text.trim(),
        receiverDocument: _docController.text.trim(),
        receiverRole: _roleController.text.trim(),
        receiverPhone: _phoneController.text.trim(),
        notes: _notesController.text.trim(),
        signatureFile: signatureFile,
        deliveryPhotoFile: _deliveryPhoto,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF15803D),
              content: Text('¡Acta de entrega firmada y maquinaria entregada a conformidad!'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFDC2626),
              content: Text(provider.errorMessage ?? 'Error al registrar entrega'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text('Error al procesar acta: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final machine = widget.trip.machine;
    final mediaQuery = MediaQuery.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        child: SizedBox(
          height: mediaQuery.size.height * 0.88 - mediaQuery.viewInsets.bottom,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Confirmar entrega', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
                  Text(machine?.serial ?? 'Maquinaria', style: const TextStyle(color: AppColors.textSecondary)),
                ])),
                IconButton(tooltip: 'Cerrar', onPressed: _isSubmitting ? null : () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(widget.trip.destination, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                const SizedBox(height: 24),
                const Text('Persona que recibe', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextFormField(controller: _nameController, decoration: _inputDecoration(label: 'Nombre completo', hint: ''),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa el nombre' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _docController, keyboardType: TextInputType.text,
                  decoration: _inputDecoration(label: 'Documento', hint: ''),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa el documento' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _roleController, decoration: _inputDecoration(label: 'Cargo (opcional)', hint: '')),
                const SizedBox(height: 16),
                TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: _inputDecoration(label: 'Teléfono (opcional)', hint: '')),
                const SizedBox(height: 28),
                Row(children: [
                  const Expanded(child: Text('Firma de quien recibe', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
                  if (_signatureBytes != null) TextButton(onPressed: _isSubmitting ? null : _openSignatureScreen, child: const Text('Volver a firmar')),
                ]),
                const SizedBox(height: 12),
                if (_signatureBytes != null)
                  Container(
                    height: 180, padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(10)),
                    child: Image.memory(_signatureBytes!, fit: BoxFit.contain, gaplessPlayback: true),
                  )
                else
                  OutlinedButton.icon(onPressed: _isSubmitting ? null : _openSignatureScreen,
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(64)),
                    icon: const Icon(Icons.draw_outlined), label: const Text('Agregar firma')),
                const SizedBox(height: 28),
                const Text('Foto de entrega (opcional)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (_deliveryPhoto != null) ...[
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_deliveryPhoto!, height: 180, fit: BoxFit.cover)),
                  TextButton(onPressed: () => setState(() => _deliveryPhoto = null), child: const Text('Quitar foto')),
                ],
                Wrap(spacing: 12, children: [
                  OutlinedButton.icon(onPressed: _isSubmitting ? null : () => _pickDeliveryPhoto(ImageSource.camera), icon: const Icon(Icons.camera_alt_outlined), label: const Text('Tomar foto')),
                  TextButton.icon(onPressed: _isSubmitting ? null : () => _pickDeliveryPhoto(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text('Galería')),
                ]),
                const SizedBox(height: 24),
                TextFormField(controller: _notesController, maxLines: 3, decoration: _inputDecoration(label: 'Observaciones (opcional)', hint: '')),
              ])),
            )),
            Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 16), child: SizedBox(
              width: double.infinity, height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.accentBlue),
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Confirmar entrega'),
              ),
            )),
          ]),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, required String hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
    );
  }
}
