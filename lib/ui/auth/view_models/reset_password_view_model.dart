import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository.dart';

class ResetPasswordViewModel extends ChangeNotifier {
  ResetPasswordViewModel(this._repository);
  final AuthRepository _repository;

  bool isLoading = false;
  String? errorMessage;

  Future<bool> reset({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (email.trim().isEmpty || token.trim().isEmpty) {
      errorMessage = 'El correo y el código son obligatorios.';
    } else if (password.length < 6) {
      errorMessage = 'La contraseña debe tener al menos 6 caracteres.';
    } else if (password != passwordConfirmation) {
      errorMessage = 'Las contraseñas no coinciden.';
    } else {
      errorMessage = null;
    }
    if (errorMessage != null) {
      notifyListeners();
      return false;
    }

    isLoading = true;
    notifyListeners();
    final result = await _repository.resetPassword(
      email: email.trim(),
      token: token.trim(),
      newPassword: password,
    );
    isLoading = false;
    errorMessage = result.failure?.message;
    notifyListeners();
    return result.isSuccess;
  }
}
