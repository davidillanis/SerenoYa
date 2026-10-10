import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/data/models/citizen/incident_create_request.dart';
import 'package:sereno_ya/data/models/citizen/incident.dart';
import 'package:sereno_ya/data/models/page_dto.dart';
import 'package:sereno_ya/data/models/officer/incident_acceptance.dart';
import 'package:sereno_ya/data/services/api/citizen/incidents_api_service.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';
import 'package:sereno_ya/models/auth/result.dart';

import 'package:sereno_ya/data/services/local/citizen/incident_local_data_source.dart';

class IncidentRepository {
  IncidentRepository({
    required IncidentsApiService apiService,
    required IncidentLocalDataSource localDataSource,
  }) : _apiService = apiService,
       _localDataSource = localDataSource;

  final IncidentsApiService _apiService;
  final IncidentLocalDataSource _localDataSource;

  List<IncidentCategory>? _cachedCategories;
  Future<Result<List<IncidentCategory>>>? _categoriesRequest;
  String? _cacheOwnerId;
  List<Incident>? _cachedRequestedIncidents;
  final Map<String, Incident> _incidentDetailCache = {};
  final Map<String, Future<Result<Incident>>> _incidentDetailRequests = {};
  Future<Result<List<Incident>>>? _requestedIncidentsRequest;
  List<Incident>? _cachedAvailableIncidents;
  int _availableIncidentsNextPage = 0;
  int _availableIncidentsTotalPages = 1;
  int _historyRevision = 0;

  int get historyRevision => _historyRevision;

  void useCacheForUser(String userId) {
    if (_cacheOwnerId == userId) return;
    _cacheOwnerId = userId;
    _cachedRequestedIncidents = null;
    _incidentDetailCache.clear();
    _incidentDetailRequests.clear();
    _requestedIncidentsRequest = null;
    _cachedAvailableIncidents = null;
    _availableIncidentsNextPage = 0;
    _availableIncidentsTotalPages = 1;
  }

  List<Incident>? getCachedRequestedIncidents() {
    final incidents = _cachedRequestedIncidents;
    return incidents == null ? null : List<Incident>.unmodifiable(incidents);
  }

  Incident? getCachedIncidentById(
    String incidentId, {
    bool requireAdminDetails = false,
  }) {
    final incident = _incidentDetailCache[incidentId];
    if (requireAdminDetails && incident?.adminDetailsIncluded != true) {
      return null;
    }
    return incident;
  }

  List<Incident>? getCachedAvailableIncidents() {
    final incidents = _cachedAvailableIncidents;
    return incidents == null ? null : List<Incident>.unmodifiable(incidents);
  }

  int get availableIncidentsNextPage => _availableIncidentsNextPage;
  bool get hasMoreAvailableIncidents =>
      _availableIncidentsNextPage < _availableIncidentsTotalPages;

  Future<Result<List<IncidentCategory>>> getCategories() async {
    if (_cachedCategories != null) {
      return Result.success(_cachedCategories!);
    }

    final pendingRequest = _categoriesRequest;
    if (pendingRequest != null) return pendingRequest;

    final request = _loadCategories();
    _categoriesRequest = request;
    try {
      return await request;
    } finally {
      if (identical(_categoriesRequest, request)) {
        _categoriesRequest = null;
      }
    }
  }

  Future<Result<List<IncidentCategory>>> _loadCategories() async {
    final localData = await _localDataSource.getCachedCategories();
    if (localData != null && localData.isNotEmpty) {
      _cachedCategories = localData;
      _refreshCategoriesFromApiQuietly();
      return Result.success(localData);
    }

    try {
      final response = await _apiService.getCategories();
      if (response.isSuccess && response.data != null) {
        _cachedCategories = response.data!.content;
        await _localDataSource.cacheCategories(response.data!.content);
        return Result.success(_cachedCategories!);
      }
      return Result.failure(
        AuthFailure(AuthFailureCode.server, response.errorMessage),
      );
    } on AuthFailure catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AuthFailure(AuthFailureCode.unknown, e.toString()));
    }
  }

  Future<void> _refreshCategoriesFromApiQuietly() async {
    try {
      final response = await _apiService.getCategories();
      if (response.isSuccess && response.data != null) {
        _cachedCategories = response.data!.content;
        await _localDataSource.cacheCategories(response.data!.content);
      }
    } catch (_) {
      // Ignoramos errores en el refresco en segundo plano
    }
  }

  Future<Result<Incident>> createIncident(IncidentCreateRequest request) async {
    final cacheOwnerId = _cacheOwnerId;
    try {
      final response = await _apiService.createIncident(request);
      if (response.isSuccess && response.data != null) {
        final incident = response.data!;
        if (_cacheOwnerId == cacheOwnerId) {
          _incidentDetailCache[incident.id] = incident;
          final requestedIncidents = _cachedRequestedIncidents;
          if (incident.status == 'REQUESTED' && requestedIncidents != null) {
            requestedIncidents.removeWhere((item) => item.id == incident.id);
            requestedIncidents.insert(0, incident);
          }
        }
        return Result.success(incident);
      }
      return Result.failure(
        AuthFailure(AuthFailureCode.server, response.errorMessage),
      );
    } on AuthFailure catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AuthFailure(AuthFailureCode.unknown, e.toString()));
    }
  }

  Future<Result<List<Incident>>> listMyIncidents({
    String? status,
    bool forceRefresh = false,
  }) async {
    if (status == 'REQUESTED') {
      final cachedIncidents = _cachedRequestedIncidents;
      if (!forceRefresh && cachedIncidents != null) {
        return Result.success(List<Incident>.unmodifiable(cachedIncidents));
      }

      final pendingRequest = _requestedIncidentsRequest;
      if (pendingRequest != null) return pendingRequest;

      final cacheOwnerId = _cacheOwnerId;
      final request = _fetchMyIncidents(status: status).then((result) {
        if (_cacheOwnerId == cacheOwnerId &&
            result.isSuccess &&
            result.data != null) {
          _cachedRequestedIncidents = List<Incident>.of(result.data!);
          return Result.success(
            List<Incident>.unmodifiable(_cachedRequestedIncidents!),
          );
        }
        return result;
      });
      _requestedIncidentsRequest = request;
      try {
        return await request;
      } finally {
        if (identical(_requestedIncidentsRequest, request)) {
          _requestedIncidentsRequest = null;
        }
      }
    }

    return _fetchMyIncidents(status: status);
  }

  Future<Result<List<Incident>>> _fetchMyIncidents({String? status}) async {
    try {
      const pageSize = 100;
      final incidents = <Incident>[];
      var page = 0;
      var totalPages = 1;

      while (page < totalPages) {
        final response = await _apiService.listMyIncidents(
          status: status,
          page: page,
          size: pageSize,
        );
        if (!response.isSuccess || response.data == null) {
          return Result.failure(
            AuthFailure(AuthFailureCode.server, response.errorMessage),
          );
        }

        incidents.addAll(response.data!.content);
        totalPages = response.data!.totalPages;
        page++;
      }

      return Result.success(incidents);
    } on AuthFailure catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AuthFailure(AuthFailureCode.unknown, e.toString()));
    }
  }

  Future<Result<PageResponse<Incident>>> listMyIncidentsPage({
    String? status,
    required int page,
    int size = 15,
  }) async {
    try {
      final response = await _apiService.listMyIncidents(
        status: status,
        page: page,
        size: size,
      );
      if (response.isSuccess && response.data != null) {
        return Result.success(response.data!);
      }
      return Result.failure(
        AuthFailure(AuthFailureCode.server, response.errorMessage),
      );
    } on AuthFailure catch (failure) {
      return Result.failure(failure);
    } catch (error) {
      return Result.failure(
        AuthFailure(AuthFailureCode.unknown, error.toString()),
      );
    }
  }

  Future<Result<PageResponse<Incident>>> listAllIncidentsPage({
    required int page,
    int size = 15,
    String? status,
    String? categoryId,
    String? citizenUserId,
    String? serenoUserId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final response = await _apiService.listIncidents(
        page: page,
        size: size,
        status: status,
        categoryId: categoryId,
        citizenUserId: citizenUserId,
        serenoUserId: serenoUserId,
        fromDate: fromDate,
        toDate: toDate,
      );
      if (response.isSuccess && response.data != null) {
        return Result.success(response.data!);
      }
      return Result.failure(
        AuthFailure(AuthFailureCode.server, response.errorMessage),
      );
    } on AuthFailure catch (failure) {
      return Result.failure(failure);
    } catch (error) {
      return Result.failure(
        AuthFailure(AuthFailureCode.unknown, error.toString()),
      );
    }
  }

  Future<Result<PageResponse<Incident>>> listAvailableIncidentsPage({
    required int page,
    int size = 15,
  }) async {
    final cacheOwnerId = _cacheOwnerId;
    try {
      final response = await _apiService.listAvailableIncidents(
        page: page,
        size: size,
      );
      if (response.isSuccess && response.data != null) {
        final pageResponse = response.data!;
        if (_cacheOwnerId == cacheOwnerId) {
          if (pageResponse.page == 0) {
            _cachedAvailableIncidents = List.of(pageResponse.content);
          } else {
            final incidents = _cachedAvailableIncidents ?? <Incident>[];
            final knownIds = incidents.map((incident) => incident.id).toSet();
            incidents.addAll(
              pageResponse.content.where(
                (incident) => knownIds.add(incident.id),
              ),
            );
            _cachedAvailableIncidents = incidents;
          }
          _availableIncidentsNextPage = pageResponse.page + 1;
          _availableIncidentsTotalPages = pageResponse.totalPages;
        }
        return Result.success(pageResponse);
      }
      return Result.failure(
        AuthFailure(AuthFailureCode.server, response.errorMessage),
      );
    } on AuthFailure catch (failure) {
      return Result.failure(failure);
    } catch (error) {
      return Result.failure(
        AuthFailure(AuthFailureCode.unknown, error.toString()),
      );
    }
  }

  Future<Result<IncidentAcceptance>> acceptIncident({
    required String incidentId,
    required int etaMinutes,
  }) async {
    final cacheOwnerId = _cacheOwnerId;
    try {
      final response = await _apiService.acceptIncident(
        incidentId: incidentId,
        etaMinutes: etaMinutes,
      );
      if (response.isSuccess && response.data != null) {
        if (_cacheOwnerId == cacheOwnerId) {
          _cachedAvailableIncidents?.removeWhere(
            (incident) => incident.id == incidentId,
          );
          _incidentDetailCache.remove(incidentId);
        }
        return Result.success(response.data!);
      }
      return Result.failure(
        AuthFailure(AuthFailureCode.server, response.errorMessage),
      );
    } on AuthFailure catch (failure) {
      return Result.failure(failure);
    } catch (error) {
      return Result.failure(
        AuthFailure(AuthFailureCode.unknown, error.toString()),
      );
    }
  }

  Future<Result<Incident>> getIncidentById(
    String incidentId, {
    bool forceRefresh = false,
    bool requireAdminDetails = false,
  }) async {
    final cachedIncident = getCachedIncidentById(
      incidentId,
      requireAdminDetails: requireAdminDetails,
    );
    if (!forceRefresh && cachedIncident != null) {
      return Result.success(cachedIncident);
    }

    final requestKey = requireAdminDetails ? '$incidentId:admin' : incidentId;
    final pendingRequest = _incidentDetailRequests[requestKey];
    if (pendingRequest != null) return pendingRequest;

    final cacheOwnerId = _cacheOwnerId;
    final request = _fetchIncidentById(incidentId, cacheOwnerId);
    _incidentDetailRequests[requestKey] = request;
    try {
      return await request;
    } finally {
      if (identical(_incidentDetailRequests[requestKey], request)) {
        _incidentDetailRequests.remove(requestKey);
      }
    }
  }

  Future<Result<Incident>> _fetchIncidentById(
    String incidentId,
    String? cacheOwnerId,
  ) async {
    try {
      final response = await _apiService.getIncidentById(incidentId);
      if (response.isSuccess && response.data != null) {
        final incident = response.data!;
        if (_cacheOwnerId == cacheOwnerId) {
          _incidentDetailCache[incidentId] = incident;
        }
        return Result.success(incident);
      }
      return Result.failure(
        AuthFailure(AuthFailureCode.server, response.errorMessage),
      );
    } on AuthFailure catch (failure) {
      return Result.failure(failure);
    } catch (error) {
      return Result.failure(
        AuthFailure(AuthFailureCode.unknown, error.toString()),
      );
    }
  }

  Future<Result<Incident>> cancelIncident(String incidentId) async {
    final cacheOwnerId = _cacheOwnerId;
    try {
      final response = await _apiService.updateStatus(
        incidentId: incidentId,
        status: 'CANCELLED_BY_CITIZEN',
      );
      if (response.isSuccess && response.data != null) {
        if (_cacheOwnerId == cacheOwnerId) {
          _historyRevision++;
          _incidentDetailCache.remove(incidentId);
          _cachedRequestedIncidents?.removeWhere(
            (incident) => incident.id == incidentId,
          );
        }
        return Result.success(response.data!);
      }
      return Result.failure(
        AuthFailure(AuthFailureCode.server, response.errorMessage),
      );
    } on AuthFailure catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AuthFailure(AuthFailureCode.unknown, e.toString()));
    }
  }
}
