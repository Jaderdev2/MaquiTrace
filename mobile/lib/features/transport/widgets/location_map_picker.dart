import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../core/theme/app_colors.dart';

class LocationMapPicker extends StatefulWidget {
  final String? initialDestination;

  const LocationMapPicker({
    super.key,
    this.initialDestination,
  });

  @override
  State<LocationMapPicker> createState() => _LocationMapPickerState();
}

class _LocationMapPickerState extends State<LocationMapPicker> {
  final MapController _mapController = MapController();
  late ll.LatLng _currentCenter;
  final TextEditingController _customNameController = TextEditingController();

  final List<Map<String, dynamic>> _presetLocations = [
    {
      'title': 'Buenaventura · Patio Portuario',
      'lat': 3.8833,
      'lng': -77.0167,
    },
    {
      'title': 'Loboguerrero · Cruce Vía al Mar',
      'lat': 3.7333,
      'lng': -76.6833,
    },
    {
      'title': 'Dagua · Vía Cabecera Km 30',
      'lat': 3.6558,
      'lng': -76.6917,
    },
    {
      'title': 'Yumbo · Parque Industrial Acopi',
      'lat': 3.5833,
      'lng': -76.4833,
    },
    {
      'title': 'Cali · Sector Sur / Pance',
      'lat': 3.3421,
      'lng': -76.5412,
    },
    {
      'title': 'Palmira · Terminal de Carga',
      'lat': 3.5394,
      'lng': -76.3036,
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentCenter = const ll.LatLng(3.8833, -77.0167); // Buenaventura por defecto
    _customNameController.text = widget.initialDestination?.trim().isNotEmpty == true
        ? widget.initialDestination!
        : 'Punto seleccionado en mapa';
  }

  @override
  void dispose() {
    _customNameController.dispose();
    super.dispose();
  }

  void _selectPreset(Map<String, dynamic> preset) {
    final pos = ll.LatLng(preset['lat'] as double, preset['lng'] as double);
    setState(() {
      _currentCenter = pos;
      _customNameController.text = preset['title'] as String;
    });
    _mapController.move(pos, 14.0);
  }

  void _handleConfirm() {
    final text = _customNameController.text.trim();
    final formatted = text.isNotEmpty
        ? '$text (${_currentCenter.latitude.toStringAsFixed(4)}, ${_currentCenter.longitude.toStringAsFixed(4)})'
        : 'Destino (${_currentCenter.latitude.toStringAsFixed(4)}, ${_currentCenter.longitude.toStringAsFixed(4)})';
    Navigator.of(context).pop(formatted);
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
              'Seleccionar Destino en el Mapa',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            Text(
              'Desplaza el mapa para ubicar el punto de entrega',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Column(
        children: [
          // Selector rápido de puntos logísticos frecuentes
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: const Color(0xFFF8FAFC),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _presetLocations.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final preset = _presetLocations[index];
                final isSelected = _customNameController.text.contains(preset['title'] as String);
                return ActionChip(
                  backgroundColor: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                  side: BorderSide(
                    color: isSelected ? AppColors.accentBlue : const Color(0xFFCBD5E1),
                  ),
                  label: Text(
                    preset['title'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.accentBlue : AppColors.textPrimary,
                    ),
                  ),
                  onPressed: () => _selectPreset(preset),
                );
              },
            ),
          ),

          // Mapa interactivo con pin central fijo
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentCenter,
                    initialZoom: 12.0,
                    minZoom: 4.0,
                    maxZoom: 18.0,
                    onPositionChanged: (camera, hasGesture) {
                      if (hasGesture) {
                        setState(() {
                          _currentCenter = camera.center;
                        });
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.maquitrace',
                    ),
                  ],
                ),

                // Pin fijo en el centro
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_currentCenter.latitude.toStringAsFixed(4)}, ${_currentCenter.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Icon(
                          Icons.location_on_rounded,
                          size: 44,
                          color: Color(0xFFDC2626),
                        ),
                      ],
                    ),
                  ),
                ),

                // Controles de zoom
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Column(
                    children: [
                      _buildControlBtn(
                        icon: Icons.add_rounded,
                        onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                      ),
                      const SizedBox(height: 6),
                      _buildControlBtn(
                        icon: Icons.remove_rounded,
                        onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Panel inferior de confirmación y nombre
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Nombre o referencia del lugar:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _customNameController,
                    decoration: InputDecoration(
                      hintText: 'Ej. Obra Muelle 13 o Bodega Principal',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                    label: const Text('Confirmar este punto como destino', style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: _handleConfirm,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBtn({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
