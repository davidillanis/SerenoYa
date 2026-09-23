import 'package:sereno_ya/models/auth/auth_failure.dart';
import 'package:sereno_ya/models/auth/auth_session.dart';

enum AuthStatus {
  unknown,
  unauthenticated,
  authenticating,
  authenticated,
  refreshing,
}

class AuthState {
  const AuthState({required this.status, this.session, this.failure});

  const AuthState.unknown() : this(status: AuthStatus.unknown);
  const AuthState.unauthenticated([AuthFailure? failure])
    : this(status: AuthStatus.unauthenticated, failure: failure);

  final AuthStatus status;
  final AuthSession? session;
  final AuthFailure? failure;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && session != null;
}
