enum AuthFailureCode {
  invalidCredentials,
  invalidSession,
  unauthorized,
  validation,
  network,
  server,
  storage,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.code, this.message);

  final AuthFailureCode code;
  final String message;

  bool get isNetwork => code == AuthFailureCode.network;

  @override
  String toString() => message;
}
