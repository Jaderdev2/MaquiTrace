import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../models/trip_model.dart';
import '../providers/transport_provider.dart';
import 'location_map_picker.dart';

class EditTripModal extends StatefulWidget {
  final TripModel trip;

  const EditTripModal({
    super.key,
    required this.trip,
  });

  @override
  State<EditTripModal> createState() => _EditTripModalState();
}

class _EditTripModalState extends State<EditTripModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _destinationController;
  late final TextEditingController _vehicleController;
  bool _isSaving = false;

  static final RegExp _coordsRegex = RegExp(r'\s*\((-?\d+\.?\d*),\s*(-?\d+\.?\d*)\)');

  static String _cleanDestination(String destination) {
    final clean = destination.replaceAll(_coordsRegex, '').trim();
    return clean.isEmpty ? 'Punto seleccionado en el mapa' : clean;
  }

  @override
  void initState() {
    super.initState();
    _destinationController = TextEditingController(text: _cleanDestination(widget.trip.destination));
    _vehicleController = TextEditingController(text: widget.trip.vehicle);
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<TransportProvider>();

    final success = await provider.updateTripDetails(
      tripId: widget.trip.id,
      destination: _destinationController.text.trim(),
      vehicle: _vehicleController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
            content: Text('Detalles de la ruta actualizados'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            content: Text(provider.errorMessage ?? 'Error al actualizar detalles'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Manija superior de arrastre
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Cabecera
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit_location_alt_rounded, color: AppColors.accentBlue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Modificar detalles de ruta',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Actualiza el destino o remolque asignado',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Destino de entrega
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Destino de entrega *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accentBlue,
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text('Elegir en el mapa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      onPressed: () async {
                        final picked = await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                            builder: (_) => LocationMapPicker(initialDestination: _destinationController.text),
                          ),
                        );
                        if (picked != null && picked.trim().isNotEmpty) {
                          setState(() {
                            _destinationController.text = _cleanDestination(picked);
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _destinationController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Ej. Obra Muelle 13 · Vía Buenaventura',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Icon(Icons.place_outlined, size: 20, color: AppColors.textSecondary),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Ingresa la dirección o punto de destino';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Remolque / Vehículo
                const Text(
                  'Vehículo / Cama baja de remolque *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _vehicleController,
                  decoration: InputDecoration(
                    hintText: 'Ej. Cama Baja KEN-452',
                    prefixIcon: const Icon(Icons.local_shipping_outlined, size: 20, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Ingresa el remolque o camión';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accentBlue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isSaving ? null : _handleSave,
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Guardar cambios', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
