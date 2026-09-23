import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository.dart';
import 'package:sereno_ya/models/auth/auth_session.dart';
import 'package:sereno_ya/models/auth/auth_state.dart';
import 'package:sereno_ya/models/auth/authenticated_user.dart';
import 'package:sereno_ya/models/auth/result.dart';
import 'package:sereno_ya/models/auth/user_role.dart';
import 'package:sereno_ya/ui/auth/view_models/forgot_password_view_model.dart';
import 'package:sereno_ya/ui/auth/view_models/login_view_model.dart';
import 'package:sereno_ya/ui/auth/view_models/register_view_model.dart';
import 'package:sereno_ya/ui/auth/view_models/reset_password_view_model.dart';
import 'package:sereno_ya/ui/auth/view_models/session_view_model.dart';

void main() {
  group('MVVM authentication delegation', () {
    test('LoginViewModel normalizes email and calls repository', () async {
      final repository = RecordingAuthRepository();
      final viewModel = LoginViewModel(repository);

      final success = await viewModel.login(
        email: '  citizen@example.com  ',
        password: 'secret',
      );

      expect(success, isTrue);
      expect(repository.loginEmail, 'citizen@example.com');
      expect(repository.loginPassword, 'secret');
    });

    test('RegisterViewModel preserves registration normalization', () async {
      final repository = RecordingAuthRepository();
      final viewModel = RegisterViewModel(repository);

      final success = await viewModel.register(
        firstName: '  Dani ',
        lastName: ' Quispe  ',
        dni: ' 12345678 ',
        phone: ' 999999999 ',
        address: '',
        email: ' citizen@example.com ',
        password: 'secret',
        passwordConfirmation: 'secret',
      );

      expect(success, isTrue);
      expect(repository.registration, {
        'firstName': 'Dani',
        'lastName': 'Quispe',
        'dni': '12345678',
        'phone': '999999999',
        'address': 'San Jerónimo',
        'email': 'citizen@example.com',
        'password': 'secret',
      });
    });

    test('password ViewModels trim identifiers before delegation', () async {
      final repository = RecordingAuthRepository();

      expect(
        await ForgotPasswordViewModel(repository).send(' citizen@example.com '),
        isTrue,
      );
      expect(repository.forgotEmail, 'citizen@example.com');

      expect(
        await ResetPasswordViewModel(repository).reset(
          email: ' citizen@example.com ',
          token: ' 123456 ',
          password: 'new-secret',
          passwordConfirmation: 'new-secret',
        ),
        isTrue,
      );
      expect(repository.resetEmail, 'citizen@example.com');
      expect(repository.resetToken, '123456');
      expect(repository.newPassword, 'new-secret');
    });

    test('SessionViewModel delegates initialize and logout', () async {
      final repository = RecordingAuthRepository();
      final viewModel = SessionViewModel(repository);

      await viewModel.initialize();
      await viewModel.logout();

      expect(repository.initializeCalls, 1);
      expect(repository.logoutCalls, 1);
      viewModel.dispose();
    });
  });
}

class RecordingAuthRepository implements AuthRepository {
  final _session = const AuthSession(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    user: AuthenticatedUser(
      id: 1,
      email: 'citizen@example.com',
      firstName: 'Dani',
      lastName: 'Quispe',
      roles: [UserRole.citizen],
    ),
  );

  String? loginEmail;
  String? loginPassword;
  Map<String, String>? registration;
  String? forgotEmail;
  String? resetEmail;
  String? resetToken;
  String? newPassword;
  int initializeCalls = 0;
  int logoutCalls = 0;

  @override
  AuthState get state => const AuthState.unauthenticated();

  @override
  Stream<AuthState> get states => const Stream.empty();

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    loginEmail = email;
    loginPassword = password;
    return Result.success(_session);
  }

  @override
  Future<Result<AuthSession>> loginWithGoogleIdToken(String idToken) async =>
      Result.success(_session);

  @override
  Future<Result<void>> registerCitizen({
    required String firstName,
    required String lastName,
    required String dni,
    required String phone,
    required String address,
    required String email,
    required String password,
  }) async {
    registration = {
      'firstName': firstName,
      'lastName': lastName,
      'dni': dni,
      'phone': phone,
      'address': address,
      'email': email,
      'password': password,
    };
    return Result<void>.success(null);
  }

  @override
  Future<Result<void>> forgotPassword(String email) async {
    forgotEmail = email;
    return Result<void>.success(null);
  }

  @override
  Future<Result<void>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    resetEmail = email;
    resetToken = token;
    this.newPassword = newPassword;
    return Result<void>.success(null);
  }

  @override
  Future<Result<bool>> validateAccessToken(String token) async =>
      Result.success(true);

  @override
  Future<Result<AuthSession>> refreshSession() async =>
      Result.success(_session);

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}
