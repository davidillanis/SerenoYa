import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/models/admin/admin_created_user.dart';
import 'package:sereno_ya/data/models/admin/admin_user_create_request.dart';
import 'package:sereno_ya/data/services/api/admin/admin_user_api_service.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';

class AdminUserCreateViewModel extends ChangeNotifier {
  AdminUserCreateViewModel(this._apiService);

  final AdminUserApiService _apiService;

  bool isSubmitting = false;
  String? errorMessage;

  Future<AdminCreatedUser?> createUser(AdminUserCreateRequest request) async {
    if (isSubmitting) return null;
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.createUser(request);
      if (!response.isSuccess || response.data == null) {
        errorMessage = response.errorMessage;
        return null;
      }
      return response.data;
    } on AuthFailure catch (failure) {
      errorMessage = failure.message;
      return null;
    } catch (_) {
      errorMessage = 'No se pudo registrar al usuario.';
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
