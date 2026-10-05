enum PhaseState { pending, inProgress, completed }

enum OverallState { pending, inProgress, completed, inTransit, delivered }

class MachineModel {
  final String id;
  final String name;
  final String serial;
  final String category;
  final OverallState overallState;
  final List<PhaseState> phases; // [Inspección, Lavado, Torque/Pruebas, Evidencias]
  final String? imageAsset;
  final String location;
  final String operatingHours;
  final int fuelPercent;
  final String assignedOperator;
  final String modelYear;
  final String? notes;

  const MachineModel({
    required this.id,
    required this.name,
    required this.serial,
    required this.category,
    required this.overallState,
    required this.phases,
    this.imageAsset,
    this.location = 'Sede Buenaventura · Patio 2 (B-04)',
    this.operatingHours = '3,420 h',
    this.fuelPercent = 75,
    this.assignedOperator = 'Jhon R.',
    this.modelYear = '2023',
    this.notes,
  });

  String get displayImage {
    if (imageAsset != null && imageAsset!.isNotEmpty) {
      return imageAsset!;
    }
    final cat = category.toLowerCase();
    if (cat.contains('motoniveladora') || cat.contains('niveladora')) {
      return 'assets/images/categories/motoniveladora.webp';
    } else if (cat.contains('cargador')) {
      return 'assets/images/categories/Cargadores frontales.webp';
    } else if (cat.contains('retro')) {
      return 'assets/images/categories/Retroexcavadoras.webp';
    } else if (cat.contains('volqueta') || cat.contains('camion') || cat.contains('dumper')) {
      return 'assets/images/categories/Volquetas.webp';
    } else if (cat.contains('excavadora')) {
      return 'assets/images/categories/Excavadoras.webp';
    }
    return 'assets/images/categories/Excavadoras.webp';
  }

  factory MachineModel.fromJson(Map<String, dynamic> json) {
    OverallState state = OverallState.pending;
    final statusStr = (json['status'] ?? '').toString().toLowerCase();
    if (statusStr == 'en_proceso') {
      state = OverallState.inProgress;
    } else if (statusStr == 'completada') {
      state = OverallState.completed;
    } else if (statusStr == 'en_transito') {
      state = OverallState.inTransit;
    } else if (statusStr == 'entregada') {
      state = OverallState.delivered;
    }

    final phasesRaw = List<dynamic>.from(json['phases'] as List<dynamic>? ?? []);
    // Ordenar explícitamente las fases por secuencia operativa de MaquiTrace:
    // 1. ensamblaje -> 2. lavado -> 3. pintura
    int getPhaseOrder(dynamic p) {
      if (p is Map<String, dynamic>) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        if (name == 'ensamblaje') return 1;
        if (name == 'lavado') return 2;
        if (name == 'pintura') return 3;
      }
      return 99;
    }
    phasesRaw.sort((a, b) => getPhaseOrder(a).compareTo(getPhaseOrder(b)));

    final phasesList = <PhaseState>[];
    String? assignedOp;
    for (final p in phasesRaw) {
      if (p is Map<String, dynamic>) {
        final pStatus = (p['status'] ?? '').toString().toLowerCase();
        if (pStatus == 'completada') {
          phasesList.add(PhaseState.completed);
        } else if (pStatus == 'en_proceso') {
          phasesList.add(PhaseState.inProgress);
        } else {
          phasesList.add(PhaseState.pending);
        }
        if (p['operator'] != null && p['operator'] is Map && assignedOp == null) {
          assignedOp = p['operator']['name'];
        }
      }
    }

    if (phasesList.isEmpty) {
      phasesList.addAll([PhaseState.pending, PhaseState.pending, PhaseState.pending]);
    } else if (state != OverallState.inTransit && state != OverallState.delivered) {
      final allCompleted = phasesList.every((p) => p == PhaseState.completed);
      final anyActive = phasesList.any((p) => p == PhaseState.inProgress || p == PhaseState.completed);
      if (allCompleted) {
        state = OverallState.completed;
      } else if (anyActive) {
        state = OverallState.inProgress;
      } else {
        state = OverallState.pending;
      }
    }

    return MachineModel(
      id: json['id'] ?? '',
      name: json['model'] ?? json['name'] ?? 'Maquinaria',
      serial: json['serial'] ?? '',
      category: json['category'] ?? 'Maquinaria',
      overallState: state,
      phases: phasesList,
      assignedOperator: assignedOp ?? 'Jhon R.',
      location: json['location'] ?? 'Sede Buenaventura · Patio 2 (B-04)',
      operatingHours: json['operatingHours'] ?? '3,420 h',
      fuelPercent: json['fuelPercent'] ?? 75,
      modelYear: json['modelYear'] ?? '2023',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'serial': serial,
      'category': category,
      'status': overallState.name,
      'assignedOperator': assignedOperator,
    };
  }
}

