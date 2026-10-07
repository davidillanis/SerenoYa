import 'package:dio/dio.dart';
import 'package:sereno_ya/data/models/auth/api_response_dto.dart';
import 'package:sereno_ya/data/models/divice_model.dart';
import 'package:sereno_ya/data/models/notification_model.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';

class DeviceApiService {
  DeviceApiService(this._dio);

  final Dio _dio;

  Future<ApiResponseDto<String>> sendNotification(NotificationRequest request) {
    return _request(
      () => _dio.post<dynamic>(
        '/device/notification/send',
        data: request.toJson(),
      ),
      _decodeString,
    );
  }

  Future<ApiResponseDto<NotificationAnyResponse>> sendNotificationAll(
    NotificationAnyRequest request,
  ) {
    return _request(
      () => _dio.post<dynamic>(
        '/device/notification/send-any',
        data: request.toJson(),
      ),
      NotificationAnyResponse.fromJson,
    );
  }

  Future<ApiResponseDto<String>> createDevice({
    required DeviceRequest request,
  }) {
    return _request(
      () => _dio.post<dynamic>('/device/create', data: request.toJson()),
      _decodeString,
    );
  }

  Future<ApiResponseDto<int>> updateDevice({
    required String deviceId,
    required DeviceRequest request,
  }) {
    return _request(
      () => _dio.put<dynamic>(
        '/device/update/${Uri.encodeComponent(deviceId)}',
        data: request.toJson(),
      ),
      (value) {
        if (value is! int) {
          throw const FormatException('La API devolvió una cantidad inválida.');
        }
        return value;
      },
    );
  }

  static String _decodeString(Object? value) {
    if (value is! String) {
      throw const FormatException('La API devolvió datos inválidos.');
    }
    return value;
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
        'No se pudo completar la operación del dispositivo.',
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
        'No se encontró el dispositivo solicitado.',
      );
    }
    return const AuthFailure(
      AuthFailureCode.server,
      'El servicio de dispositivos no está disponible en este momento.',
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
