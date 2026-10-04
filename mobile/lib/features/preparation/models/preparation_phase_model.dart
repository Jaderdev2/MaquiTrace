class PreparationPhaseModel {
  final String id;
  final String machineId;
  final String name; // lavado | ensamblaje | pintura
  final String status; // pendiente | en_proceso | completada
  final String? observations;
  final String? operatorName;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const PreparationPhaseModel({
    required this.id,
    required this.machineId,
    required this.name,
    required this.status,
    this.observations,
    this.operatorName,
    this.startedAt,
    this.completedAt,
  });

  bool get isCompleted => status == 'completada';
  bool get isInProgress => status == 'en_proceso';
  bool get isPending => status == 'pendiente';

  int get stepNumber {
    switch (name.toLowerCase()) {
      case 'lavado':
        return 1;
      case 'ensamblaje':
        return 2;
      case 'pintura':
        return 3;
      default:
        return 1;
    }
  }

  String get displayName {
    switch (name.toLowerCase()) {
      case 'lavado':
        return 'Lavado y Descontaminación';
      case 'ensamblaje':
        return 'Ensamblaje Mecánico';
      case 'pintura':
        return 'Pintura y Acabados';
      default:
        return name.toUpperCase();
    }
  }

  String get description {
    switch (name.toLowerCase()) {
      case 'lavado':
        return 'Desengrase de motor, orugas, chasis y cabina del operador.';
      case 'ensamblaje':
        return 'Acople de brazo hidráulico, mandos y verificación de torque de pernos.';
      case 'pintura':
        return 'Retoque de pintura anticorrosiva, pulido estético y rotulación oficial.';
      default:
        return 'Inspección técnica y ejecución de fase.';
    }
  }

  factory PreparationPhaseModel.fromJson(Map<String, dynamic> json) {
    String? opName;
    if (json['operator'] != null && json['operator'] is Map) {
      opName = json['operator']['name'];
    }

    return PreparationPhaseModel(
      id: json['id'] ?? '',
      machineId: json['machineId'] ?? '',
      name: (json['name'] ?? '').toString().toLowerCase(),
      status: (json['status'] ?? 'pendiente').toString().toLowerCase(),
      observations: json['observations'],
      operatorName: opName,
      startedAt: json['startedAt'] != null ? DateTime.tryParse(json['startedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt']) : null,
    );
  }

  PreparationPhaseModel copyWith({
    String? id,
    String? machineId,
    String? name,
    String? status,
    String? observations,
    String? operatorName,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return PreparationPhaseModel(
      id: id ?? this.id,
      machineId: machineId ?? this.machineId,
      name: name ?? this.name,
      status: status ?? this.status,
      observations: observations ?? this.observations,
      operatorName: operatorName ?? this.operatorName,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
