import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_constants.dart';
import '../models/preparation_phase_model.dart';

class PreparationException implements Exception {
  final String message;
  PreparationException(this.message);

  @override
  String toString() => message;
}

class PreparationService {
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

  /// Obtiene las fases de alistamiento de una máquina
  Future<List<PreparationPhaseModel>> getPhases(String machineId) async {
    final token = await _getToken();
    final headers = _buildHeaders(token);
    final candidateUrls = ApiConstants.candidateBaseUrls;

    for (final base in candidateUrls) {
      try {
        final url = Uri.parse('$base/machines/$machineId/phases');
        final res = await http.get(url, headers: headers).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          ApiConstants.setActiveBaseUrl(base);
          final List<dynamic> list = jsonDecode(res.body);
          return list.map((item) => PreparationPhaseModel.fromJson(item as Map<String, dynamic>)).toList();
        }
      } on TimeoutException {
        continue;
      } catch (_) {
        continue;
      }
    }

    // Fases de contingencia local si el backend no responde
    return [
      PreparationPhaseModel(
        id: 'phase-1-$machineId',
        machineId: machineId,
        name: 'ensamblaje',
        status: 'completada',
        observations: 'Ensamblaje mecánico y torque estructural completados.',
        operatorName: 'Yuji Itadori',
      ),
      PreparationPhaseModel(
        id: 'phase-2-$machineId',
        machineId: machineId,
        name: 'lavado',
        status: 'en_proceso',
        observations: 'Lavado a presión de chasis y desengrase de ceras de transporte.',
        operatorName: 'Charly Murillo',
      ),
      PreparationPhaseModel(
        id: 'phase-3-$machineId',
        machineId: machineId,
        name: 'pintura',
        status: 'pendiente',
        observations: null,
      ),
    ];
  }

  /// Actualiza el estado y observaciones de una fase con validación secuencial
  Future<PreparationPhaseModel?> updatePhase({
    required String machineId,
    required String phaseId,
    required String status,
    String? observations,
  }) async {
    final token = await _getToken();
    final headers = _buildHeaders(token);
    final candidateUrls = ApiConstants.candidateBaseUrls;

    for (final base in candidateUrls) {
      try {
        final url = Uri.parse('$base/machines/$machineId/phases/$phaseId');
        final payload = <String, dynamic>{'status': status};
        if (observations != null) {
          payload['observations'] = observations;
        }

        final res = await http
            .patch(
              url,
              headers: headers,
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 5));

        if (res.statusCode == 200 || res.statusCode == 201) {
          ApiConstants.setActiveBaseUrl(base);
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          return PreparationPhaseModel.fromJson(data);
        } else if (res.statusCode == 400) {
          final errorData = jsonDecode(res.body);
          final msg = errorData['message'] ?? 'Restricción de avance no cumplida';
          throw PreparationException(msg.toString());
        }
      } on TimeoutException {
        continue;
      } catch (e) {
        if (e is PreparationException) rethrow;
        continue;
      }
    }

    return null;
  }
}
