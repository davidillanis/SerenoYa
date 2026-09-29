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
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    final serverClientId = ApiConfig.googleServerClientId;
    if (serverClientId.trim().isEmpty) {
      throw const GoogleIdentityException(
        'Google Sign-In no está configurado para esta aplicación.',
      );
    }

    await _googleSignIn.initialize(serverClientId: serverClientId);
    _initialized = true;
  }

  @override
  Future<String?> authenticateForIdToken() async {
    try {
      await initialize();
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;

      print('GOOGLE_ACCOUNT_EMAIL: ${account.email}');
      print('GOOGLE_ID_TOKEN_IS_NULL: ${idToken == null}');
      print(
        'GOOGLE_ID_TOKEN_PREFIX: ${idToken != null ? idToken.substring(0, 20) : 'null'}',
      );

      if (idToken == null || idToken.trim().isEmpty) {
        return null;
      }
      return idToken.trim();
    } on GoogleSignInException catch (_) {
      rethrow;
    } on Exception {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
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
