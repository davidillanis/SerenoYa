import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/models/citizen/incident.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';
import 'package:sereno_ya/models/auth/auth_session.dart';

class IncidentTrackingViewModel extends ChangeNotifier {
  IncidentTrackingViewModel({
    required IncidentRepository repository,
    required AuthSession? session,
  })  : _repository = repository,
        _session = session {
    loadActiveIncidents();
  }

  final IncidentRepository _repository;
  final AuthSession? _session;

  List<Incident> _incidents = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Incident> get incidents => _incidents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadActiveIncidents() async {
    if (_session == null) {
      _errorMessage = 'No hay sesión activa';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // El usuario nos indica que usemos el ID del usuario del token
    final citizenId = _session.user.id;
    if (citizenId.isEmpty) {
      _errorMessage = 'No se encontró el ID de usuario en la sesión';
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    final result = await _repository.listIncidents(citizenId: citizenId);

    if (result.isSuccess && result.data != null) {
      // Filtrar incidencias activas en caso de que el backend retorne todas
      final activeStatuses = ['REQUESTED', 'ACCEPTED', 'ON_SITE'];
      _incidents = result.data!.where((i) => activeStatuses.contains(i.status)).toList();
      
      // Ordenar por las más recientes primero
      _incidents.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });
    } else {
      _errorMessage = result.failure?.message ?? 'Error al cargar incidencias';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> cancelIncident(String incidentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.cancelIncident(incidentId);

    if (result.isSuccess) {
      // Recargar lista después de cancelar
      await loadActiveIncidents();
    } else {
      _isLoading = false;
      _errorMessage = result.failure?.message ?? 'No se pudo cancelar la incidencia';
      notifyListeners();
    }
  }
}
