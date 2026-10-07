class EvidenceModel {
  final String id;
  final String machineId;
  final String? phaseId;
  final String type; // 'foto' o 'video'
  final String url;
  final String uploadedBy;
  final String? uploaderName;
  final String? phaseName;
  final DateTime createdAt;

  const EvidenceModel({
    required this.id,
    required this.machineId,
    this.phaseId,
    required this.type,
    required this.url,
    required this.uploadedBy,
    this.uploaderName,
    this.phaseName,
    required this.createdAt,
  });

  factory EvidenceModel.fromJson(Map<String, dynamic> json) {
    String? uploader;
    if (json['uploader'] != null && json['uploader'] is Map<String, dynamic>) {
      uploader = json['uploader']['name'] as String?;
    }

    String? phase;
    if (json['phase'] != null && json['phase'] is Map<String, dynamic>) {
      phase = json['phase']['name'] as String?;
    }

    return EvidenceModel(
      id: json['id'] as String? ?? '',
      machineId: json['machineId'] as String? ?? '',
      phaseId: json['phaseId'] as String?,
      type: (json['type'] as String? ?? 'foto').toLowerCase(),
      url: json['url'] as String? ?? '',
      uploadedBy: json['uploadedBy'] as String? ?? '',
      uploaderName: uploader,
      phaseName: phase,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'machineId': machineId,
      'phaseId': phaseId,
      'type': type,
      'url': url,
      'uploadedBy': uploadedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isVideo => type == 'video';
  bool get isPhoto => type == 'foto';
}
