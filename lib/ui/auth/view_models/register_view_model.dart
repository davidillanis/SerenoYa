import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository.dart';

class RegisterViewModel extends ChangeNotifier {
  RegisterViewModel(this._repository);
  final AuthRepository _repository;

  bool isLoading = false;
  String? errorMessage;

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (isLoading) return false;
    errorMessage = _validate(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    if (errorMessage != null) {
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();
    final result = await _repository.registerCitizen(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      phone: phone.trim(),
      email: email.trim(),
      password: password,
    );
    isLoading = false;
    errorMessage = result.failure?.message;
    notifyListeners();
    return result.isSuccess;
  }

  String? _validate({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) {
    if (firstName.trim().length > 60 || lastName.trim().length > 60) {
      return 'Los nombres y apellidos no deben superar los 60 caracteres.';
    }
    if (!RegExp(r'^(?:\+51)?9[0-9]{8}$').hasMatch(phone.trim())) {
      return 'El celular debe tener 9 dígitos y comenzar con 9; puede incluir +51, sin espacios.';
    }
    if (email.trim().length > 60) {
      return 'El correo electrónico no debe superar los 60 caracteres.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
      return 'Ingresa un correo válido.';
    }
    if (password.trim().isEmpty) {
      return 'La contraseña es obligatoria.';
    }
    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    if (password != passwordConfirmation) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }
}
