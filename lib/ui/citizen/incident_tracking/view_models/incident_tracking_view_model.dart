import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/models/citizen/incident.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';
import 'package:sereno_ya/models/auth/auth_session.dart';

class IncidentTrackingViewModel extends ChangeNotifier {
  IncidentTrackingViewModel({
    required IncidentRepository repository,
    required AuthSession? session,
  }) : _repository = repository,
       _session = session {
    final userId = session?.user.id;
    if (userId != null) {
      _repository.useCacheForUser(userId);
    }
    final cachedIncidents = _repository.getCachedRequestedIncidents();
    if (cachedIncidents == null) {
      loadActiveIncidents();
    } else {
      _incidents = cachedIncidents;
    }
  }

  final IncidentRepository _repository;
  final AuthSession? _session;

  List<Incident> _incidents = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Incident> get incidents => _incidents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool _disposed = false;

  Future<void> loadActiveIncidents({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (_session == null) {
      _errorMessage = 'No hay sesión activa';
      _notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _notifyListeners();

    final result = await _repository.listMyIncidents(
      status: 'REQUESTED',
      forceRefresh: forceRefresh,
    );

    if (result.isSuccess && result.data != null) {
      _incidents = result.data!;
    } else {
      _errorMessage = result.failure?.message ?? 'Error al cargar incidencias';
    }

    _isLoading = false;
    _notifyListeners();
  }

  void syncFromCache() {
    final cachedIncidents = _repository.getCachedRequestedIncidents();
    if (cachedIncidents == null) return;
    _incidents = cachedIncidents;
    _errorMessage = null;
    _notifyListeners();
  }

  Future<void> cancelIncident(String incidentId) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    _notifyListeners();

    final result = await _repository.cancelIncident(incidentId);

    if (result.isSuccess) {
      _incidents = _incidents
          .where((incident) => incident.id != incidentId)
          .toList(growable: false);
      _isLoading = false;
      _notifyListeners();
    } else {
      _isLoading = false;
      _errorMessage =
          result.failure?.message ?? 'No se pudo cancelar la incidencia';
      _notifyListeners();
    }
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
