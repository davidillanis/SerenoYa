import 'dart:async';

import 'package:sereno_ya/data/models/auth/auth_response_dto.dart';
import 'package:sereno_ya/data/models/auth/jwt_claims.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository.dart';
import 'package:sereno_ya/data/services/api/auth/auth_api_service.dart';
import 'package:sereno_ya/data/services/storage/session_storage_service.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';
import 'package:sereno_ya/models/auth/auth_session.dart';
import 'package:sereno_ya/models/auth/auth_state.dart';
import 'package:sereno_ya/models/auth/authenticated_user.dart';
import 'package:sereno_ya/models/auth/result.dart';
import 'package:sereno_ya/models/auth/user_role.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._apiService, this._storageService);

  final AuthApiService _apiService;
  final SessionStorageService _storageService;
  final _stateController = StreamController<AuthState>.broadcast(sync: true);

  AuthState _state = const AuthState.unknown();

  @override
  AuthState get state => _state;

  @override
  Stream<AuthState> get states => _stateController.stream;

  @override
  Future<void> initialize() async {
    try {
      final tokens = await _storageService.readTokens();
      if (tokens == null) {
        _emit(const AuthState.unauthenticated());
        return;
      }

      final claims = JwtClaims.decode(tokens.accessToken);
      final expiration = claims.expiresAt;
      final isExpired =
          expiration != null &&
          !expiration.isAfter(
            DateTime.now().toUtc().add(const Duration(seconds: 30)),
          );
      if (isExpired) {
        await refreshSession();
        return;
      }

      try {
        final validation = await _apiService.validateToken(tokens.accessToken);
        if (validation.isSuccess && validation.data == true) {
          _emit(
            AuthState(
              status: AuthStatus.authenticated,
              session: _sessionFromTokens(tokens),
            ),
          );
          return;
        }
        await refreshSession();
      } on AuthFailure catch (failure) {
        if (failure.isNetwork &&
            expiration != null &&
            expiration.isAfter(DateTime.now().toUtc())) {
          _emit(
            AuthState(
              status: AuthStatus.authenticated,
              session: _sessionFromTokens(tokens),
              failure: failure,
            ),
          );
          return;
        }
        await refreshSession();
      }
    } on AuthFailure catch (failure) {
      await _clearSession(failure);
    } on Object {
      await _clearSession(
        const AuthFailure(
          AuthFailureCode.unknown,
          'No se pudo restaurar la sesión.',
        ),
      );
    }
  }

  @override
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    _emit(const AuthState(status: AuthStatus.authenticating));
    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );
      return await _completeAuthentication(
        response.isSuccess,
        response.data,
        response.errorMessage,
      );
    } on AuthFailure catch (failure) {
      _emit(AuthState.unauthenticated(failure));
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<AuthSession>> loginWithGoogleIdToken(String idToken) async {
    _emit(const AuthState(status: AuthStatus.authenticating));
    try {
      final response = await _apiService.loginWithGoogle(idToken);
      return await _completeAuthentication(
        response.isSuccess,
        response.data,
        response.errorMessage,
      );
    } on AuthFailure catch (failure) {
      _emit(AuthState.unauthenticated(failure));
      return Result.failure(failure);
    }
  }

  Future<Result<AuthSession>> _completeAuthentication(
    bool isSuccess,
    AuthResponseDto? dto,
    String errorMessage,
  ) async {
    if (!isSuccess || dto == null) {
      final failure = AuthFailure(
        AuthFailureCode.invalidCredentials,
        errorMessage,
      );
      _emit(AuthState.unauthenticated(failure));
      return Result.failure(failure);
    }

    try {
      final session = _sessionFromResponse(dto);
      await _storageService.writeTokens(
        StoredTokens(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        ),
      );
      _emit(AuthState(status: AuthStatus.authenticated, session: session));
      return Result.success(session);
    } on AuthFailure catch (failure) {
      await _clearSession(failure);
      return Result.failure(failure);
    }
  }

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
    try {
      final response = await _apiService.registerCitizen(
        firstName: firstName,
        lastName: lastName,
        dni: dni,
        phone: phone,
        address: address,
        email: email,
        password: password,
      );
      if (!response.isSuccess) {
        return Result.failure(
          AuthFailure(AuthFailureCode.validation, response.errorMessage),
        );
      }
      return Result<void>.success(null);
    } on AuthFailure catch (failure) {
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<void>> forgotPassword(String email) async {
    try {
      final response = await _apiService.forgotPassword(email);
      if (!response.isSuccess) {
        return Result.failure(
          AuthFailure(AuthFailureCode.validation, response.errorMessage),
        );
      }
      return Result<void>.success(null);
    } on AuthFailure catch (failure) {
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<void>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.resetPassword(
        email: email,
        token: token,
        newPassword: newPassword,
      );
      if (!response.isSuccess) {
        return Result.failure(
          AuthFailure(AuthFailureCode.validation, response.errorMessage),
        );
      }
      return Result<void>.success(null);
    } on AuthFailure catch (failure) {
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<bool>> validateAccessToken(String token) async {
    try {
      final response = await _apiService.validateToken(token);
      if (!response.isSuccess) {
        return Result.failure(
          AuthFailure(AuthFailureCode.invalidSession, response.errorMessage),
        );
      }
      return Result.success(response.data == true);
    } on AuthFailure catch (failure) {
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<AuthSession>> refreshSession() async {
    final previousSession = _state.session;
    _emit(AuthState(status: AuthStatus.refreshing, session: previousSession));
    try {
      final tokens = await _storageService.readTokens();
      if (tokens == null) {
        throw const AuthFailure(
          AuthFailureCode.invalidSession,
          'No existe un refresh token disponible.',
        );
      }

      final response = await _apiService.refresh(tokens.refreshToken);
      if (!response.isSuccess || response.data == null) {
        throw AuthFailure(
          AuthFailureCode.invalidSession,
          response.errorMessage,
        );
      }

      final session = _sessionFromResponse(response.data!);
      await _storageService.writeTokens(
        StoredTokens(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        ),
      );
      _emit(AuthState(status: AuthStatus.authenticated, session: session));
      return Result.success(session);
    } on AuthFailure catch (failure) {
      await _clearSession(failure);
      return Result.failure(failure);
    }
  }

  @override
  Future<void> logout() => _clearSession();

  AuthSession _sessionFromResponse(AuthResponseDto dto) {
    final claims = JwtClaims.decode(dto.accessToken);
    final roles = UserRole.parseAuthorities(claims.authorities);
    _ensureHasOperationalRole(roles);
    return AuthSession(
      accessToken: dto.accessToken,
      refreshToken: dto.refreshToken,
      accessTokenExpiresAt: claims.expiresAt,
      user: AuthenticatedUser(
        id: dto.id.isEmpty ? claims.userId ?? '' : dto.id,
        email: claims.email,
        firstName: dto.firstName,
        lastName: dto.lastName,
        phone: dto.phone,
        imageUrl: dto.imageUrl,
        citizenId: claims.citizenId,
        officerId: claims.officerId,
        roles: roles,
      ),
    );
  }

  AuthSession _sessionFromTokens(StoredTokens tokens) {
    final claims = JwtClaims.decode(tokens.accessToken);
    final roles = UserRole.parseAuthorities(claims.authorities);
    _ensureHasOperationalRole(roles);
    return AuthSession(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      accessTokenExpiresAt: claims.expiresAt,
      user: AuthenticatedUser(
        id: claims.userId ?? '',
        email: claims.email,
        firstName: '',
        lastName: '',
        citizenId: claims.citizenId,
        officerId: claims.officerId,
        roles: roles,
      ),
    );
  }

  void _ensureHasOperationalRole(List<UserRole> roles) {
    if (roles.isEmpty) {
      throw const AuthFailure(
        AuthFailureCode.unauthorized,
        'La cuenta no tiene ningún rol operativo reconocido.',
      );
    }
  }

  Future<void> _clearSession([AuthFailure? failure]) async {
    try {
      await _storageService.clear();
    } on AuthFailure catch (storageFailure) {
      failure ??= storageFailure;
    }
    _emit(AuthState.unauthenticated(failure));
  }

  void _emit(AuthState state) {
    _state = state;
    if (!_stateController.isClosed) _stateController.add(state);
  }
}
