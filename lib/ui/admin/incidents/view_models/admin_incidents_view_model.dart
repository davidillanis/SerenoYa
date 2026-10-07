import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/models/citizen/incident.dart';
import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';

class AdminIncidentsViewModel extends ChangeNotifier {
  AdminIncidentsViewModel(this._repository, {String? cacheOwnerId}) {
    if (cacheOwnerId != null) {
      _repository.useCacheForUser(cacheOwnerId);
    }
    loadInitial();
    _loadCategories();
  }

  static const pageSize = 15;

  final IncidentRepository _repository;
  final List<Incident> _incidents = [];
  List<IncidentCategory> _categories = [];
  AdminIncidentFilters _filters = const AdminIncidentFilters();

  List<Incident> get incidents => List.unmodifiable(_incidents);
  List<IncidentCategory> get categories => List.unmodifiable(_categories);
  AdminIncidentFilters get filters => _filters;
  bool isLoadingInitial = false;
  bool isLoadingMore = false;
  bool get isBusy => isLoadingInitial || isLoadingMore;
  bool hasMore = true;
  int totalElements = 0;
  String? errorMessage;
  String? loadMoreError;
  String? filterOptionsError;

  int _nextPage = 0;
  int _generation = 0;
  bool _disposed = false;

  Future<void> loadInitial({bool forceRefresh = false}) async {
    if (_disposed || isLoadingInitial || isLoadingMore) return;
    if (_incidents.isNotEmpty && !forceRefresh) return;

    final generation = ++_generation;
    isLoadingInitial = true;
    errorMessage = null;
    loadMoreError = null;
    _notify();

    final result = await _repository.listAllIncidentsPage(
      page: 0,
      size: pageSize,
      status: _filters.status?.apiValue,
      categoryId: _filters.categoryId,
      citizenUserId: _filters.citizenUserId,
      serenoUserId: _filters.serenoUserId,
      fromDate: _filters.fromDate,
      toDate: _filters.toDate,
    );
    if (_disposed || generation != _generation) return;

    if (result.isSuccess && result.data != null) {
      final page = result.data!;
      _incidents
        ..clear()
        ..addAll(page.content);
      _nextPage = page.page + 1;
      totalElements = page.totalElements;
      hasMore = _nextPage < page.totalPages;
    } else {
      errorMessage =
          result.failure?.message ?? 'No se pudieron cargar las incidencias.';
    }

    isLoadingInitial = false;
    _notify();
  }

  Future<void> loadMore() async {
    if (_disposed ||
        isLoadingInitial ||
        isLoadingMore ||
        !hasMore ||
        loadMoreError != null) {
      return;
    }

    final generation = _generation;
    isLoadingMore = true;
    _notify();

    final result = await _repository.listAllIncidentsPage(
      page: _nextPage,
      size: pageSize,
      status: _filters.status?.apiValue,
      categoryId: _filters.categoryId,
      citizenUserId: _filters.citizenUserId,
      serenoUserId: _filters.serenoUserId,
      fromDate: _filters.fromDate,
      toDate: _filters.toDate,
    );
    if (_disposed || generation != _generation) return;

    if (result.isSuccess && result.data != null) {
      final page = result.data!;
      final knownIds = _incidents.map((incident) => incident.id).toSet();
      _incidents.addAll(
        page.content.where((incident) => knownIds.add(incident.id)),
      );
      _nextPage = page.page + 1;
      totalElements = page.totalElements;
      hasMore = _nextPage < page.totalPages;
      loadMoreError = null;
    } else {
      loadMoreError =
          result.failure?.message ?? 'No se pudieron cargar más incidencias.';
    }

    isLoadingMore = false;
    _notify();
  }

  Future<void> retryLoadMore() async {
    loadMoreError = null;
    await loadMore();
  }

  Future<void> applyFilters(AdminIncidentFilters filters) async {
    if (_disposed || filters.sameValuesAs(_filters)) return;
    _generation++;
    isLoadingMore = false;
    _filters = filters;
    _incidents.clear();
    totalElements = 0;
    hasMore = true;
    _nextPage = 0;
    await loadInitial(forceRefresh: true);
  }

  Future<void> clearFilters() => applyFilters(const AdminIncidentFilters());

  String? categoryName(String? categoryId) {
    if (categoryId == null) return null;
    for (final category in _categories) {
      if (category.id == categoryId) return category.name;
    }
    return 'Categoría seleccionada';
  }

  Future<void> _loadCategories() async {
    filterOptionsError = null;
    final result = await _repository.getCategories();
    if (_disposed) return;
    if (result.isSuccess && result.data != null) {
      _categories = List.of(result.data!);
    } else {
      filterOptionsError =
          result.failure?.message ?? 'No se pudieron cargar las categorías.';
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}

enum AdminIncidentStatusFilter {
  requested('REQUESTED', 'Solicitada'),
  accepted('ACCEPTED', 'Aceptada'),
  onSite('ON_SITE', 'En el lugar'),
  attended('ATTENDED', 'Atendida'),
  cancelled('CANCELLED_BY_CITIZEN', 'Cancelada'),
  expired('EXPIRED', 'Expirada');

  const AdminIncidentStatusFilter(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

class AdminIncidentFilters {
  const AdminIncidentFilters({
    this.status,
    this.categoryId,
    this.citizenUserId,
    this.serenoUserId,
    this.fromDate,
    this.toDate,
  });

  final AdminIncidentStatusFilter? status;
  final String? categoryId;
  final String? citizenUserId;
  final String? serenoUserId;
  final DateTime? fromDate;
  final DateTime? toDate;

  bool get isEmpty => activeCount == 0;

  int get activeCount {
    var count = [
      status,
      categoryId,
      citizenUserId,
      serenoUserId,
    ].where((value) => value != null).length;
    if (fromDate != null || toDate != null) count++;
    return count;
  }

  bool sameValuesAs(AdminIncidentFilters other) =>
      status == other.status &&
      categoryId == other.categoryId &&
      citizenUserId == other.citizenUserId &&
      serenoUserId == other.serenoUserId &&
      _sameDate(fromDate, other.fromDate) &&
      _sameDate(toDate, other.toDate);

  static bool _sameDate(DateTime? left, DateTime? right) {
    if (left == null || right == null) return left == right;
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
