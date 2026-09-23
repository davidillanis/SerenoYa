import 'package:sereno_ya/models/auth/auth_session.dart';
import 'package:sereno_ya/models/auth/auth_state.dart';
import 'package:sereno_ya/models/auth/result.dart';

abstract interface class AuthRepository {
  AuthState get state;
  Stream<AuthState> get states;

  Future<void> initialize();

  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  });

  Future<Result<AuthSession>> loginWithGoogleIdToken(String idToken);

  Future<Result<void>> registerCitizen({
    required String firstName,
    required String lastName,
    required String dni,
    required String phone,
    required String address,
    required String email,
    required String password,
  });

  Future<Result<void>> forgotPassword(String email);

  Future<Result<void>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  });

  Future<Result<bool>> validateAccessToken(String token);
  Future<Result<AuthSession>> refreshSession();
  Future<void> logout();
}
