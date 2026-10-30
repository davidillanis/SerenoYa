import 'package:dio/dio.dart';
import 'package:sereno_ya/data/models/admin/admin_created_user.dart';
import 'package:sereno_ya/data/models/admin/admin_sereno_update_request.dart';
import 'package:sereno_ya/data/models/admin/admin_user_create_request.dart';
import 'package:sereno_ya/data/models/admin/admin_user_detail.dart';
import 'package:sereno_ya/data/models/admin/admin_user_summary.dart';
import 'package:sereno_ya/data/models/admin/admin_user_roles_update_request.dart';
import 'package:sereno_ya/data/models/admin/admin_user_update_request.dart';
import 'package:sereno_ya/data/models/auth/api_response_dto.dart';
import 'package:sereno_ya/data/models/page_dto.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';

class AdminUserApiService {
  AdminUserApiService(this._dio);

  final Dio _dio;

  Future<ApiResponseDto<PageResponse<AdminUserSummary>>> listUsers({
    int page = 0,
    int size = 15,
    String? search,
  }) => _request(
    () => _dio.get<dynamic>(
      '/user-role/list-details',
      queryParameters: {
        'page': page,
        'size': size,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'sortBy': 'createdAt',
        'direction': 'DESC',
      },
    ),
    (value) => PageResponse<AdminUserSummary>.fromJson(
      value,
      AdminUserSummary.fromJson,
    ),
  );

  Future<ApiResponseDto<AdminCreatedUser>> createUser(
    AdminUserCreateRequest request,
  ) => _request(
    () => _dio.post<dynamic>('/user-role/create', data: request.toJson()),
    (value) => AdminCreatedUser.fromJson(_asJsonMap(value)),
  );

  Future<ApiResponseDto<AdminUserDetail>> getUser(String userId) => _request(
    () => _dio.get<dynamic>('/user-role/byId/$userId'),
    (value) => AdminUserDetail.fromJson(_asJsonMap(value)),
  );

  Future<ApiResponseDto<String>> updateUser(
    String userId,
    AdminUserUpdateRequest request,
  ) => _request(
    () => _dio.put<dynamic>(
      '/user-role/update-admin',
      queryParameters: {'id': userId},
      data: request.toJson(),
    ),
    (value) => value?.toString() ?? '',
  );

  Future<ApiResponseDto<String>> updateRoles(
    AdminUserRolesUpdateRequest request,
  ) => _request(
    () => _dio.put<dynamic>('/user-role/update-roles', data: request.toJson()),
    (value) => value?.toString() ?? '',
  );

  Future<ApiResponseDto<String>> updateSereno(
    String userId,
    AdminSerenoUpdateRequest request,
  ) => _request(
    () => _dio.put<dynamic>(
      '/user-role/sereno-update/$userId',
      data: request.toJson(),
    ),
    (value) => value?.toString() ?? '',
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
    } on DioException catch (error) {
      throw _mapDioFailure(error);
    } on FormatException catch (error) {
      throw AuthFailure(AuthFailureCode.server, error.message);
    } on Object {
      throw const AuthFailure(
        AuthFailureCode.unknown,
        'No se pudo completar la operación de usuarios.',
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
      return AuthFailure(
        AuthFailureCode.unauthorized,
        message.isEmpty
            ? 'No tienes permisos para gestionar usuarios.'
            : message,
      );
    }
    if (statusCode == 400 || statusCode == 409 || statusCode == 422) {
      return AuthFailure(
        AuthFailureCode.validation,
        message.isEmpty ? 'Revisa los datos ingresados.' : message,
      );
    }
    return AuthFailure(
      AuthFailureCode.server,
      message.isEmpty
          ? 'El servicio no está disponible en este momento.'
          : message,
    );
  }

  static String _extractServerMessage(Object? body) {
    if (body is! Map) return '';
    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      return errors.map((error) => error.toString()).join('\n');
    }
    return body['message']?.toString() ?? '';
  }

  static Map<String, dynamic> _asJsonMap(Object? value) {
    if (value is! Map) {
      throw const FormatException('La API devolvió datos inválidos.');
    }
    return Map<String, dynamic>.from(value);
  }
}
