import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/data/models/citizen/incident_evidence.dart';

class Incident {
  final String id;
  final String status;
  final String description;
  final double latitude;
  final double longitude;
  final String? referenceAddress;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? attendedAt;
  final DateTime? cancelledAt;
  final IncidentCategory? category;
  final IncidentEvidence? evidence;

  Incident({
    required this.id,
    required this.status,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.referenceAddress,
    this.createdAt,
    this.acceptedAt,
    this.arrivedAt,
    this.attendedAt,
    this.cancelledAt,
    this.category,
    this.evidence,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'REQUESTED',
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      referenceAddress: json['referenceAddress'] as String?,
      createdAt: _parseLocalDateTime(json['createdAt']),
      acceptedAt: _parseLocalDateTime(json['acceptedAt']),
      arrivedAt: _parseLocalDateTime(json['arrivedAt']),
      attendedAt: _parseLocalDateTime(json['attendedAt']),
      cancelledAt: _parseLocalDateTime(json['cancelledAt']),
      category: json['category'] != null
          ? IncidentCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      evidence: json['evidence'] is Map
          ? IncidentEvidence.fromJson(
              Map<String, dynamic>.from(json['evidence'] as Map),
            )
          : null,
    );
  }

  static DateTime? _parseLocalDateTime(Object? value) {
    if (value is! String) return null;

    return DateTime.tryParse(value)?.toLocal();
  }
}
