import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_constants.dart';
import '../models/machine_model.dart';

class MachinesService {
  /// Catálogo local de contingencia (garantiza funcionamiento sin red o ante fallos de conexión)
  static const List<MachineModel> localCatalog = [
    MachineModel(
      id: '1',
      name: 'CAT 320D',
      serial: 'ABC123',
      category: 'Excavadoras',
      overallState: OverallState.inProgress,
      phases: [PhaseState.completed, PhaseState.inProgress, PhaseState.pending],
    ),
    MachineModel(
      id: '2',
      name: 'Komatsu WA470',
      serial: 'KMT458',
      category: 'Cargadores',
      overallState: OverallState.pending,
      phases: [PhaseState.pending, PhaseState.pending, PhaseState.pending],
    ),
    MachineModel(
      id: '3',
      name: 'CAT 320D',
      serial: 'DEF789',
      category: 'Excavadoras',
      overallState: OverallState.completed,
      phases: [PhaseState.completed, PhaseState.completed, PhaseState.completed],
    ),
    MachineModel(
      id: '4',
      name: 'John Deere 310L',
      serial: 'JD310-992',
      category: 'Retroexcavadoras',
      overallState: OverallState.inProgress,
      phases: [PhaseState.completed, PhaseState.inProgress, PhaseState.pending],
    ),
    MachineModel(
      id: '5',
      name: 'Kenworth T800',
      serial: 'KW-8841',
      category: 'Volquetas',
      overallState: OverallState.completed,
      phases: [PhaseState.completed, PhaseState.completed, PhaseState.completed],
    ),
    MachineModel(
      id: '6',
      name: 'CAT 140M',
      serial: 'MN-9042',
      category: 'Motoniveladoras',
      overallState: OverallState.inProgress,
      phases: [PhaseState.completed, PhaseState.inProgress, PhaseState.pending],
      location: 'Sede Buenaventura · Patio 2 (B-08)',
      operatingHours: '2,680 h',
      fuelPercent: 82,
    ),
  ];

  Future<String?> _getToken() async {
    if (ApiConstants.authToken != null && ApiConstants.authToken!.isNotEmpty) {
      return ApiConstants.authToken;
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('auth_token');
    if (saved != null) {
      ApiConstants.authToken = saved;
    }
    return saved;
  }

  Map<String, String> _buildHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Busca una máquina por su número serial exacto (vía QR o búsqueda manual directa)
  Future<MachineModel?> getBySerial(String serial) async {
    final cleanSerial = serial.trim().toUpperCase();
    final token = await _getToken();
    final headers = _buildHeaders(token);
    final candidateUrls = ApiConstants.candidateBaseUrls;

    // 1. Intentar consultar el backend en vivo
    for (final base in candidateUrls) {
      try {
        final url = Uri.parse('$base/machines/by-serial/${Uri.encodeComponent(cleanSerial)}');
        final res = await http.get(url, headers: headers).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          ApiConstants.setActiveBaseUrl(base);
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          return MachineModel.fromJson(data);
        } else if (res.statusCode == 404) {
          // El backend respondió explícitamente que no existe
          ApiConstants.setActiveBaseUrl(base);
          // Verificar si existe en el catálogo local de contingencia
          return _findInLocalCatalog(cleanSerial);
        }
      } on TimeoutException {
        continue;
      } catch (e) {
        debugPrint('[MachinesService] Error consultando $base: $e');
        continue;
      }
    }

    // 2. Si no hubo respuesta del backend, consultar fallback local
    return _findInLocalCatalog(cleanSerial);
  }

  MachineModel? _findInLocalCatalog(String serial) {
    final match = localCatalog.where(
      (m) => m.serial.toUpperCase() == serial || m.serial.toUpperCase().contains(serial),
    );
    return match.isNotEmpty ? match.first : null;
  }

  /// Búsqueda y listado de máquinas con filtro opcional de serial y categoría
  Future<List<MachineModel>> search({String? serial, String? category}) async {
    final token = await _getToken();
    final headers = _buildHeaders(token);
    final queryParams = <String, String>{};

    if (serial != null && serial.trim().isNotEmpty) {
      queryParams['serial'] = serial.trim();
    }
    if (category != null && category != 'Todas') {
      queryParams['category'] = category;
    }

    final candidateUrls = ApiConstants.candidateBaseUrls;

    for (final base in candidateUrls) {
      try {
        final uri = Uri.parse('$base/machines').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
        final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          ApiConstants.setActiveBaseUrl(base);
          final List<dynamic> list = jsonDecode(res.body);
          if (list.isNotEmpty) {
            return list.map((item) => MachineModel.fromJson(item as Map<String, dynamic>)).toList();
          }
        }
      } on TimeoutException {
        continue;
      } catch (_) {
        continue;
      }
    }

    // Fallback al catálogo local si no se pudo conectar al backend
    return localCatalog.where((m) {
      final matchesSerial = serial == null || serial.isEmpty || m.serial.toUpperCase().contains(serial.toUpperCase());
      final matchesCat = category == null || category == 'Todas' || m.category.toLowerCase().contains(category.toLowerCase());
      return matchesSerial && matchesCat;
    }).toList();
  }
}
