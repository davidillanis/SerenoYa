/// Refleja `IncidentStatus` del backend.
enum IncidentStatus {
  requested('REQUESTED', 'Pendiente'),
  accepted('ACCEPTED', 'Aceptado'),
  onSite('ON_SITE', 'En recorrido'),
  attended('ATTENDED', 'Completado'),
  cancelledByCitizen('CANCELLED_BY_CITIZEN', 'Cancelado por el ciudadano'),
  expired('EXPIRED', 'Expirado');

  const IncidentStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static IncidentStatus? parse(String value) {
    for (final status in values) {
      if (status.apiValue == value) return status;
    }
    return null;
  }
}
