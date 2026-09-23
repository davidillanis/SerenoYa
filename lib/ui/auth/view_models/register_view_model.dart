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
    required String dni,
    required String phone,
    required String address,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    errorMessage = _validate(
      firstName: firstName,
      lastName: lastName,
      dni: dni,
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
      dni: dni.trim(),
      phone: phone.trim(),
      address: (address.isEmpty ? 'San Jerónimo' : address).trim(),
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
    required String dni,
    required String phone,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) {
    if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
      return 'Ingresa tus nombres y apellidos.';
    }
    if (!RegExp(r'^\d{8}$').hasMatch(dni.trim())) {
      return 'El DNI debe contener 8 dígitos.';
    }
    if (!RegExp(r'^\d{9}$').hasMatch(phone.trim())) {
      return 'El teléfono debe contener 9 dígitos.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
      return 'Ingresa un correo válido.';
    }
    if (password.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (password != passwordConfirmation) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }
}
