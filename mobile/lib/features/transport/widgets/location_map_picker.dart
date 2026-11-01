import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../core/constants/mapbox_constants.dart';
import '../../../core/services/mapbox_service.dart';
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
  final MapboxService _mapboxService = MapboxService();

  late ll.LatLng _currentCenter;
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isSatellite = false;
  bool _isSearching = false;
  bool _isReverseGeocoding = false;
  List<MapboxSearchResult> _searchResults = [];
  Timer? _debounceTimer;

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
        : 'Buenaventura · Terminal Portuario';
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _customNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isSearching = true);
      final results = await _mapboxService.searchPlaces(query, proximity: _currentCenter);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _selectSearchResult(MapboxSearchResult result) {
    setState(() {
      _currentCenter = result.center;
      _customNameController.text = result.placeName;
      _searchController.clear();
      _searchResults = [];
    });
    FocusScope.of(context).unfocus();
    _mapController.move(result.center, 15.0);
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    _currentCenter = camera.center;

    // Debounce de geocodificación inversa para actualizar la dirección automáticamente
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      setState(() => _isReverseGeocoding = true);
      final address = await _mapboxService.reverseGeocode(_currentCenter);
      if (mounted) {
        setState(() {
          _isReverseGeocoding = false;
          if (address != null && address.isNotEmpty) {
            _customNameController.text = address;
          }
        });
      }
    });
  }

  void _selectPreset(Map<String, dynamic> preset) {
    final pos = ll.LatLng(preset['lat'] as double, preset['lng'] as double);
    setState(() {
      _currentCenter = pos;
      _customNameController.text = preset['title'] as String;
      _searchResults = [];
    });
    _mapController.move(pos, 14.5);
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
    final activeTileUrl = _isSatellite ? MapboxConstants.satelliteStreets : MapboxConstants.navigationDay;

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
              'Seleccionar Destino (Mapbox)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            Text(
              'Búsqueda inteligente y satelital HD en carretera',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          // Botón alternar estilo Satelital / Calles
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: _isSatellite ? const Color(0xFF15803D) : AppColors.accentBlue,
                backgroundColor: _isSatellite ? const Color(0xFFE8F5EC) : const Color(0xFFEFF6FF),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(0, 32),
              ),
              icon: Icon(_isSatellite ? Icons.layers_rounded : Icons.satellite_alt_rounded, size: 16),
              label: Text(
                _isSatellite ? 'Calles' : 'Satélite HD',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                setState(() => _isSatellite = !_isSatellite);
              },
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 1. Barra de búsqueda Mapbox Places
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                color: Colors.white,
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Buscar ciudad, peaje, muelle o dirección...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.accentBlue),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchResults = []);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ),
              ),

              // 2. Hubs logísticos de acceso rápido
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.white,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _presetLocations.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final preset = _presetLocations[index];
                    final isSelected = _customNameController.text.contains(preset['title'] as String);
                    return ActionChip(
                      backgroundColor: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                      side: BorderSide(
                        color: isSelected ? AppColors.accentBlue : const Color(0xFFE2E8F0),
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

              // 3. Mapa Mapbox HD
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentCenter,
                        initialZoom: 13.0,
                        minZoom: 4.0,
                        maxZoom: 18.0,
                        onPositionChanged: _onPositionChanged,
                      ),
                      children: [
                        TileLayer(
                          key: ValueKey(activeTileUrl),
                          urlTemplate: activeTileUrl,
                          additionalOptions: const {
                            'access_token': MapboxConstants.accessToken,
                          },
                          userAgentPackageName: 'com.example.maquitrace',
                        ),
                      ],
                    ),

                    // Pin central de mira
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 38),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isReverseGeocoding) ...[
                                    const SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    '${_currentCenter.latitude.toStringAsFixed(4)}, ${_currentCenter.longitude.toStringAsFixed(4)}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.location_on_rounded,
                              size: 46,
                              color: Color(0xFFDC2626),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Badge de atribución Mapbox
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '© Mapbox · © OpenStreetMap',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
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

              // 4. Panel inferior de confirmación
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Nombre o dirección confirmada:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          if (_isReverseGeocoding)
                            const Text(
                              'Geocodificando...',
                              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.accentBlue),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _customNameController,
                        maxLines: 2,
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

          // 5. Overlay de resultados de búsqueda Mapbox Places (flotante)
          if (_searchResults.isNotEmpty || _isSearching)
            Positioned(
              top: 56,
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          itemBuilder: (context, index) {
                            final item = _searchResults[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.place_outlined, color: AppColors.accentBlue, size: 20),
                              title: Text(
                                item.text,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              subtitle: Text(
                                item.placeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              onTap: () => _selectSearchResult(item),
                            );
                          },
                        ),
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
      elevation: 3,
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
