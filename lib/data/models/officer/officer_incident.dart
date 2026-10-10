import 'package:sereno_ya/data/models/citizen/incident.dart';

enum OfficerIncidentStatus {
  pending('REQUESTED', 'Pendiente'),
  enRoute('ACCEPTED', 'En curso'),
  attending('ON_SITE', 'Atendiendo'),
  attended('ATTENDED', 'Atendido'),
  cancelled('CANCELLED_BY_CITIZEN', 'Cancelado'),
  expired('EXPIRED', 'Expirado'),
  unknown('', 'Estado no disponible');

  const OfficerIncidentStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static OfficerIncidentStatus parse(String value) => values.firstWhere(
    (status) => status.apiValue == value,
    orElse: () => unknown,
  );
}

enum IncidentPriority { high, medium, low, unknown }

class OfficerIncident {
  const OfficerIncident({
    required this.incident,
    this.priority = IncidentPriority.unknown,
    this.citizenId,
    this.citizenPhone,
    this.coordinatesProvided = true,
  });

  factory OfficerIncident.fromJson(Map<String, dynamic> json) {
    final citizen = json['citizen'];
    final user = citizen is Map ? citizen['userEntity'] : null;
    // Privacidad: en pendiente (REQUESTED) no se expone información del
    // ciudadano; solo se carga una vez aceptado el incidente.
    final isPending =
        (json['status']?.toString() ?? '') ==
        OfficerIncidentStatus.pending.apiValue;
    return OfficerIncident(
      incident: Incident.fromJson(json),
      coordinatesProvided: json['latitude'] is num && json['longitude'] is num,
      priority: switch (json['priority']) {
        'HIGH' => IncidentPriority.high,
        'MEDIUM' => IncidentPriority.medium,
        'LOW' => IncidentPriority.low,
        _ => IncidentPriority.unknown,
      },
      citizenId: isPending
          ? null
          : (citizen is Map ? citizen['id']?.toString() : null),
      citizenPhone: isPending
          ? null
          : (user is Map ? user['phone']?.toString() : null),
    );
  }

  final Incident incident;
  final IncidentPriority priority;
  final String? citizenId;
  final String? citizenPhone;
  final bool coordinatesProvided;
  String get id => incident.id;
  OfficerIncidentStatus get status =>
      OfficerIncidentStatus.parse(incident.status);

  /// La información del ciudadano solo está disponible una vez aceptado.
  bool get showsCitizenInfo => status != OfficerIncidentStatus.pending;

  /// La ruta comparada solo se obtiene en incidentes aceptados o en curso
  /// (ACCEPTED, ON_SITE); en pendientes no se consulta.
  bool get showsRoute =>
      status == OfficerIncidentStatus.enRoute ||
      status == OfficerIncidentStatus.attending;
  String get priorityLabel => switch (priority) {
    IncidentPriority.high => 'Prioridad alta',
    IncidentPriority.medium => 'Prioridad media',
    IncidentPriority.low => 'Prioridad baja',
    IncidentPriority.unknown => 'Prioridad sin informar',
  };
  bool get hasCoordinates =>
      coordinatesProvided &&
      incident.latitude.isFinite &&
      incident.longitude.isFinite &&
      incident.latitude.abs() <= 90 &&
      incident.longitude.abs() <= 180;
}
