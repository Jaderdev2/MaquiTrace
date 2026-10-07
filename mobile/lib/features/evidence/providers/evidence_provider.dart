import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../models/evidence_model.dart';

class EvidenceProvider extends ChangeNotifier {
  List<EvidenceModel> _evidences = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;
  String? _successMessage;

  List<EvidenceModel> get evidences => _evidences;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  /// Obtiene las evidencias de una máquina específica
  List<EvidenceModel> getEvidencesForMachine(String machineId) {
    return _evidences.where((e) => e.machineId == machineId).toList();
  }

  /// Obtiene las evidencias de una fase específica
  List<EvidenceModel> getEvidencesForPhase(String? phaseId) {
    if (phaseId == null) return _evidences;
    return _evidences.where((e) => e.phaseId == phaseId).toList();
  }

  /// Carga todas las evidencias de una máquina desde la API de Render
  Future<void> fetchEvidences(String machineId, {String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse(ApiConstants.machineEvidenceUrl(machineId));
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      final effectiveToken = token ?? ApiConstants.authToken;
      if (effectiveToken != null && effectiveToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $effectiveToken';
      }

      final response = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          _evidences = decoded
              .map((item) => EvidenceModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (decoded is Map && decoded['data'] is List) {
          _evidences = (decoded['data'] as List)
              .map((item) => EvidenceModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      } else {
        _errorMessage = 'Error ${response.statusCode} al obtener evidencias.';
      }
    } catch (e) {
      debugPrint('[EvidenceProvider] Error al consultar evidencias: $e');
      _errorMessage = 'No se pudo conectar con el servidor de evidencias.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sube un archivo binario (foto/video) con Multer hacia Oracle Object Storage
  Future<bool> uploadEvidence({
    required String machineId,
    required File file,
    String? phaseId,
    String type = 'foto',
    String? observations,
    String? token,
  }) async {
    _isUploading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse(ApiConstants.machineEvidenceUrl(machineId));
      final request = http.MultipartRequest('POST', url);

      final effectiveToken = token ?? ApiConstants.authToken;
      if (effectiveToken != null && effectiveToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $effectiveToken';
      }

      // Campos en formato FormData
      if (phaseId != null && phaseId.isNotEmpty) {
        request.fields['phaseId'] = phaseId;
      }
      request.fields['type'] = type;
      if (observations != null && observations.isNotEmpty) {
        request.fields['observations'] = observations;
      }

      // Adjuntar archivo binario
      final multipartFile = await http.MultipartFile.fromPath('file', file.path);
      request.files.add(multipartFile);

      debugPrint('[Upload] Enviando archivo ${file.path} (${multipartFile.length} bytes) a: $url');

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 45),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _successMessage = '¡Evidencia subida y guardada exitosamente en Oracle Cloud!';
        debugPrint('[Upload] Subida exitosa: ${response.body}');

        // Recargar lista actualizada de evidencias
        await fetchEvidences(machineId, token: effectiveToken);
        _isUploading = false;
        notifyListeners();
        return true;
      } else {
        debugPrint('[Upload] Error ${response.statusCode}: ${response.body}');
        try {
          final errorBody = jsonDecode(response.body);
          _errorMessage = errorBody['message'] ?? 'Error al subir evidencia.';
        } catch (_) {
          _errorMessage = 'Error ${response.statusCode} al subir archivo al servidor.';
        }
      }
    } catch (e) {
      debugPrint('[Upload] Excepción en subida de evidencia: $e');
      _errorMessage = 'Fallo de conexión al subir la evidencia. Verifica tu internet.';
    } finally {
      _isUploading = false;
      notifyListeners();
    }

    return false;
  }
}
