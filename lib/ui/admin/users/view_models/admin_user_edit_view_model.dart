import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/models/admin/admin_user_detail.dart';
import 'package:sereno_ya/data/models/admin/admin_user_update_request.dart';
import 'package:sereno_ya/data/services/api/admin/admin_user_api_service.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';

class AdminUserEditViewModel extends ChangeNotifier {
  AdminUserEditViewModel(this._apiService, this.userId) {
    load();
  }

  final AdminUserApiService _apiService;
  final String userId;

  AdminUserDetail? user;
  bool isLoading = false;
  bool isSubmitting = false;
  String? loadError;
  String? submitError;
  bool _disposed = false;

  Future<void> load() async {
    if (_disposed || isLoading) return;
    isLoading = true;
    loadError = null;
    _notify();
    try {
      final response = await _apiService.getUser(userId);
      if (_disposed) return;
      if (!response.isSuccess || response.data == null) {
        loadError = response.errorMessage;
        return;
      }
      user = response.data;
    } on AuthFailure catch (failure) {
      if (!_disposed) {
        loadError = failure.message;
      }
    } catch (_) {
      if (!_disposed) {
        loadError = 'No se pudo cargar la información del usuario.';
      }
    } finally {
      if (!_disposed) {
        isLoading = false;
        _notify();
      }
    }
  }

  Future<bool> update(AdminUserUpdateRequest request) async {
    if (_disposed || isSubmitting) return false;
    isSubmitting = true;
    submitError = null;
    _notify();
    try {
      final response = await _apiService.updateUser(userId, request);
      if (_disposed) return false;
      if (!response.isSuccess) {
        submitError = response.errorMessage;
        return false;
      }
      return true;
    } on AuthFailure catch (failure) {
      if (!_disposed) {
        submitError = failure.message;
      }
      return false;
    } catch (_) {
      if (!_disposed) {
        submitError = 'No se pudo actualizar el usuario.';
      }
      return false;
    } finally {
      if (!_disposed) {
        isSubmitting = false;
        _notify();
      }
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
