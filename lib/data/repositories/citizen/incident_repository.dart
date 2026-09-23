import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/data/models/citizen/incident_create_request.dart';
import 'package:sereno_ya/data/services/api/citizen/incident_api_service.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';
import 'package:sereno_ya/models/auth/result.dart';

class IncidentRepository {
  IncidentRepository(this._apiService);

  final IncidentApiService _apiService;

  List<IncidentCategory>? _cachedCategories;

  Future<Result<List<IncidentCategory>>> getCategories() async {
    if (_cachedCategories != null) {
      return Result.success(_cachedCategories!);
    }
    
    try {
      final response = await _apiService.getCategories();
      if (response.isSuccess && response.data != null) {
        _cachedCategories = response.data;
        return Result.success(_cachedCategories!);
      }
      return Result.failure(AuthFailure(AuthFailureCode.server, response.errorMessage));
    } on AuthFailure catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AuthFailure(AuthFailureCode.unknown, e.toString()));
    }
  }

  Future<Result<String>> createIncident(IncidentCreateRequest request) async {
    try {
      final response = await _apiService.createIncident(request);
      if (response.isSuccess) {
        return Result.success(response.data ?? 'Incidente creado');
      }
      return Result.failure(AuthFailure(AuthFailureCode.server, response.errorMessage));
    } on AuthFailure catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AuthFailure(AuthFailureCode.unknown, e.toString()));
    }
  }
}
