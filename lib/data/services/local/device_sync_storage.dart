import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Foto exacta de lo último sincronizado con éxito en el backend.
///
/// Se persiste para no crear dispositivos duplicados tras reinicios y para
/// no llamar a la red cuando nada cambió (mismo usuario, hardware, token y SO).
class DeviceSyncSnapshot {
  const DeviceSyncSnapshot({
    required this.userId,
    required this.recordId,
    this.deviceId,
    this.fcmToken,
    this.osType,
  });

  final String userId;
  final String recordId;
  final String? deviceId;
  final String? fcmToken;
  final String? osType;

  /// Verdadero si este snapshot ya representa [token]/[deviceId]/[osType]
  /// para [userId]. En ese caso no hace falta ninguna llamada de red.
  bool matches({
    required String userId,
    required String? deviceId,
    required String? token,
    required String osType,
  }) {
    return this.userId == userId &&
        recordId.isNotEmpty &&
        this.deviceId == deviceId &&
        fcmToken == token &&
        this.osType == osType;
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'recordId': recordId,
    'deviceId': deviceId,
    'fcmToken': fcmToken,
    'osType': osType,
  };

  factory DeviceSyncSnapshot.fromJson(Map<String, dynamic> json) {
    return DeviceSyncSnapshot(
      userId: json['userId'] as String? ?? '',
      recordId: json['recordId'] as String? ?? '',
      deviceId: json['deviceId'] as String?,
      fcmToken: json['fcmToken'] as String?,
      osType: json['osType'] as String?,
    );
  }
}

/// Persistencia mínima del snapshot. Abstraída para poder probarla en memoria.
abstract class DeviceSyncStorage {
  Future<DeviceSyncSnapshot?> read();
  Future<void> write(DeviceSyncSnapshot snapshot);
  Future<void> clear();
}

/// Implementación con SharedPreferences (el token FCM no es un secreto de
/// sesión, por lo que no necesita almacenamiento seguro).
class SharedPreferencesDeviceSyncStorage implements DeviceSyncStorage {
  SharedPreferencesDeviceSyncStorage({Future<SharedPreferences>? prefs})
    : _prefs = prefs ?? SharedPreferences.getInstance();

  static const storageKey = '@device_sync_snapshot';

  final Future<SharedPreferences> _prefs;

  @override
  Future<DeviceSyncSnapshot?> read() async {
    final prefs = await _prefs;
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final snapshot = DeviceSyncSnapshot.fromJson(decoded);
      if (snapshot.userId.isEmpty || snapshot.recordId.isEmpty) return null;
      return snapshot;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> write(DeviceSyncSnapshot snapshot) async {
    final prefs = await _prefs;
    await prefs.setString(storageKey, jsonEncode(snapshot.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(storageKey);
  }
}

/// Implementación en memoria para pruebas.
class InMemoryDeviceSyncStorage implements DeviceSyncStorage {
  DeviceSyncSnapshot? _snapshot;

  @override
  Future<DeviceSyncSnapshot?> read() async => _snapshot;

  @override
  Future<void> write(DeviceSyncSnapshot snapshot) async {
    _snapshot = snapshot;
  }

  @override
  Future<void> clear() async {
    _snapshot = null;
  }
}
