class IncidentAssignmentAttempt {
  const IncidentAssignmentAttempt({
    required this.attemptNumber,
    required this.serenoId,
    required this.serenoCode,
    required this.status,
    required this.sentAt,
    this.distanceMeters,
    this.respondedAt,
    this.expiresAt,
    this.rejectionReason,
  });

  final int attemptNumber;
  final String serenoId;
  final String serenoCode;
  final double? distanceMeters;
  final String status;
  final DateTime? sentAt;
  final DateTime? respondedAt;
  final DateTime? expiresAt;
  final String? rejectionReason;

  factory IncidentAssignmentAttempt.fromJson(Map<String, dynamic> json) {
    return IncidentAssignmentAttempt(
      attemptNumber: (json['attemptNumber'] as num?)?.toInt() ?? 0,
      serenoId: json['serenoId']?.toString() ?? '',
      serenoCode: json['serenoCode']?.toString() ?? '',
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? '',
      sentAt: _parseDate(json['sentAt']),
      respondedAt: _parseDate(json['respondedAt']),
      expiresAt: _parseDate(json['expiresAt']),
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }

  static DateTime? _parseDate(Object? value) {
    return DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  }
}
