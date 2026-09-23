import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';

class StoredTokens {
  const StoredTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

class SessionStorageService {
  SessionStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'sereno_ya_access_token';
  static const _refreshTokenKey = 'sereno_ya_refresh_token';

  final FlutterSecureStorage _storage;

  Future<StoredTokens?> readTokens() async {
    try {
      final values = await Future.wait([
        _storage.read(key: _accessTokenKey),
        _storage.read(key: _refreshTokenKey),
      ]);
      final accessToken = values[0];
      final refreshToken = values[1];
      if (accessToken == null ||
          accessToken.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty) {
        return null;
      }
      return StoredTokens(accessToken: accessToken, refreshToken: refreshToken);
    } on Object {
      throw const AuthFailure(
        AuthFailureCode.storage,
        'No se pudo leer la sesión segura.',
      );
    }
  }

  Future<void> writeTokens(StoredTokens tokens) async {
    try {
      await _storage.write(key: _accessTokenKey, value: tokens.accessToken);
      await _storage.write(key: _refreshTokenKey, value: tokens.refreshToken);
    } on Object {
      await clear();
      throw const AuthFailure(
        AuthFailureCode.storage,
        'No se pudo guardar la sesión segura.',
      );
    }
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> clear() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
      ]);
    } on Object {
      throw const AuthFailure(
        AuthFailureCode.storage,
        'No se pudo eliminar completamente la sesión local.',
      );
    }
  }
}
