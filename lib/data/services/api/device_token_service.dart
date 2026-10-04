import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/models/divice_model.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository.dart';
import 'package:sereno_ya/data/services/api/device_api_service.dart';
import 'package:sereno_ya/models/auth/auth_state.dart';

/// Sincroniza el token solo cuando hay una sesión autenticada.
class DeviceTokenService {
  DeviceTokenService({
    required AuthRepository authRepository,
    required DeviceApiService apiService,
    required this._readDeviceId,
    required this._osType,
  }) : _auth = authRepository,
       _api = apiService {
    _subscription = _auth.states.listen(_onAuthState);
    _onAuthState(_auth.state);
  }

  final AuthRepository _auth;
  final DeviceApiService _api;
  final Future<String?> Function() _readDeviceId;
  final String _osType;
  late final StreamSubscription<AuthState> _subscription;
  Future<void> _pending = Future<void>.value();
  String? _userId;
  String? _recordId;
  String? _token;
  String? _sentToken;
  int _generation = 0;
  bool _disposed = false;

  void _onAuthState(AuthState state) {
    if (state.status == AuthStatus.refreshing) return;
    final userId = state.isAuthenticated ? state.session?.user.id : null;
    if (_userId != userId) {
      _generation++;
      _userId = userId;
      _recordId = null;
      _sentToken = null;
    }
    if (userId != null && userId.isNotEmpty) unawaited(_enqueue());
  }

  Future<void> synchronizeToken(String? token) {
    if (token == null || token.isEmpty || _disposed) return Future.value();
    _token = token;
    return _enqueue();
  }

  Future<void> _enqueue() {
    final generation = _generation;
    _pending = _pending.then((_) => _synchronize(generation));
    return _pending;
  }

  Future<void> _synchronize(int generation) async {
    final userId = _userId;
    final token = _token;
    bool isCurrent() => !_disposed && generation == _generation;
    if (!isCurrent() ||
        userId == null ||
        userId.isEmpty ||
        token == null ||
        token == _sentToken) {
      return;
    }
    try {
      final deviceId = await _readDeviceId();
      if (!isCurrent()) return;
      final request = DeviceRequest(
        deviceId: deviceId,
        fcmToken: token,
        osType: _osType,
      );
      final recordId = _recordId;
      if (recordId == null) {
        final response = await _api.createDevice(
          userId: userId,
          request: request,
        );
        if (!isCurrent()) return;
        if (!response.isSuccess ||
            response.data == null ||
            response.data!.isEmpty) {
          throw StateError('No se pudo registrar el dispositivo.');
        }
        _recordId = response.data;
      } else {
        final response = await _api.updateDevice(
          deviceId: recordId,
          request: request,
        );
        if (!isCurrent()) return;
        if (!response.isSuccess || (response.data ?? 0) <= 0) {
          throw StateError('No se pudo actualizar el dispositivo.');
        }
      }
      _sentToken = token;
    } on Object {
      // Conserva el token pendiente para el próximo evento de sesión o FCM.
      debugPrint('No se pudo sincronizar el dispositivo para notificaciones.');
    }
  }

  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(_subscription.cancel());
  }
}
