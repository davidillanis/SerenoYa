import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/models/citizen/incident.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';
import 'package:sereno_ya/models/auth/auth_session.dart';

enum IncidentHistoryFilter { all, attended, cancelled, expired }

extension IncidentHistoryFilterPresentation on IncidentHistoryFilter {
  String get label => switch (this) {
    IncidentHistoryFilter.all => 'Todas',
    IncidentHistoryFilter.attended => 'Atendidas',
    IncidentHistoryFilter.cancelled => 'Canceladas',
    IncidentHistoryFilter.expired => 'Expiradas',
  };

  String? get status => switch (this) {
    IncidentHistoryFilter.all => null,
    IncidentHistoryFilter.attended => 'ATTENDED',
    IncidentHistoryFilter.cancelled => 'CANCELLED_BY_CITIZEN',
    IncidentHistoryFilter.expired => 'EXPIRED',
  };

  List<String>? get statuses => switch (this) {
    IncidentHistoryFilter.all => const [
      'ATTENDED',
      'CANCELLED_BY_CITIZEN',
      'EXPIRED',
    ],
    _ => null,
  };
}

class IncidentHistoryViewModel extends ChangeNotifier {
  IncidentHistoryViewModel(this._repository, this._session) {
    final userId = _session?.user.id;
    if (userId != null) {
      _repository.useCacheForUser(userId);
    }
    _observedHistoryRevision = _repository.historyRevision;
  }

  static const pageSize = 15;

  final IncidentRepository _repository;
  final AuthSession? _session;
  final Map<IncidentHistoryFilter, _HistoryPageState> _states = {};

  IncidentHistoryFilter _selectedFilter = IncidentHistoryFilter.all;
  bool _isLoadingInitial = false;
  bool _isLoadingMore = false;
  bool _disposed = false;
  late int _observedHistoryRevision;

  IncidentHistoryFilter get selectedFilter => _selectedFilter;
  List<Incident> get incidents =>
      List<Incident>.unmodifiable(_currentState.incidents);
  bool get hasMore => _currentState.hasMore;
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isLoadingMore => _isLoadingMore;
  bool get isBusy => _isLoadingInitial || _isLoadingMore;
  String? get errorMessage => _currentState.errorMessage;
  String? get loadMoreError => _currentState.loadMoreError;

  _HistoryPageState get _currentState =>
      _states.putIfAbsent(_selectedFilter, _HistoryPageState.new);

  Future<void> selectFilter(IncidentHistoryFilter filter) async {
    if (filter == _selectedFilter || isBusy) return;

    _synchronizeCacheRevision();
    _selectedFilter = filter;
    _notifyListeners();
    await loadInitial();
  }

  Future<void> loadInitial({bool forceRefresh = false}) async {
    if (_isLoadingInitial || _isLoadingMore) return;
    _synchronizeCacheRevision();

    final state = _currentState;
    if (state.hasLoaded && !forceRefresh) return;
    if (_session == null) {
      state.errorMessage = 'No hay sesión activa';
      _notifyListeners();
      return;
    }

    _isLoadingInitial = true;
    state.errorMessage = null;
    state.loadMoreError = null;
    _notifyListeners();

    final result = await _repository.listMyIncidentsPage(
      status: _selectedFilter.status,
      statuses: _selectedFilter.statuses,
      page: 0,
      size: pageSize,
    );

    if (result.isSuccess && result.data != null) {
      final page = result.data!;
      state.incidents = List.of(page.content);
      state.nextPage = page.page + 1;
      state.hasMore = state.nextPage < page.totalPages;
      state.hasLoaded = true;
      if (forceRefresh) {
        _states.removeWhere((filter, _) => filter != _selectedFilter);
      }
    } else {
      state.errorMessage =
          result.failure?.message ?? 'Error al cargar el historial';
    }

    _isLoadingInitial = false;
    _notifyListeners();
  }

  Future<void> loadMore() async {
    final state = _currentState;
    if (!state.hasLoaded ||
        !state.hasMore ||
        _isLoadingInitial ||
        _isLoadingMore ||
        state.loadMoreError != null) {
      return;
    }

    _isLoadingMore = true;
    _notifyListeners();

    final result = await _repository.listMyIncidentsPage(
      status: _selectedFilter.status,
      statuses: _selectedFilter.statuses,
      page: state.nextPage,
      size: pageSize,
    );

    if (result.isSuccess && result.data != null) {
      final page = result.data!;
      final knownIds = state.incidents.map((incident) => incident.id).toSet();
      state.incidents = [
        ...state.incidents,
        ...page.content.where((incident) => knownIds.add(incident.id)),
      ];
      state.nextPage = page.page + 1;
      state.hasMore = state.nextPage < page.totalPages;
      state.loadMoreError = null;
    } else {
      state.loadMoreError =
          result.failure?.message ?? 'No se pudo cargar más incidencias';
    }

    _isLoadingMore = false;
    _notifyListeners();
  }

  Future<void> retryLoadMore() async {
    _currentState.loadMoreError = null;
    await loadMore();
  }

  void _synchronizeCacheRevision() {
    final revision = _repository.historyRevision;
    if (_observedHistoryRevision == revision) return;
    _states.clear();
    _observedHistoryRevision = revision;
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

class _HistoryPageState {
  List<Incident> incidents = [];
  int nextPage = 0;
  bool hasLoaded = false;
  bool hasMore = true;
  String? errorMessage;
  String? loadMoreError;
}
