import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/data/models/officer/incident_citizen.dart';
import 'package:sereno_ya/data/repositories/officer/officer_repository.dart';
import 'package:sereno_ya/data/services/maps/citizen_location_service.dart';

class OfficerDetailViewModel extends ChangeNotifier {
  OfficerDetailViewModel(
    this._repository,
    this.id, {
    CitizenLocationService? locationService,
  }) : _locationService = locationService ?? CitizenLocationService() {
    load();
  }
  final OfficerRepository _repository;
  OfficerRepository get repository => _repository;
  final CitizenLocationService _locationService;
  final String id;
  OfficerIncident? item;
  IncidentCitizen? citizen;
  String? citizenError;
  bool loading = false;
  bool saving = false;
  bool acceptedHere = false;
  bool changed = false;
  bool _disposed = false;
  String? error;
  Future<void> load() async {
    if (saving || _disposed) return;
    await _load();
  }

  Future<void> _load() async {
    if (loading || _disposed) return;
    loading = true;
    error = null;
    citizen = null;
    citizenError = null;
    _notify();
    final result = await _repository.detail(id);
    if (_disposed) return;
    if (result.isSuccess) {
      item = result.data;
      if (item!.showsCitizenInfo) {
        final citizenResult = await _repository.citizenByIncidentId(id);
        if (_disposed) return;
        if (citizenResult.isSuccess) {
          citizen = citizenResult.data;
        } else {
          citizenError = citizenResult.failure!.message;
        }
      }
    } else {
      error = result.failure!.message;
    }
    loading = false;
    _notify();
  }

  /// Solo los pendientes admiten acción: aceptar con el GPS actual.
  /// La API v2 no expone llegada/atendido, así que esos estados no operan.
  Future<String?> act() async {
    if (_disposed || saving || loading || item == null) {
      return 'Espera a que termine la operación.';
    }
    if (item!.status != OfficerIncidentStatus.pending) {
      return 'Este incidente no admite esa operación.';
    }
    saving = true;
    _notify();
    late final double latitude;
    late final double longitude;
    try {
      final position = await _locationService.currentLocation();
      latitude = position.latitude;
      longitude = position.longitude;
    } on LocationFailure catch (failure) {
      if (_disposed) return failure.message;
      saving = false;
      _notify();
      return failure.message;
    } catch (_) {
      if (_disposed) return 'No se pudo obtener tu ubicación.';
      saving = false;
      _notify();
      return 'No se pudo obtener tu ubicación. Vuelve a intentar.';
    }
    final result = await _repository.accept(
      id: id,
      latitude: latitude,
      longitude: longitude,
    );
    if (_disposed) return null;
    if (result.isSuccess) {
      changed = true;
      acceptedHere = true;
      item =
          null; // Never leave stale actions enabled after a successful write.
      await _load();
    }
    saving = false;
    _notify();
    return result.failure?.message;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
