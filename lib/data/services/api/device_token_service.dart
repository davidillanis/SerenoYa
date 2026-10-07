import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/models/divice_model.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository.dart';
import 'package:sereno_ya/data/services/api/device_api_service.dart';
import 'package:sereno_ya/data/services/local/device_sync_storage.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';
import 'package:sereno_ya/models/auth/auth_state.dart';

/// Sincroniza el token solo cuando hay una sesión autenticada.
///
/// Estrategia eficiente y precisa:
/// - No llama a la red si el snapshot persistido ya coincide
///   (mismo usuario, hardware, token FCM y [osType]).
/// - Crea solo cuando no hay `recordId` para el usuario actual.
/// - Actualiza cuando ya hay `recordId` y algo cambió.
/// - Si el `update` indica que el registro ya no existe (0 filas o 404),
///   reintenta una sola vez con `create` para no dejar el token huérfano.
class DeviceTokenService {
  DeviceTokenService({
    required AuthRepository authRepository,
    required DeviceApiService apiService,
    required Future<String?> Function() readDeviceId,
    required String osType,
    DeviceSyncStorage? syncStorage,
  }) : _auth = authRepository,
       _api = apiService,
       _readDeviceId = readDeviceId,
       _osType = osType,
       _syncStorage = syncStorage {
    _restoreFuture = _restorePersistedState();
    _subscription = _auth.states.listen(_onAuthState);
    _onAuthState(_auth.state);
  }

  final AuthRepository _auth;
  final DeviceApiService _api;
  final Future<String?> Function() _readDeviceId;
  final String _osType;
  final DeviceSyncStorage? _syncStorage;
  late final StreamSubscription<AuthState> _subscription;
  late final Future<void> _restoreFuture;
  Future<void> _pending = Future<void>.value();
  String? _userId;
  String? _recordId;
  String? _token;
  String? _sentToken;
  String? _sentDeviceId;
  String? _sentOsType;
  DeviceSyncSnapshot? _persisted;
  String? _cachedHardwareId;
  bool _hardwareIdLoaded = false;
  int _generation = 0;
  bool _disposed = false;

  /// Mensaje exacto que [DeviceApiService] devuelve ante un 404.
  /// Se compara por igualdad para no confundir otros errores del servidor.
  static const _deviceNotFoundMessage =
      'No se encontró el dispositivo solicitado.';

  Future<void> _restorePersistedState() async {
    final storage = _syncStorage;
    if (storage == null) return;
    try {
      // Solo carga; la adopción del recordId se decide en [_onAuthState] y
      // [_synchronize], donde ya se conocen usuario y hardware id juntos.
      _persisted = await storage.read();
    } on Object {
      _persisted = null;
    }
  }

  void _onAuthState(AuthState state) {
    if (state.status == AuthStatus.refreshing) return;
    final userId = state.isAuthenticated ? state.session?.user.id : null;
    if (_userId != userId) {
      _generation++;
      _userId = userId;
      _recordId = null;
      _sentToken = null;
      _sentDeviceId = null;
      _sentOsType = null;
      // Readopta el snapshot persistido si pertenece al nuevo usuario.
      final snapshot = _persisted;
      if (snapshot != null && snapshot.userId == userId) {
        _recordId = snapshot.recordId;
      }
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
    await _restoreFuture;
    final userId = _userId;
    final token = _token;

    bool isCurrent() => !_disposed && generation == _generation;
    if (!isCurrent() || userId == null || userId.isEmpty || token == null) {
      return;
    }
    try {
      // El hardware id se cachea: es estable por instalación y evita un
      // channel nativo en cada sincronización; solo se relee si fue nulo.
      final deviceId = await _readHardwareId();
      if (!isCurrent()) return;

      // Vía rápida en memoria: payload idéntico al último confirmado.
      if (token == _sentToken &&
          deviceId == _sentDeviceId &&
          _osType == _sentOsType &&
          _recordId != null) {
        return;
      }

      // Vía precisa tras reinicio: si lo persistido ya coincide, no hay red.
      final persisted = _persisted;
      if (persisted != null &&
          persisted.matches(
            userId: userId,
            deviceId: deviceId,
            token: token,
            osType: _osType,
          )) {
        _recordId = persisted.recordId;
        _sentToken = token;
        _sentDeviceId = deviceId;
        _sentOsType = _osType;
        return;
      }

      final request = DeviceRequest(
        deviceId: deviceId,
        fcmToken: token,
        osType: _osType,
      );
      var recordId = _recordId;
      // Si el snapshot persistido es de este usuario pero la memoria se
      // perdió (reinicio), readóptalo antes de decidir crear o actualizar.
      if (recordId == null && persisted != null && persisted.userId == userId) {
        recordId = persisted.recordId;
      }
      String? newRecordId = recordId;
      if (recordId == null) {
        final created = await _create(request);
        if (!isCurrent()) return;
        newRecordId = created;
      } else {
        try {
          await _update(recordId, request);
          if (!isCurrent()) return;
        } on _MissingDevice {
          // El backend ya no conoce el registro: crea uno nuevo una sola vez.
          _recordId = null;
          _persisted = null;
          if (!isCurrent()) return;
          final created = await _create(request);
          if (!isCurrent()) return;
          newRecordId = created;
        }
      }
      if (!isCurrent()) return;
      final finalId = newRecordId;
      if (finalId == null || finalId.isEmpty) {
        throw StateError('No se pudo registrar el dispositivo.');
      }
      _recordId = finalId;
      _sentToken = token;
      _sentDeviceId = deviceId;
      _sentOsType = _osType;
      await _persistSnapshot(
        userId: userId,
        recordId: finalId,
        deviceId: deviceId,
        token: token,
      );
    } on Object {
      // Conserva el token pendiente para el próximo evento de sesión o FCM.
      debugPrint('No se pudo sincronizar el dispositivo para notificaciones.');
    }
  }

  Future<String?> _readHardwareId() async {
    if (_hardwareIdLoaded) return _cachedHardwareId;
    final deviceId = await _readDeviceId();
    // Solo se cachea un valor no nulo: un nulo puede deberse a un fallo
    // transitorio del channel y debe reintentarse en la próxima sync.
    if (deviceId != null) {
      _cachedHardwareId = deviceId;
      _hardwareIdLoaded = true;
    }
    return deviceId;
  }

  Future<String> _create(DeviceRequest request) async {
    final response = await _api.createDevice(request: request);
    if (!response.isSuccess ||
        response.data == null ||
        response.data!.isEmpty) {
      throw StateError('No se pudo registrar el dispositivo.');
    }
    return response.data!;
  }

  Future<void> _update(String recordId, DeviceRequest request) async {
    try {
      final response = await _api.updateDevice(
        deviceId: recordId,
        request: request,
      );
      if (!response.isSuccess || (response.data ?? 0) <= 0) {
        throw const _MissingDevice();
      }
    } on AuthFailure catch (error) {
      // 404 se mapea como server con el mensaje exacto de "No se encontró".
      // Solo en ese caso tiene sentido reintentar con create; otros errores
      // (red, permisos, validación, 500) deben conservar el pendiente.
      if (error.code == AuthFailureCode.server &&
          error.message == _deviceNotFoundMessage) {
        throw const _MissingDevice();
      }
      rethrow;
    }
  }

  Future<void> _persistSnapshot({
    required String userId,
    required String recordId,
    required String? deviceId,
    required String? token,
  }) async {
    final snapshot = DeviceSyncSnapshot(
      userId: userId,
      recordId: recordId,
      deviceId: deviceId,
      fcmToken: token,
      osType: _osType,
    );
    _persisted = snapshot;
    try {
      await _syncStorage?.write(snapshot);
    } on Object {
      // La persistencia es una optimización: un fallo no invalida el envío.
      debugPrint('No se pudo guardar el estado del dispositivo.');
    }
  }

  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(_subscription.cancel());
  }
}

/// Marca interna: el registro del servidor ya no existe y corresponde crear.
class _MissingDevice implements Exception {
  const _MissingDevice();
}
