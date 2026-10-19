import 'package:sereno_ya/data/services/maps/citizen_location_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Busca comisarías alrededor de la ubicación actual en Google Maps.
class NearbyPoliceService {
  NearbyPoliceService({CitizenLocationService? locationService})
    : _locationService = locationService ?? CitizenLocationService();

  final CitizenLocationService _locationService;

  Future<bool> openNearby() async {
    final position = await _locationService.currentLocation();
    final uri = nearbyPoliceUri(position.latitude, position.longitude);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

Uri nearbyPoliceUri(double latitude, double longitude) => Uri.https(
  'www.google.com',
  '/maps/search/',
  {'api': '1', 'query': 'comisarías cerca de $latitude,$longitude'},
);
