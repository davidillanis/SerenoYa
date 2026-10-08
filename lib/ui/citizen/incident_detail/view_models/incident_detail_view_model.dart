import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/models/citizen/incident.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';

class IncidentDetailViewModel extends ChangeNotifier {
  IncidentDetailViewModel(
    this._repository,
    this._incidentId, {
    String? cacheOwnerId,
    this.requireAssignmentDetails = false,
  }) {
    if (cacheOwnerId != null) {
      _repository.useCacheForUser(cacheOwnerId);
    }
    _incident = _repository.getCachedIncidentById(
      _incidentId,
      requireAssignmentDetails: requireAssignmentDetails,
    );
    if (_incident == null) {
      load();
    }
  }

  final IncidentRepository _repository;
  final String _incidentId;
  final bool requireAssignmentDetails;

  Incident? _incident;
  Incident? get incident => _incident;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool _disposed = false;

  Future<void> load({bool forceRefresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    _notifyListeners();

    final result = await _repository.getIncidentById(
      _incidentId,
      forceRefresh: forceRefresh,
      requireAssignmentDetails: requireAssignmentDetails,
    );
    if (result.isSuccess && result.data != null) {
      _incident = result.data;
    } else {
      _errorMessage =
          result.failure?.message ?? 'No se pudo cargar la incidencia';
    }

    _isLoading = false;
    _notifyListeners();
  }

  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
