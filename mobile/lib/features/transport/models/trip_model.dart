import 'package:flutter/material.dart';
import '../../machines/models/machine_model.dart';

enum TripStatus {
  pendiente,
  enTransito,
  entregado,
}

class GpsRecordModel {
  final String id;
  final double latitude;
  final double longitude;
  final DateTime recordedAt;

  const GpsRecordModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  factory GpsRecordModel.fromJson(Map<String, dynamic> json) {
    return GpsRecordModel(
      id: json['id']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      recordedAt: json['recordedAt'] != null
          ? DateTime.tryParse(json['recordedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'recordedAt': recordedAt.toIso8601String(),
      };
}

class IncidentModel {
  final String id;
  final String tripId;
  final String description;
  final String? photoUrl;
  final DateTime reportedAt;

  const IncidentModel({
    required this.id,
    required this.tripId,
    required this.description,
    this.photoUrl,
    required this.reportedAt,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      id: json['id']?.toString() ?? '',
      tripId: json['tripId']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString(),
      reportedAt: json['reportedAt'] != null
          ? DateTime.tryParse(json['reportedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripId': tripId,
        'description': description,
        'photoUrl': photoUrl,
        'reportedAt': reportedAt.toIso8601String(),
      };
}

class TripModel {
  final String id;
  final String machineId;
  final MachineModel? machine;
  final String transporterId;
  final String? transporterName;
  final String vehicle;
  final String destination;
  final TripStatus status;
  final DateTime? departureAt;
  final DateTime? arrivalAt;
  final GpsRecordModel? lastGps;
  final List<IncidentModel> incidents;

  const TripModel({
    required this.id,
    required this.machineId,
    this.machine,
    required this.transporterId,
    this.transporterName,
    required this.vehicle,
    required this.destination,
    required this.status,
    this.departureAt,
    this.arrivalAt,
    this.lastGps,
    this.incidents = const [],
  });

  bool get isPending => status == TripStatus.pendiente;
  bool get isInTransit => status == TripStatus.enTransito;
  bool get isDelivered => status == TripStatus.entregado;

  String get statusLabel {
    switch (status) {
      case TripStatus.pendiente:
        return 'Pendiente de Salida';
      case TripStatus.enTransito:
        return 'En Tránsito';
      case TripStatus.entregado:
        return 'Entregado';
    }
  }

  Color get statusColor {
    switch (status) {
      case TripStatus.pendiente:
        return const Color(0xFFB45309); // Ámbar WCAG AA
      case TripStatus.enTransito:
        return const Color(0xFF2563EB); // Azul industrial
      case TripStatus.entregado:
        return const Color(0xFF15803D); // Verde éxito
    }
  }

  Color get statusBgColor {
    switch (status) {
      case TripStatus.pendiente:
        return const Color(0xFFFEF3C7);
      case TripStatus.enTransito:
        return const Color(0xFFEFF6FF);
      case TripStatus.entregado:
        return const Color(0xFFE8F5EC);
    }
  }

  factory TripModel.fromJson(Map<String, dynamic> json) {
    TripStatus tripStatus = TripStatus.pendiente;
    final statusStr = (json['status'] ?? '').toString().toLowerCase();
    if (statusStr == 'en_transito' || statusStr == 'entransito') {
      tripStatus = TripStatus.enTransito;
    } else if (statusStr == 'entregado') {
      tripStatus = TripStatus.entregado;
    }

    MachineModel? parsedMachine;
    if (json['machine'] != null && json['machine'] is Map<String, dynamic>) {
      parsedMachine = MachineModel.fromJson(json['machine'] as Map<String, dynamic>);
    }

    String? name;
    if (json['transporter'] != null && json['transporter'] is Map) {
      name = json['transporter']['name']?.toString();
    }

    GpsRecordModel? gps;
    if (json['gpsRecords'] != null && json['gpsRecords'] is List && (json['gpsRecords'] as List).isNotEmpty) {
      final first = (json['gpsRecords'] as List).first;
      if (first is Map<String, dynamic>) {
        gps = GpsRecordModel.fromJson(first);
      }
    }

    final incList = <IncidentModel>[];
    if (json['incidents'] != null && json['incidents'] is List) {
      for (final inc in (json['incidents'] as List)) {
        if (inc is Map<String, dynamic>) {
          incList.add(IncidentModel.fromJson(inc));
        }
      }
    }

    return TripModel(
      id: json['id']?.toString() ?? '',
      machineId: json['machineId']?.toString() ?? (parsedMachine?.id ?? ''),
      machine: parsedMachine,
      transporterId: json['transporterId']?.toString() ?? '',
      transporterName: name,
      vehicle: json['vehicle']?.toString() ?? 'Vehículo no especificado',
      destination: json['destination']?.toString() ?? 'Destino no especificado',
      status: tripStatus,
      departureAt: json['departureAt'] != null
          ? DateTime.tryParse(json['departureAt'].toString())
          : null,
      arrivalAt: json['arrivalAt'] != null
          ? DateTime.tryParse(json['arrivalAt'].toString())
          : null,
      lastGps: gps,
      incidents: incList,
    );
  }

  TripModel copyWith({
    String? id,
    String? machineId,
    MachineModel? machine,
    String? transporterId,
    String? transporterName,
    String? vehicle,
    String? destination,
    TripStatus? status,
    DateTime? departureAt,
    DateTime? arrivalAt,
    GpsRecordModel? lastGps,
    List<IncidentModel>? incidents,
  }) {
    return TripModel(
      id: id ?? this.id,
      machineId: machineId ?? this.machineId,
      machine: machine ?? this.machine,
      transporterId: transporterId ?? this.transporterId,
      transporterName: transporterName ?? this.transporterName,
      vehicle: vehicle ?? this.vehicle,
      destination: destination ?? this.destination,
      status: status ?? this.status,
      departureAt: departureAt ?? this.departureAt,
      arrivalAt: arrivalAt ?? this.arrivalAt,
      lastGps: lastGps ?? this.lastGps,
      incidents: incidents ?? this.incidents,
    );
  }
}
