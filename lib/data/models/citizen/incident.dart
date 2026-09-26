import 'package:sereno_ya/data/models/citizen/incident_category.dart';

class Incident {
  final String id;
  final String status;
  final String description;
  final double latitude;
  final double longitude;
  final String? referenceAddress;
  final DateTime? createdAt;
  final IncidentCategory? category;

  Incident({
    required this.id,
    required this.status,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.referenceAddress,
    this.createdAt,
    this.category,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'REQUESTED',
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      referenceAddress: json['referenceAddress'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      category: json['category'] != null
          ? IncidentCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }
}
