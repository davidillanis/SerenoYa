class IncidentStatusHistory {
  const IncidentStatusHistory({
    required this.previousStatus,
    required this.newStatus,
    required this.observation,
    required this.changedAt,
  });

  final String previousStatus;
  final String newStatus;
  final String observation;
  final DateTime? changedAt;

  factory IncidentStatusHistory.fromJson(Map<String, dynamic> json) {
    return IncidentStatusHistory(
      previousStatus: json['previousStatus']?.toString() ?? '',
      newStatus: json['newStatus']?.toString() ?? '',
      observation: json['observation']?.toString() ?? '',
      changedAt: DateTime.tryParse(json['changedAt']?.toString() ?? '')
          ?.toLocal(),
    );
  }
}
