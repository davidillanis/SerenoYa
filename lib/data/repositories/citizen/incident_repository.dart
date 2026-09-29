import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/data/models/citizen/incident_create_request.dart';
import 'package:sereno_ya/data/models/citizen/incident.dart';
import 'package:sereno_ya/data/services/api/citizen/incident_api_service.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';
import 'package:sereno_ya/models/auth/result.dart';

import 'package:sereno_ya/data/services/local/citizen/incident_local_data_source.dart';

class IncidentRepository {
  IncidentRepository({
    required IncidentApiService apiService,
    required IncidentLocalDataSource localDataSource,
  }) : _apiService = apiService,
       _localDataSource = localDataSource;

  final IncidentApiService _apiService;
  final IncidentLocalDataSource _localDataSource;

  List<IncidentCategory>? _cachedCategories;
  final Map<String, Incident> _incidentDetailCache = {};

  Incident? getCachedIncidentById(String incidentId) {
    return _incidentDetailCache[incidentId];
  }

  Future<Result<List<IncidentCategory>>> getCategories() async {
    // 1. Memory Cache
    if (_cachedCategories != null) {
      return Result.success(_cachedCategories!);
    }

    // 2. Local Storage Cache (SharedPreferences)
    final localData = await _localDataSource.getCachedCategories();
    if (localData != null && localData.isNotEmpty) {
      _cachedCategories = localData;

      // Opcional: Refrescar silenciosamente en background si lo deseas
      _refreshCategoriesFromApiQuietly();

      return Result.success(localData);
    }

    // 3. Remote Data Source (API)
    try {
      final response = await _apiService.getCategories();
      if (response.isSuccess && response.data != null) {
        _cachedCategories = response.data!.content;
        // Guardamos en la caché local
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
    try {
      final response = await _apiService.createIncident(request);
      if (response.isSuccess && response.data != null) {
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

  Future<Result<List<Incident>>> listMyIncidents({String? status}) async {
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

  Future<Result<Incident>> getIncidentById(
    String incidentId, {
    bool forceRefresh = false,
  }) async {
    final cachedIncident = _incidentDetailCache[incidentId];
    if (!forceRefresh && cachedIncident != null) {
      return Result.success(cachedIncident);
    }

    try {
      final response = await _apiService.getIncidentById(incidentId);
      if (response.isSuccess && response.data != null) {
        final incident = response.data!;
        _incidentDetailCache[incidentId] = incident;
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
    try {
      final response = await _apiService.updateStatus(
        incidentId: incidentId,
        status: 'CANCELLED_BY_CITIZEN',
      );
      if (response.isSuccess && response.data != null) {
        _incidentDetailCache.remove(incidentId);
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
