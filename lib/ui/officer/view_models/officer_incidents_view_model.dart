import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/models/citizen/incident.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';
import 'package:sereno_ya/models/auth/auth_session.dart';

class OfficerIncidentsViewModel extends ChangeNotifier {
  OfficerIncidentsViewModel(this._repository, this._session) {
    final userId = _session?.user.id;
    if (userId != null) {
      _repository.useCacheForUser(userId);
    }
    final cachedIncidents = _repository.getCachedAvailableIncidents();
    if (cachedIncidents == null) {
      loadInitial();
    } else {
      _incidents = cachedIncidents;
      _nextPage = _repository.availableIncidentsNextPage;
      _hasMore = _repository.hasMoreAvailableIncidents;
      _hasLoaded = true;
    }
  }

  static const pageSize = 15;

  final IncidentRepository _repository;
  final AuthSession? _session;
  final Set<String> _acceptingIds = {};

  List<Incident> _incidents = [];
  int _nextPage = 0;
  bool _hasMore = true;
  bool _hasLoaded = false;
  bool _isLoadingInitial = false;
  bool _isLoadingMore = false;
  bool _disposed = false;
  String? _errorMessage;
  String? _loadMoreError;

  List<Incident> get incidents => List.unmodifiable(_incidents);
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isLoadingMore => _isLoadingMore;
  bool get isBusy => _isLoadingInitial || _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  String? get loadMoreError => _loadMoreError;
  bool isAccepting(String incidentId) => _acceptingIds.contains(incidentId);

  Future<void> loadInitial({bool forceRefresh = false}) async {
    if (_isLoadingInitial || _isLoadingMore) return;
    if (_hasLoaded && !forceRefresh) return;
    if (_session == null) {
      _errorMessage = 'No hay sesión activa';
      _notifyListeners();
      return;
    }

    _isLoadingInitial = true;
    _errorMessage = null;
    _loadMoreError = null;
    _notifyListeners();

    final result = await _repository.listAvailableIncidentsPage(
      page: 0,
      size: pageSize,
    );
    if (result.isSuccess && result.data != null) {
      final page = result.data!;
      _incidents = _repository.getCachedAvailableIncidents() ?? page.content;
      _nextPage = page.page + 1;
      _hasMore = _nextPage < page.totalPages;
      _hasLoaded = true;
    } else {
      _errorMessage =
          result.failure?.message ?? 'No se pudieron cargar las incidencias';
    }

    _isLoadingInitial = false;
    _notifyListeners();
  }

  Future<void> loadMore() async {
    if (!_hasLoaded ||
        !_hasMore ||
        _isLoadingInitial ||
        _isLoadingMore ||
        _loadMoreError != null) {
      return;
    }

    _isLoadingMore = true;
    _notifyListeners();
    final result = await _repository.listAvailableIncidentsPage(
      page: _nextPage,
      size: pageSize,
    );
    if (result.isSuccess && result.data != null) {
      final page = result.data!;
      _incidents = _repository.getCachedAvailableIncidents() ?? _incidents;
      _nextPage = page.page + 1;
      _hasMore = _nextPage < page.totalPages;
      _loadMoreError = null;
    } else {
      _loadMoreError =
          result.failure?.message ?? 'No se pudieron cargar más incidencias';
    }
    _isLoadingMore = false;
    _notifyListeners();
  }

  Future<void> retryLoadMore() async {
    _loadMoreError = null;
    await loadMore();
  }

  Future<String?> acceptIncident(String incidentId, int etaMinutes) async {
    if (_acceptingIds.contains(incidentId)) return null;
    _acceptingIds.add(incidentId);
    _notifyListeners();

    final result = await _repository.acceptIncident(
      incidentId: incidentId,
      etaMinutes: etaMinutes,
    );
    _acceptingIds.remove(incidentId);
    if (result.isSuccess) {
      _incidents =
          _repository.getCachedAvailableIncidents() ??
          _incidents
              .where((incident) => incident.id != incidentId)
              .toList(growable: false);
      _notifyListeners();
      return null;
    }

    _notifyListeners();
    return result.failure?.message ?? 'No se pudo aceptar la incidencia';
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
