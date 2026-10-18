import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../models/trip_model.dart';
import '../providers/transport_provider.dart';
import 'signature_pad.dart';

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
  final _signatureKey = GlobalKey<SignaturePadState>();

  final _nameController = TextEditingController();
  final _docController = TextEditingController();
  final _roleController = TextEditingController(text: 'Residente de obra');
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  File? _deliveryPhoto;
  bool _hasSignature = false;
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

  Future<void> _pickDeliveryPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _deliveryPhoto = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo capturar la fotografía')),
        );
      }
    }
  }

  Future<File?> _saveSignatureToFile() async {
    try {
      final bytes = await _signatureKey.currentState?.exportPngBytes();
      if (bytes == null || bytes.isEmpty) return null;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/pod_signature_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_hasSignature) {
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

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            // Cabecera fija
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5EC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF15803D), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Acta Oficial de Entrega (POD)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${machine?.model ?? "Maquinaria"} · Serial ${machine?.serial ?? "N/A"}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Cuerpo desplazable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Banner informativo de destino
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.place_outlined, color: AppColors.accentBlue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.trip.destination,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // SECCIÓN 1: DATOS DE QUIEN RECIBE
                      const Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textPrimary),
                          SizedBox(width: 6),
                          Text(
                            '1. Datos de quien recibe en obra',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Nombre
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration(
                          label: 'Nombre y apellido de quien recibe *',
                          hint: 'Ej. Ing. Carlos Mendoza',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el nombre del receptor' : null,
                      ),
                      const SizedBox(height: 10),

                      // Cédula y Cargo en fila
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _docController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration(
                                label: 'Cédula / Documento *',
                                hint: 'Ej. 1114829302',
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _roleController,
                              decoration: _inputDecoration(
                                label: 'Cargo / Rol',
                                hint: 'Residente / Jefe patio',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Teléfono
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          label: 'Teléfono de contacto (opcional)',
                          hint: 'Ej. 315 889 0012',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // SECCIÓN 2: FIRMA DIGITAL CON EL DEDO
                      const Row(
                        children: [
                          Icon(Icons.draw_rounded, size: 18, color: AppColors.textPrimary),
                          SizedBox(width: 6),
                          Text(
                            '2. Firma del receptor (Con el dedo) *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pídele a la persona que recibe la máquina que estampe su firma digital:',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),

                      SignaturePad(
                        key: _signatureKey,
                        height: 150,
                        onSignatureChanged: (has) {
                          setState(() => _hasSignature = has);
                        },
                      ),
                      const SizedBox(height: 20),

                      // SECCIÓN 3: FOTOGRAFÍA DE ENTREGA
                      const Row(
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 18, color: AppColors.textPrimary),
                          SizedBox(width: 6),
                          Text(
                            '3. Fotografía de entrega en obra',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Foto de respaldo del equipo descargado en su sitio final:',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),

                      if (_deliveryPhoto != null) ...[
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _deliveryPhoto!,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: InkWell(
                                onTap: () => setState(() => _deliveryPhoto = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textPrimary,
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  minimumSize: const Size.fromHeight(42),
                                ),
                                icon: const Icon(Icons.photo_camera_rounded, size: 18),
                                label: const Text('Tomar foto', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                onPressed: () => _pickDeliveryPhoto(ImageSource.camera),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textPrimary,
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  minimumSize: const Size.fromHeight(42),
                                ),
                                icon: const Icon(Icons.photo_library_outlined, size: 18),
                                label: const Text('Galería', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                onPressed: () => _pickDeliveryPhoto(ImageSource.gallery),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],

                      // SECCIÓN 4: OBSERVACIONES
                      const Text(
                        'Observaciones o estado de entrega',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: _inputDecoration(
                          label: 'Novedades / Horómetro / Combustible',
                          hint: 'Ej. Maquinaria recibida a entera conformidad. Sin daños de transporte.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Botones de acción inferiores
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
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
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
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
                      icon: _isSubmitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.verified_rounded, size: 20),
                      label: Text(
                        _isSubmitting ? 'Registrando...' : 'Firmar y Finalizar Entrega',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: _isSubmitting ? null : _handleSubmit,
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
