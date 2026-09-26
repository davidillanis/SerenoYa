import 'package:dio/dio.dart';
import 'package:sereno_ya/data/models/auth/api_response_dto.dart';
import 'package:sereno_ya/data/models/auth/auth_response_dto.dart';
import 'package:sereno_ya/data/services/api/auth/auth_interceptor.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';

class AuthApiService {
  AuthApiService(this._dio);

  final Dio _dio;

  static const String _basepath = '/auth';

  Options get _publicOptions =>
      Options(extra: const {AuthInterceptor.skipAuthenticationKey: true});

  Future<ApiResponseDto<AuthResponseDto>> login({
    required String email,
    required String password,
  }) => _request(
    () => _dio.post<dynamic>(
      '$_basepath/login',
      data: {'email': email, 'password': password},
      options: _publicOptions,
    ),
    AuthResponseDto.fromJson,
  );

  Future<ApiResponseDto<AuthResponseDto>> loginWithGoogle(String idToken) =>
      _request(
        () => _dio.post<dynamic>(
          '$_basepath/google-login',
          data: {'idToken': idToken},
          options: _publicOptions,
        ),
        AuthResponseDto.fromJson,
      );

  Future<ApiResponseDto<bool>> validateToken(String token) => _request(
    () => _dio.get<dynamic>(
      '$_basepath/validateToken/${Uri.encodeComponent(token)}',
      options: _publicOptions,
    ),
    (value) => value == true,
  );

  Future<ApiResponseDto<AuthResponseDto>> refresh(String refreshToken) =>
      _request(
        () => _dio.post<dynamic>(
          '$_basepath/refresh',
          data: {'refreshToken': refreshToken},
          options: _publicOptions,
        ),
        AuthResponseDto.fromJson,
      );

  Future<ApiResponseDto<String>> forgotPassword(String email) => _request(
    () => _dio.post<dynamic>(
      '$_basepath/forgot-password',
      data: {'email': email},
      options: _publicOptions,
    ),
    (value) => value?.toString() ?? '',
  );

  Future<ApiResponseDto<Object?>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) => _request(
    () => _dio.post<dynamic>(
      '$_basepath/reset-password',
      data: {'email': email, 'token': token, 'newPassword': newPassword},
      options: _publicOptions,
    ),
    (value) => value,
  );

  Future<ApiResponseDto<Object?>> registerCitizen({
    required String firstName,
    required String lastName,
    required String dni,
    required String phone,
    required String address,
    required String email,
    required String password,
  }) => _request(
    () => _dio.post<dynamic>(
      '/user-role/create-customer',
      data: {
        'name': firstName,
        'lastName': lastName,
        'dni': dni,
        'phone': phone,
        'address': address,
        'imageUrl': '',
        'email': email,
        'password': password,
        'roles': ['CLIENTE'],
      },
      options: _publicOptions,
    ),
    (value) => value,
  );

  Future<ApiResponseDto<T>> _request<T>(
    Future<Response<dynamic>> Function() action,
    T Function(Object? value) decodeData,
  ) async {
    try {
      final response = await action();
      final body = response.data;
      if (body is! Map) {
        throw const AuthFailure(
          AuthFailureCode.server,
          'La API devolvió una respuesta inválida.',
        );
      }
      return ApiResponseDto<T>.fromJson(
        Map<String, dynamic>.from(body),
        decodeData,
      );
    } on AuthFailure {
      rethrow;
    } on FormatException catch (error) {
      throw AuthFailure(AuthFailureCode.server, error.message);
    } on DioException catch (error) {
      throw _mapDioFailure(error);
    } on Object {
      throw const AuthFailure(
        AuthFailureCode.unknown,
        'Ocurrió un error inesperado durante la autenticación.',
      );
    }
  }

  AuthFailure _mapDioFailure(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const AuthFailure(
        AuthFailureCode.network,
        'No se pudo conectar con el servidor. Verifica tu conexión.',
      );
    }

    final statusCode = error.response?.statusCode;
    final body = error.response?.data;
    final serverMessage = _extractServerMessage(body);

    if (statusCode == 401) {
      final normalizedMessage = serverMessage.toLowerCase();
      final userDoesNotExist =
          normalizedMessage.contains('user not found') ||
          normalizedMessage.contains('usuario no encontrado') ||
          normalizedMessage.contains('usuario no existe');

      return AuthFailure(
        AuthFailureCode.invalidCredentials,
        userDoesNotExist
            ? 'El usuario no existe.'
            : 'El correo o la contraseña son incorrectos.',
      );
    }

    if (statusCode == 403) {
      return const AuthFailure(
        AuthFailureCode.unauthorized,
        'No tienes permisos para realizar esta acción.',
      );
    }

    if (statusCode == 400 || statusCode == 422) {
      return AuthFailure(
        AuthFailureCode.validation,
        serverMessage.isEmpty
            ? 'Revisa los datos ingresados e inténtalo nuevamente.'
            : serverMessage,
      );
    }

    if (statusCode == 404) {
      return const AuthFailure(
        AuthFailureCode.server,
        'No se encontró el recurso solicitado.',
      );
    }

    return const AuthFailure(
      AuthFailureCode.server,
      'El servicio no está disponible en este momento. Inténtalo nuevamente.',
    );
  }

  String _extractServerMessage(Object? body) {
    if (body is! Map) return '';

    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      return errors.map((error) => error.toString()).join(' ');
    }

    return body['message']?.toString() ?? '';
  }
}
