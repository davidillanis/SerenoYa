import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/models/notification_model.dart';
import 'package:sereno_ya/data/services/api/device_api_service.dart';
import 'package:sereno_ya/data/services/api/device_token_service.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';

class ProfileNotificationsViewModel extends ChangeNotifier {
  ProfileNotificationsViewModel({
    required DeviceApiService apiService,
    required DeviceTokenService deviceTokens,
    required Future<String?> Function() readToken,
  }) : _api = apiService,
       _tokens = deviceTokens,
       _getToken = readToken;

  final DeviceApiService _api;
  final DeviceTokenService _tokens;
  final Future<String?> Function() _getToken;

  bool _isUpdatingToken = false;
  bool get isUpdatingToken => _isUpdatingToken;

  bool _isSendingTest = false;
  bool get isSendingTest => _isSendingTest;

  bool get isBusy => _isUpdatingToken || _isSendingTest;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  bool _disposed = false;

  Future<bool> updateToken() => _run(
    _tokens.updateToken,
    updatingToken: true,
    successMessage: 'Token actualizado en el servidor.',
  );

  Future<bool> sendTestNotification() => _run(
    (token) async {
      final response = await _api.sendNotification(
        NotificationRequest(
          token: token,
          title: 'Prueba de SerenoYa',
          body:
              'Esta es una notificación de prueba para comprobar los avisos '
              'y el sonido en tu dispositivo.',
        ),
      );
      if (!response.isSuccess) {
        throw AuthFailure(AuthFailureCode.server, response.errorMessage);
      }
      if (response.data == null || response.data!.isEmpty) {
        throw const AuthFailure(
          AuthFailureCode.server,
          'El servidor no confirmó el envío de la notificación.',
        );
      }
    },
    updatingToken: false,
    successMessage:
        'Prueba enviada. Comprueba si recibiste la notificación '
        'en este dispositivo.',
  );

  Future<bool> _run(
    Future<void> Function(String token) action, {
    required bool updatingToken,
    required String successMessage,
  }) async {
    if (isBusy || _disposed) return false;
    _isUpdatingToken = updatingToken;
    _isSendingTest = !updatingToken;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (_disposed) return false;
      if (token == null || token.trim().isEmpty) {
        throw const AuthFailure(
          AuthFailureCode.validation,
          'Token FCM no disponible. Abre la app en un dispositivo Android '
          'o iOS con conexión e inténtalo de nuevo.',
        );
      }
      await action(token);
      if (_disposed) return false;
      _successMessage = successMessage;
      return true;
    } on AuthFailure catch (failure) {
      if (!_disposed) _errorMessage = failure.message;
      return false;
    } on Object {
      if (!_disposed) {
        _errorMessage = updatingToken
            ? 'No se pudo actualizar el token. Inténtalo de nuevo.'
            : 'No se pudo enviar la notificación de prueba. Inténtalo de nuevo.';
      }
      return false;
    } finally {
      _isUpdatingToken = false;
      _isSendingTest = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
