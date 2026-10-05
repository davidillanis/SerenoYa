import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:url_launcher/url_launcher.dart';

class RouteService {
  Future<bool> open(OfficerIncident item) async {
    if (!item.hasCoordinates) return false;
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${item.incident.latitude},${item.incident.longitude}',
      'travelmode': 'driving',
    });
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
