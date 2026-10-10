import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../machines/models/machine_model.dart';
import '../models/trip_model.dart';

class TransportService {
  Map<String, String> _buildHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final effectiveToken = token ?? ApiConstants.authToken;
    if (effectiveToken != null && effectiveToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $effectiveToken';
    }
    return headers;
  }

  /// Obtiene los viajes asignados al transportador autenticado
  Future<List<TripModel>> fetchMyTrips({String? token}) async {
    try {
      final url = Uri.parse(ApiConstants.myTripsUrl);
      final response = await http
          .get(url, headers: _buildHeaders(token: token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .map((item) => TripModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {
      // Si falla o la nube aún no tiene my-trips, continúa con el fallback
    }

    // Fallback de contingencia: si la nube de Render aún no tiene desplegado /my-trips,
    // consulta /transport/active que sí existe en el servidor remoto actual.
    try {
      final fallbackUrl = Uri.parse(ApiConstants.activeTripsUrl);
      final fallbackResponse = await http
          .get(fallbackUrl, headers: _buildHeaders(token: token))
          .timeout(const Duration(seconds: 15));

      if (fallbackResponse.statusCode == 200) {
        final dynamic decoded = jsonDecode(fallbackResponse.body);
        if (decoded is List) {
          return decoded
              .map((item) => TripModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}

    return <TripModel>[];
  }

  /// Obtiene las maquinarias que están alistadas y listas para despacho (status == completada)
  Future<List<MachineModel>> fetchReadyMachines({String? token}) async {
    final url = Uri.parse('${ApiConstants.machinesUrl}?status=completada');
    final response = await http
        .get(url, headers: _buildHeaders(token: token))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .map((item) => MachineModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }
    throw HttpException('Error al obtener maquinaria lista (${response.statusCode})');
  }

  /// Registra la recepción de una máquina por el transportador
  Future<TripModel> receiveMachine({
    required String machineId,
    required String vehicle,
    required String destination,
    String? token,
  }) async {
    final url = Uri.parse(ApiConstants.receiveTransportUrl(machineId));
    final body = jsonEncode({
      'vehicle': vehicle,
      'destination': destination,
    });

    final response = await http
        .post(url, headers: _buildHeaders(token: token), body: body)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return TripModel.fromJson(decoded);
    }
    final error = jsonDecode(response.body);
    throw HttpException(error['message'] ?? 'Error al recibir maquinaria');
  }

  /// Inicia el trayecto / salida en ruta
  Future<TripModel> markDeparture({
    required String machineId,
    String? token,
  }) async {
    final url = Uri.parse(ApiConstants.departTransportUrl(machineId));
    final response = await http
        .post(url, headers: _buildHeaders(token: token))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return TripModel.fromJson(decoded);
    }
    final error = jsonDecode(response.body);
    throw HttpException(error['message'] ?? 'Error al iniciar ruta de transporte');
  }

  /// Confirma la entrega final en obra/destino
  Future<TripModel> markDelivered({
    required String machineId,
    String? token,
  }) async {
    final url = Uri.parse(ApiConstants.deliverTransportUrl(machineId));
    final response = await http
        .post(url, headers: _buildHeaders(token: token))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return TripModel.fromJson(decoded);
    }
    final error = jsonDecode(response.body);
    throw HttpException(error['message'] ?? 'Error al confirmar entrega');
  }

  /// Envía coordenadas GPS en tiempo real
  Future<GpsRecordModel> sendGpsLocation({
    required String tripId,
    required double latitude,
    required double longitude,
    String? token,
  }) async {
    final url = Uri.parse(ApiConstants.recordGpsUrl(tripId));
    final body = jsonEncode({
      'latitude': latitude,
      'longitude': longitude,
    });

    final response = await http
        .post(url, headers: _buildHeaders(token: token), body: body)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return GpsRecordModel.fromJson(decoded);
    }
    throw HttpException('Error al reportar posición GPS');
  }

  /// Reporta una novedad o incidencia en ruta con foto opcional a Oracle Cloud
  Future<IncidentModel> reportIncident({
    required String tripId,
    required String description,
    File? photoFile,
    String? token,
  }) async {
    final url = Uri.parse(ApiConstants.tripIncidentsUrl(tripId));
    final effectiveToken = token ?? ApiConstants.authToken;

    if (photoFile != null && await photoFile.exists()) {
      final request = http.MultipartRequest('POST', url);
      if (effectiveToken != null && effectiveToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $effectiveToken';
      }
      request.fields['description'] = description;
      request.files.add(await http.MultipartFile.fromPath('file', photoFile.path));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final respStr = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
        final decoded = jsonDecode(respStr) as Map<String, dynamic>;
        return IncidentModel.fromJson(decoded);
      }
      throw HttpException('Error al enviar reporte con foto (${streamedResponse.statusCode})');
    } else {
      final body = jsonEncode({'description': description});
      final response = await http
          .post(url, headers: _buildHeaders(token: token), body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return IncidentModel.fromJson(decoded);
      }
      final error = jsonDecode(response.body);
      throw HttpException(error['message'] ?? 'Error al reportar novedad');
    }
  }
}
