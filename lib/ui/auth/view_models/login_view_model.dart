import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/services/auth/google_identity_service.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel(
    this._repository, {
    this._googleIdentityService,
    this._onLoginSuccess,
  });

  final Future<void> Function()? _onLoginSuccess;

  Future<void> _registerDevice() async {
    try {
      await _onLoginSuccess?.call();
    } on Object {
      debugPrint('No se pudo registrar el dispositivo tras iniciar sesión.');
    }
  }

  final GoogleIdentityService? _googleIdentityService;
  bool _disposed = false;
  bool isGoogleLoading = false;
  bool get canLoginWithGoogle =>
      _googleIdentityService != null &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<bool> loginWithGoogle() async {
    if (isLoading || _disposed) return false;
    isLoading = true;
    isGoogleLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final service = _googleIdentityService;
      if (service == null) {
        throw const GoogleIdentityException(
          'El acceso con Google no está disponible.',
        );
      }
      final token = await service.authenticateForIdToken();
      if (_disposed || token == null) return false;
      if (token.trim().isEmpty) {
        throw const GoogleIdentityException(
          'Google no devolvió un token válido.',
        );
      }
      final result = await _repository.loginWithGoogleIdToken(token.trim());
      if (result.isSuccess) unawaited(_registerDevice());
      errorMessage = result.failure?.message;
      return result.isSuccess;
    } on GoogleIdentityException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage =
          'No se pudo iniciar sesión con Google. Inténtalo nuevamente.';
      return false;
    } finally {
      isLoading = false;
      isGoogleLoading = false;
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  final AuthRepository _repository;

  bool isLoading = false;
  bool obscurePassword = true;
  String? errorMessage;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    if (isLoading || _disposed) return false;
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
    if (result.isSuccess) unawaited(_registerDevice());
    isLoading = false;
    errorMessage = result.failure?.message;
    notifyListeners();
    return result.isSuccess;
  }

  Future<bool> loginWithGoogleIdToken(String idToken) async {
    if (isLoading || _disposed) return false;
    if (idToken.trim().isEmpty) {
      errorMessage = 'Google no devolvió un token válido.';
      notifyListeners();
      return false;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    final result = await _repository.loginWithGoogleIdToken(idToken.trim());
    if (result.isSuccess) unawaited(_registerDevice());
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
