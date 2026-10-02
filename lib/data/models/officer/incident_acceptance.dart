class IncidentAcceptance {
  const IncidentAcceptance({
    required this.incidentId,
    required this.assignmentId,
    required this.serenoId,
    required this.status,
    required this.acceptedAt,
    required this.etaMinutes,
  });

  factory IncidentAcceptance.fromJson(Map<String, dynamic> json) {
    return IncidentAcceptance(
      incidentId: json['incidentId']?.toString() ?? '',
      assignmentId: json['assignmentId']?.toString() ?? '',
      serenoId: json['serenoId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACCEPTED',
      acceptedAt: DateTime.tryParse(json['acceptedAt']?.toString() ?? '')
          ?.toLocal(),
      etaMinutes: (json['etaMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  final String incidentId;
  final String assignmentId;
  final String serenoId;
  final String status;
  final DateTime? acceptedAt;
  final int etaMinutes;
}
