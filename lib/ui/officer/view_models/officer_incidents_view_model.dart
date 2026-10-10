import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/data/repositories/officer/officer_repository.dart';
import 'package:sereno_ya/data/services/maps/citizen_location_service.dart';
import 'package:sereno_ya/models/auth/auth_session.dart';

class OfficerIncidentsViewModel extends ChangeNotifier {
  OfficerIncidentsViewModel(
    this.repository,
    this._session, {
    CitizenLocationService? locationService,
  }) : _locationService = locationService ?? CitizenLocationService() {
    loadInitial();
    loadMine();
  }
  final OfficerRepository repository;
  final CitizenLocationService _locationService;
  final Set<String> _accepting = {};
  bool isAccepting(String id) => _accepting.contains(id);

  /// Acepta con la ubicación GPS actual (`POST /incident/accept`).
  Future<String?> acceptIncident(String id) async {
    if (_disposed || _session == null) return 'No hay sesión activa';
    if (!_accepting.add(id)) return 'La aceptación está en curso.';
    _notify();
    late final double latitude;
    late final double longitude;
    try {
      final position = await _locationService.currentLocation();
      latitude = position.latitude;
      longitude = position.longitude;
    } on LocationFailure catch (error) {
      _accepting.remove(id);
      _notify();
      return error.message;
    } catch (_) {
      _accepting.remove(id);
      _notify();
      return 'No se pudo obtener tu ubicación. Vuelve a intentar.';
    }
    final result = await repository.accept(
      id: id,
      latitude: latitude,
      longitude: longitude,
    );
    String? error = result.failure?.message;
    if (result.isSuccess) {
      _acceptedIds.add(id);
      final detail = await repository.detail(id);
      await synchronize(detail.data, acceptedHere: true);
      if (!detail.isSuccess) {
        error = 'Incidente aceptado, pero no se pudo cargar el detalle. Actualiza los reportes.';
      }
    }
    _accepting.remove(id);
    _notify();
    return error;
  }

  final AuthSession? _session;
  List<OfficerIncident> _incidents = [];
  List<OfficerIncident> get incidents => List.unmodifiable(_incidents);
  final Map<OfficerIncidentStatus, int> totals = {};
  // Ownership is confirmed only by a successful acceptance in this session.
  final Map<String, OfficerIncident> _accepted = {};
  final Set<String> _acceptedIds = {};
  List<OfficerIncident> get accepted => List.unmodifiable(_accepted.values);
  Set<String> get acceptedIds => Set.unmodifiable(_acceptedIds);
  // Incidentes del sereno autenticado (`GET /incident/list-me-sereno`).
  // Es la única fuente persistente de "mis incidentes": sobrevive reinicios,
  // a diferencia de [accepted], que solo cubre la sesión actual.
  List<OfficerIncident> _mine = [];
  List<OfficerIncident> get mineIncidents => List.unmodifiable(_mine);
  bool mineBusy = false;
  bool mineHasMore = false;
  String? mineError;
  OfficerIncidentStatus? filter = OfficerIncidentStatus.pending;
  bool isBusy = false;
  bool hasMore = false;
  String? errorMessage;
  String? metricsError;
  int _nextPage = 0;
  int _mineNextPage = 0;
  bool _disposed = false;
  int _generation = 0;
  int _mineGeneration = 0;
  int _metricsGeneration = 0;

  Future<void> selectFilter(OfficerIncidentStatus? value) async {
    if (_disposed) return;
    if (filter == value) return;
    filter = value;
    _generation++;
    isBusy = false;
    _incidents = [];
    await loadInitial();
  }

  Future<void> loadInitial({bool forceRefresh = false}) async {
    if (isBusy || _disposed) return;
    await _load(reset: true);
    final ids = _acceptedIds.toList();
    if (ids.isEmpty || _disposed) return;
    final results = await Future.wait(ids.map(repository.detail));
    if (_disposed) return;
    for (var i = 0; i < results.length; i++) {
      final item = results[i].data;
      if (item != null) {
        _rememberAccepted(item);
      } else {
        errorMessage = 'No se pudo actualizar uno de tus incidentes aceptados.';
      }
    }
    _notify();
  }

  void _rememberAccepted(OfficerIncident item) {
    if (item.status == OfficerIncidentStatus.attended ||
        item.status == OfficerIncidentStatus.cancelled ||
        item.status == OfficerIncidentStatus.expired) {
      _accepted.remove(item.id);
      _acceptedIds.remove(item.id);
    } else {
      _acceptedIds.add(item.id);
      _accepted[item.id] = item;
    }
  }

  Future<void> loadMore() => _load(reset: false);

  /// Mis incidentes del sereno (`GET /incident/list-me-sereno`, sin filtro).
  Future<void> loadMine() => _loadMine(reset: true);

  Future<void> loadMoreMine() => _loadMine(reset: false);

  Future<void> _loadMine({required bool reset}) async {
    if (_disposed || mineBusy || (!reset && !mineHasMore)) return;
    if (_session == null) {
      mineError = 'No hay sesión activa';
      _notify();
      return;
    }
    final generation = ++_mineGeneration;
    mineBusy = true;
    mineError = null;
    _notify();
    final result = await repository.listMine(page: reset ? 0 : _mineNextPage);
    if (_disposed || generation != _mineGeneration) return;
    if (result.isSuccess) {
      final page = result.data!;
      final items = reset
          ? <String, OfficerIncident>{}
          : {for (final item in _mine) item.id: item};
      for (final item in page.content) {
        items[item.id] = item;
      }
      _mine = items.values.toList();
      _mineNextPage = page.page + 1;
      mineHasMore = _mineNextPage < page.totalPages;
    } else {
      mineError = result.failure!.message;
    }
    mineBusy = false;
    _notify();
  }

  Future<void> _load({required bool reset}) async {
    if (_disposed || isBusy || (!reset && !hasMore)) return;
    if (_session == null) {
      errorMessage = 'No hay sesión activa';
      _notify();
      return;
    }
    final generation = ++_generation;
    isBusy = true;
    errorMessage = null;
    _notify();
    // Pendientes: bolsa general aceptable por cualquier sereno.
    // Cualquier otro filtro o "Todos": casos propios del sereno.
    final result = filter == OfficerIncidentStatus.pending
        ? await repository.list(status: filter, page: reset ? 0 : _nextPage)
        : await repository.listMine(
            status: filter,
            page: reset ? 0 : _nextPage,
          );
    if (_disposed || generation != _generation) return;
    if (result.isSuccess) {
      final page = result.data!;
      final items = reset
          ? <String, OfficerIncident>{}
          : {for (final item in _incidents) item.id: item};
      for (final item in page.content) {
        items[item.id] = item;
      }
      _incidents = items.values.toList();
      _nextPage = page.page + 1;
      hasMore = _nextPage < page.totalPages;
    } else {
      errorMessage = result.failure!.message;
    }
    isBusy = false;
    _notify();
  }

  Future<void> loadMetrics() async {
    if (_disposed || _session == null) return;
    final generation = ++_metricsGeneration;
    metricsError = null;
    final results = await Future.wait([
      for (final status in operationalStatuses)
        repository.listMine(status: status),
    ]);
    if (_disposed || generation != _metricsGeneration) return;
    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      if (result.isSuccess) {
        totals[operationalStatuses[i]] = result.data!.totalElements;
      } else {
        metricsError = 'No se pudo actualizar el resumen.';
      }
    }
    _notify();
  }

  Future<void> synchronize(
    OfficerIncident? item, {
    bool acceptedHere = false,
    String? acceptedId,
  }) async {
    if (_disposed) return;
    if (acceptedHere && acceptedId != null) _acceptedIds.add(acceptedId);
    if (item != null && (acceptedHere || _accepted.containsKey(item.id))) {
      _rememberAccepted(item);
    }
    await loadInitial(forceRefresh: true);
    await loadMine();
    await loadMetrics();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _mineGeneration++;
    super.dispose();
  }
}

const operationalStatuses = [
  OfficerIncidentStatus.pending,
  OfficerIncidentStatus.enRoute,
  OfficerIncidentStatus.attending,
  OfficerIncidentStatus.attended,
];
