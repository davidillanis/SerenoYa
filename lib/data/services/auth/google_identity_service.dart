import 'package:google_sign_in/google_sign_in.dart';
import 'package:sereno_ya/config/api_config.dart';

abstract interface class GoogleIdentityService {
  Future<void> initialize();
  Future<String?> authenticateForIdToken();
  Future<void> signOut();
}

class GoogleIdentityServiceImpl implements GoogleIdentityService {
  GoogleIdentityServiceImpl({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;
  Future<void>? _initialization;

  @override
  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    final serverClientId = ApiConfig.googleServerClientId;
    if (serverClientId.trim().isEmpty) {
      throw const GoogleIdentityException(
        'Google Sign-In no está configurado para esta aplicación.',
      );
    }

    await _googleSignIn.initialize(serverClientId: serverClientId);
  }

  @override
  Future<String?> authenticateForIdToken() async {
    try {
      await initialize();
      if (!_googleSignIn.supportsAuthenticate()) {
        throw const GoogleIdentityException(
          'El acceso con Google no está disponible en esta plataforma.',
        );
      }
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;

      if (idToken == null || idToken.trim().isEmpty) {
        throw const GoogleIdentityException(
          'Google no devolvió un token válido.',
        );
      }
      return idToken.trim();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      throw const GoogleIdentityException(
        'No se pudo iniciar sesión con Google. Inténtalo nuevamente.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (_initialization == null) return;
      await _initialization;
      await _googleSignIn.signOut();
    } catch (_) {
      // Mantener la sesión local de SerenoYa aunque Google falle.
    }
  }
}

class DummyGoogleIdentityService implements GoogleIdentityService {
  const DummyGoogleIdentityService();

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> authenticateForIdToken() async => null;

  @override
  Future<void> signOut() async {}
}

class GoogleIdentityException implements Exception {
  const GoogleIdentityException(this.message);

  final String message;

  @override
  String toString() => message;
}
