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
}
