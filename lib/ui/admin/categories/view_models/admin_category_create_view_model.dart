import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/models/admin/admin_category_create_request.dart';
import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';
import 'package:sereno_ya/data/services/api/citizen/incidents_api_service.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';

class AdminCategoryCreateViewModel extends ChangeNotifier {
  AdminCategoryCreateViewModel(this._apiService, this._incidentRepository);

  final IncidentsApiService _apiService;
  final IncidentRepository _incidentRepository;

  bool isSubmitting = false;
  String? errorMessage;

  Future<IncidentCategory?> createCategory(
    AdminCategoryCreateRequest request,
  ) async {
    if (isSubmitting) return null;
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.createCategory(request);
      if (!response.isSuccess || response.data == null) {
        errorMessage = response.errorMessage;
        return null;
      }
      await _incidentRepository.invalidateCategoriesCache();
      return response.data;
    } on AuthFailure catch (failure) {
      errorMessage = failure.message;
      return null;
    } catch (_) {
      errorMessage = 'No se pudo crear la categoría.';
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
