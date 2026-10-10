import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../machines/models/machine_model.dart';
import '../models/trip_model.dart';
import '../services/transport_service.dart';

class TransportProvider extends ChangeNotifier {
  final TransportService _service = TransportService();

  List<TripModel> _trips = [];
  List<MachineModel> _readyMachines = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  List<TripModel> get myTrips => _trips;
  List<MachineModel> get readyMachines => _readyMachines;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  /// Viajes activos (pendientes de salir o en tránsito)
  List<TripModel> get activeTrips =>
      _trips.where((t) => t.isPending || t.isInTransit).toList();

  /// Historial de viajes entregados
  List<TripModel> get deliveredTrips =>
      _trips.where((t) => t.isDelivered).toList();

  /// Si hay un viaje actualmente en ruta
  TripModel? get currentTripInTransit {
    for (final t in _trips) {
      if (t.isInTransit) return t;
    }
    return null;
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Carga viajes del transportador y máquinas listas para despacho
  Future<void> loadDashboardData({String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.fetchMyTrips(token: token).catchError((_) => <TripModel>[]),
        _service.fetchReadyMachines(token: token).catchError((_) => <MachineModel>[]),
      ]);

      _trips = results[0] as List<TripModel>;
      _readyMachines = results[1] as List<MachineModel>;
    } catch (e) {
      _errorMessage = 'No se pudo sincronizar la información de transporte.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Registrar recepción de maquinaria
  Future<bool> receiveMachine({
    required String machineId,
    required String vehicle,
    required String destination,
    String? token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newTrip = await _service.receiveMachine(
        machineId: machineId,
        vehicle: vehicle,
        destination: destination,
        token: token,
      );

      _trips.insert(0, newTrip);
      _readyMachines.removeWhere((m) => m.id == machineId);
      _successMessage = 'Maquinaria recibida exitosamente en el despacho';
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('HttpException: ', '').replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Iniciar salida / viaje en ruta
  Future<bool> startTrip({
    required String machineId,
    String? token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedTrip = await _service.markDeparture(
        machineId: machineId,
        token: token,
      );

      final index = _trips.indexWhere((t) => t.id == updatedTrip.id || t.machineId == machineId);
      if (index != -1) {
        _trips[index] = updatedTrip;
      } else {
        _trips.insert(0, updatedTrip);
      }

      _successMessage = 'Ruta iniciada: El equipo se encuentra ahora en tránsito';
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('HttpException: ', '').replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Confirmar entrega final en obra
  Future<bool> completeDelivery({
    required String machineId,
    String? token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final deliveredTrip = await _service.markDelivered(
        machineId: machineId,
        token: token,
      );

      final index = _trips.indexWhere((t) => t.id == deliveredTrip.id || t.machineId == machineId);
      if (index != -1) {
        _trips[index] = deliveredTrip;
      } else {
        _trips.insert(0, deliveredTrip);
      }

      _successMessage = 'Entrega confirmada y registrada exitosamente';
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('HttpException: ', '').replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Emitir posición GPS
  Future<bool> updateGps({
    required String tripId,
    required double latitude,
    required double longitude,
    String? token,
  }) async {
    try {
      final record = await _service.sendGpsLocation(
        tripId: tripId,
        latitude: latitude,
        longitude: longitude,
        token: token,
      );

      final index = _trips.indexWhere((t) => t.id == tripId);
      if (index != -1) {
        _trips[index] = _trips[index].copyWith(lastGps: record);
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Reportar incidencia en ruta
  Future<bool> reportIncident({
    required String tripId,
    required String description,
    File? photoFile,
    String? token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final incident = await _service.reportIncident(
        tripId: tripId,
        description: description,
        photoFile: photoFile,
        token: token,
      );

      final index = _trips.indexWhere((t) => t.id == tripId);
      if (index != -1) {
        final currentIncidents = List<IncidentModel>.from(_trips[index].incidents);
        currentIncidents.insert(0, incident);
        _trips[index] = _trips[index].copyWith(incidents: currentIncidents);
      }

      _successMessage = 'Novedad registrada y transmitida al centro de control';
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('HttpException: ', '').replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
