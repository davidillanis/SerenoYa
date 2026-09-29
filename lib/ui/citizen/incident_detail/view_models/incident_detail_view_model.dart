import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/models/citizen/incident.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';

class IncidentDetailViewModel extends ChangeNotifier {
  IncidentDetailViewModel(this._repository, this._incidentId)
    : _incident = _repository.getCachedIncidentById(_incidentId) {
    if (_incident == null) {
      load();
    }
  }

  final IncidentRepository _repository;
  final String _incidentId;

  Incident? _incident;
  Incident? get incident => _incident;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> load({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getIncidentById(
      _incidentId,
      forceRefresh: forceRefresh,
    );
    if (result.isSuccess && result.data != null) {
      _incident = result.data;
    } else {
      _errorMessage =
          result.failure?.message ?? 'No se pudo cargar la incidencia';
    }

    _isLoading = false;
    notifyListeners();
  }
}
