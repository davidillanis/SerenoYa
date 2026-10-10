/// Refleja `IncidentStatus` del backend.
enum IncidentStatus {
  requested('REQUESTED'),
  accepted('ACCEPTED'),
  onSite('ON_SITE'),
  attended('ATTENDED'),
  cancelledByCitizen('CANCELLED_BY_CITIZEN'),
  expired('EXPIRED');

  const IncidentStatus(this.apiValue);

  final String apiValue;

  static IncidentStatus? parse(String value) {
    for (final status in values) {
      if (status.apiValue == value) return status;
    }
    return null;
  }
}
