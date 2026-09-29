import 'package:dio/dio.dart';
import 'package:sereno_ya/data/models/auth/api_response_dto.dart';
import 'package:sereno_ya/data/models/profile/citizen_profile.dart';
import 'package:sereno_ya/data/models/profile/profile_update_request.dart';
import 'package:sereno_ya/data/models/profile/user_profile.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';

class ProfileApiService {
  ProfileApiService(this._dio);

  final Dio _dio;
  String? _cacheOwnerId;
  UserProfile? _cachedUserProfile;
  CitizenProfile? _cachedCitizenProfile;

  UserProfile? get cachedUserProfile => _cachedUserProfile;
  CitizenProfile? get cachedCitizenProfile => _cachedCitizenProfile;

  void useCacheForUser(String userId) {
    if (_cacheOwnerId == userId) return;
    _cacheOwnerId = userId;
    _cachedUserProfile = null;
    _cachedCitizenProfile = null;
  }

  Future<ApiResponseDto<UserProfile>> getUserProfile() async {
    final cacheOwnerId = _cacheOwnerId;
    final response = await _request(
      () => _dio.get<dynamic>('/user-role/me'),
      UserProfile.fromJson,
    );
    if (_cacheOwnerId == cacheOwnerId &&
        response.isSuccess &&
        response.data != null) {
      _cachedUserProfile = response.data;
    }
    return response;
  }

  Future<ApiResponseDto<CitizenProfile>> getCitizenProfile() async {
    final cacheOwnerId = _cacheOwnerId;
    final response = await _request(
      () => _dio.get<dynamic>(
        '/citizens/me',
        queryParameters: const {
          'fields': 'id,homeLatitude,homeLongitude,createdAt',
        },
      ),
      CitizenProfile.fromJson,
    );
    if (_cacheOwnerId == cacheOwnerId &&
        response.isSuccess &&
        response.data != null) {
      _cachedCitizenProfile = response.data;
    }
    return response;
  }

  Future<ApiResponseDto<String>> updateUserProfile(
    UserProfileUpdateRequest request,
  ) async {
    final cacheOwnerId = _cacheOwnerId;
    final response = await _request(
      () => _dio.put<dynamic>('/user-role/update-me', data: request.toJson()),
      (value) => value?.toString() ?? '',
    );
    if (_cacheOwnerId == cacheOwnerId && response.isSuccess) {
      _cachedUserProfile = null;
    }
    return response;
  }

  Future<ApiResponseDto<String>> updateCitizenProfile(
    CitizenProfileUpdateRequest request,
  ) async {
    final cacheOwnerId = _cacheOwnerId;
    final response = await _request(
      () => _dio.put<dynamic>('/citizens/update', data: request.toJson()),
      (value) => value?.toString() ?? '',
    );
    if (_cacheOwnerId == cacheOwnerId && response.isSuccess) {
      _cachedCitizenProfile = null;
    }
    return response;
  }

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
        'No se pudo completar la operación del perfil.',
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
    final message = _extractServerMessage(error.response?.data);
    if (statusCode == 401 || statusCode == 403) {
      return const AuthFailure(
        AuthFailureCode.unauthorized,
        'No tienes permisos para realizar esta acción.',
      );
    }
    if (statusCode == 400 || statusCode == 422) {
      return AuthFailure(
        AuthFailureCode.validation,
        message.isEmpty ? 'Revisa los datos ingresados.' : message,
      );
    }
    if (statusCode == 404) {
      return const AuthFailure(
        AuthFailureCode.server,
        'No se encontró el perfil solicitado.',
      );
    }
    return const AuthFailure(
      AuthFailureCode.server,
      'El perfil no está disponible en este momento.',
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
