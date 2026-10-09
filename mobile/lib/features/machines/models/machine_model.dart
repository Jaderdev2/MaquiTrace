import 'package:flutter/material.dart';

enum PhaseState { pending, inProgress, completed }

enum OverallState { pending, inProgress, completed, inTransit, delivered }

class MachineModel {
  final String id;
  final String name;
  final String serial;
  final String category;
  final OverallState overallState;
  final List<PhaseState> phases; // [Inspección, Lavado, Torque/Pruebas, Evidencias]
  final String? imageUrl; // URL de la foto/avatar subida desde la Web
  final String? imageAsset;
  final String location;
  final String operatingHours;
  final int fuelPercent;
  final String assignedOperator;
  final String modelYear;
  final String? notes;
  final int completedAnglesCount;
  final bool hasAllMandatoryAngles;

  const MachineModel({
    required this.id,
    required this.name,
    required this.serial,
    required this.category,
    required this.overallState,
    required this.phases,
    this.imageUrl,
    this.imageAsset,
    this.location = 'Sede Buenaventura · Patio 2 (B-04)',
    this.operatingHours = '3,420 h',
    this.fuelPercent = 75,
    this.assignedOperator = 'Jhon R.',
    this.modelYear = '2023',
    this.notes,
    this.completedAnglesCount = 0,
    this.hasAllMandatoryAngles = false,
  });

  bool get isReadyForDispatch =>
      overallState == OverallState.completed && hasAllMandatoryAngles;

  bool get isPendingPhotos =>
      overallState == OverallState.completed && !hasAllMandatoryAngles;

  bool get hasCustomImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  String get categoryAsset {
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

  String get displayImage {
    if (imageAsset != null && imageAsset!.isNotEmpty) {
      return imageAsset!;
    }
    return categoryAsset;
  }

  /// Renderiza la imagen de la máquina:
  /// 1. Si tiene foto/avatar personalizada (`imageUrl`), carga desde red con fallback.
  /// 2. Si no tiene, usa la ilustración correspondiente a su categoría.
  Widget buildImage({BoxFit fit = BoxFit.cover, Widget? placeholder}) {
    if (hasCustomImage) {
      return Image.network(
        imageUrl!,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return placeholder ??
              Container(
                color: const Color(0xFFF1F5F9),
                child: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) => Image.asset(
          displayImage,
          fit: fit,
        ),
      );
    }
    return Image.asset(
      displayImage,
      fit: fit,
    );
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

    // Conteo de ángulos obligatorios a partir de evidencias
    final dynamic evidenceRaw = json['evidence'] ?? json['evidences'];
    final evidenceList = evidenceRaw is List ? evidenceRaw : const [];
    const mandatoryKeys = ['frontal', 'lateral', 'cabina', 'serial'];
    final completedAngles = mandatoryKeys.where((key) {
      return evidenceList.any((item) {
        if (item is Map) {
          final url = (item['url'] ?? '').toString().toLowerCase();
          final obs = (item['observations'] ?? '').toString().toLowerCase();
          return url.contains(key) || obs.contains(key);
        }
        return false;
      });
    }).length;

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
      imageUrl: json['imageUrl'] as String?,
      notes: json['notes'],
      completedAnglesCount: completedAngles,
      hasAllMandatoryAngles: completedAngles >= mandatoryKeys.length,
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
      'imageUrl': imageUrl,
    };
  }
}

