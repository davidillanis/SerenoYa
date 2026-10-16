import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/models/admin/admin_category_update_request.dart';
import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';
import 'package:sereno_ya/data/services/api/citizen/incidents_api_service.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';

class AdminCategoriesViewModel extends ChangeNotifier {
  AdminCategoriesViewModel(this._apiService, this._incidentRepository) {
    loadInitial();
  }

  static const pageSize = 100;

  final IncidentsApiService _apiService;
  final IncidentRepository _incidentRepository;
  final List<IncidentCategory> _categories = [];

  List<IncidentCategory> get categories => List.unmodifiable(_categories);
  bool isLoading = false;
  String? errorMessage;
  String? updatingCategoryId;
  String? updateError;
  int totalElements = 0;

  bool _disposed = false;

  Future<void> loadInitial({bool forceRefresh = false}) async {
    if (_disposed || isLoading) return;
    if (_categories.isNotEmpty && !forceRefresh) return;

    isLoading = true;
    errorMessage = null;
    _notify();
    try {
      final response = await _apiService.getCategories(size: pageSize);
      if (_disposed) return;
      if (response.isSuccess && response.data != null) {
        final page = response.data!;
        _categories
          ..clear()
          ..addAll(page.content);
        totalElements = page.totalElements;
      } else {
        errorMessage = response.errorMessage;
      }
    } on AuthFailure catch (failure) {
      if (!_disposed) errorMessage = failure.message;
    } catch (_) {
      if (!_disposed) errorMessage = 'No se pudieron cargar las categorías.';
    } finally {
      if (!_disposed) {
        isLoading = false;
        _notify();
      }
    }
  }

  Future<bool> updateCategory(
    String categoryId,
    AdminCategoryUpdateRequest request,
  ) async {
    if (_disposed || updatingCategoryId != null) return false;
    updatingCategoryId = categoryId;
    updateError = null;
    _notify();
    try {
      final response = await _apiService.updateCategory(categoryId, request);
      if (_disposed) return false;
      if (!response.isSuccess || response.data == null) {
        updateError = response.errorMessage;
        return false;
      }
      final index = _categories.indexWhere(
        (category) => category.id == categoryId,
      );
      if (index >= 0) _categories[index] = response.data!;
      await _incidentRepository.invalidateCategoriesCache();
      return true;
    } on AuthFailure catch (failure) {
      if (!_disposed) updateError = failure.message;
      return false;
    } catch (_) {
      if (!_disposed) updateError = 'No se pudo actualizar la categoría.';
      return false;
    } finally {
      if (!_disposed) {
        updatingCategoryId = null;
        _notify();
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
