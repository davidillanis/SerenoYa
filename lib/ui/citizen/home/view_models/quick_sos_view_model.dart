import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sereno_ya/data/models/citizen/incident_create_request.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';
import 'package:sereno_ya/data/services/maps/citizen_location_service.dart';

class QuickSosViewModel extends ChangeNotifier {
  QuickSosViewModel(this._repository, {CitizenLocationService? locationService})
    : _locationService = locationService ?? CitizenLocationService();

  final IncidentRepository _repository;
  final CitizenLocationService _locationService;

  // Punto de referencia en San Jerónimo; nunca se muestra como GPS real.
  static const fallbackLocation = LatLng(-13.65, -73.36);
  static const _referenceEvidence = IncidentEvidenceCreateRequest(
    fileUrl: 'https://cdn-icons-png.flaticon.com/128/9356/9356599.png',
    fileName: '9356599.png',
    fileType: 'image/png',
  );

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _usedFallbackLocation = false;
  bool get usedFallbackLocation => _usedFallbackLocation;

  Future<bool> submit() async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _errorMessage = null;
    _usedFallbackLocation = false;
    notifyListeners();

    try {
      LatLng location;
      try {
        location = await _locationService.currentLocation();
      } catch (_) {
        location = fallbackLocation;
        _usedFallbackLocation = true;
      }

      final result = await _repository.createIncident(
        IncidentCreateRequest(
          description: _usedFallbackLocation
              ? 'Alerta SOS desde la app ciudadana. Ubicación no verificada: '
                    'se usó un punto de referencia.'
              : 'Alerta SOS desde la app ciudadana.',
          referenceAddress: _usedFallbackLocation
              ? 'Punto de referencia en San Jerónimo; ubicación real desconocida'
              : 'Ubicación obtenida por GPS (sin dirección verificada)',
          latitude: location.latitude,
          longitude: location.longitude,
          currentLat: location.latitude,
          currentLong: location.longitude,
          categoryName: 'Emergencia',
          evidences: const [_referenceEvidence],
        ),
      );
      if (!result.isSuccess) {
        _errorMessage = result.failure?.message ?? 'No se pudo enviar el SOS.';
        return false;
      }
      return true;
    } catch (_) {
      _errorMessage = 'No se pudo enviar el SOS. Inténtalo de nuevo.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
