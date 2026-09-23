import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._repository);

  final AuthRepository _repository;

  bool isLoading = false;
  bool obscurePassword = true;
  String? errorMessage;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    errorMessage = _validate(email, password);
    if (errorMessage != null) {
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();
    final result = await _repository.login(
      email: email.trim(),
      password: password,
    );
    isLoading = false;
    errorMessage = result.failure?.message;
    notifyListeners();
    return result.isSuccess;
  }

  Future<bool> loginWithGoogleIdToken(String idToken) async {
    if (idToken.trim().isEmpty) {
      errorMessage = 'Google no devolvió un token válido.';
      notifyListeners();
      return false;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    final result = await _repository.loginWithGoogleIdToken(idToken.trim());
    isLoading = false;
    errorMessage = result.failure?.message;
    notifyListeners();
    return result.isSuccess;
  }

  String? _validate(String email, String password) {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizedEmail)) {
      return 'Ingresa un correo válido.';
    }
    if (password.isEmpty) return 'Ingresa tu contraseña.';
    return null;
  }
}
