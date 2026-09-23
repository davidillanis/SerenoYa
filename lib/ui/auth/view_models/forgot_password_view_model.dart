import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  ForgotPasswordViewModel(this._repository);
  final AuthRepository _repository;

  bool isLoading = false;
  String? errorMessage;

  Future<bool> send(String email) async {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
      errorMessage = 'Ingresa un correo válido.';
      notifyListeners();
      return false;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    final result = await _repository.forgotPassword(email.trim());
    isLoading = false;
    errorMessage = result.failure?.message;
    notifyListeners();
    return result.isSuccess;
  }
}
