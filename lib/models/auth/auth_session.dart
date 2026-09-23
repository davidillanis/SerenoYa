import 'package:sereno_ya/models/auth/authenticated_user.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.accessTokenExpiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final AuthenticatedUser user;
  final DateTime? accessTokenExpiresAt;

  bool get isExpired {
    final expiry = accessTokenExpiresAt;
    if (expiry == null) return false;
    return !expiry.isAfter(
      DateTime.now().toUtc().add(const Duration(seconds: 30)),
    );
  }
}
