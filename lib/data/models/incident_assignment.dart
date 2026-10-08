class IncidentAssignment {
  const IncidentAssignment({
    required this.serenoId,
    required this.serenoCode,
    required this.serenoServiceStatus,
    required this.status,
    required this.assignedAt,
    required this.etaMinutes,
  });

  final String serenoId;
  final String serenoCode;
  final String serenoServiceStatus;
  final String status;
  final DateTime? assignedAt;
  final int? etaMinutes;

  factory IncidentAssignment.fromJson(Map<String, dynamic> json) {
    return IncidentAssignment(
      serenoId: json['serenoId']?.toString() ?? '',
      serenoCode: json['serenoCode']?.toString() ?? '',
      serenoServiceStatus: json['serenoServiceStatus']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      assignedAt: DateTime.tryParse(json['assignedAt']?.toString() ?? '')
          ?.toLocal(),
      etaMinutes: (json['etaMinutes'] as num?)?.toInt(),
    );
  }
}
