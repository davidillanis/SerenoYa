class IncidentEvidence {
  const IncidentEvidence({
    required this.id,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    this.createdAt,
  });

  factory IncidentEvidence.fromJson(Map<String, dynamic> json) {
    return IncidentEvidence(
      id: json['id']?.toString() ?? '',
      fileUrl: json['fileUrl']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      fileType: json['fileType']?.toString() ?? '',
      createdAt: _parseLocalDateTime(json['createdAt']),
    );
  }

  final String id;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final DateTime? createdAt;

  static DateTime? _parseLocalDateTime(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
