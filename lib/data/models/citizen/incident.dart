import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/data/models/citizen/incident_evidence.dart';
import 'package:sereno_ya/data/models/incident_assignment.dart';
import 'package:sereno_ya/data/models/incident_assignment_attempt.dart';
import 'package:sereno_ya/data/models/incident_status_history.dart';

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
  final List<IncidentEvidence> evidences;
  final IncidentAssignment? assignment;
  final List<IncidentStatusHistory> statusHistory;
  final List<IncidentAssignmentAttempt> assignmentAttempts;
  final bool adminDetailsIncluded;

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
    this.evidences = const [],
    this.assignment,
    this.statusHistory = const [],
    this.assignmentAttempts = const [],
    this.adminDetailsIncluded = false,
  });

  /// Primera evidencia, para compatibilidad con vistas de una sola imagen.
  IncidentEvidence? get evidence => evidences.isEmpty ? null : evidences.first;

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
      evidences: _parseEvidences(json),
      assignment: json['assignment'] is Map
          ? IncidentAssignment.fromJson(
              Map<String, dynamic>.from(json['assignment'] as Map),
            )
          : null,
      statusHistory: json['statusHistory'] is List
          ? (json['statusHistory'] as List)
                .whereType<Map>()
                .map(
                  (entry) => IncidentStatusHistory.fromJson(
                    Map<String, dynamic>.from(entry),
                  ),
                )
                .toList(growable: false)
          : const [],
      assignmentAttempts: json['assignmentAttempts'] is List
          ? (json['assignmentAttempts'] as List)
                .whereType<Map>()
                .map(
                  (entry) => IncidentAssignmentAttempt.fromJson(
                    Map<String, dynamic>.from(entry),
                  ),
                )
                .toList(growable: false)
          : const [],
      adminDetailsIncluded:
          json.containsKey('assignment') &&
          json.containsKey('statusHistory') &&
          json.containsKey('assignmentAttempts'),
    );
  }

  static DateTime? _parseLocalDateTime(Object? value) {
    if (value is! String) return null;

    return DateTime.tryParse(value)?.toLocal();
  }

  static List<IncidentEvidence> _parseEvidences(Map<String, dynamic> json) {
    final rawList = json['evidences'];
    if (rawList is List) {
      return rawList
          .whereType<Map>()
          .map(
            (entry) =>
                IncidentEvidence.fromJson(Map<String, dynamic>.from(entry)),
          )
          .toList(growable: false);
    }
    final legacy = json['evidence'];
    if (legacy is Map) {
      return [IncidentEvidence.fromJson(Map<String, dynamic>.from(legacy))];
    }
    return const [];
  }
}
