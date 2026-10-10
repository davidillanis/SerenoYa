import 'package:dio/dio.dart';
import 'package:sereno_ya/data/models/auth/api_response_dto.dart';
import 'package:sereno_ya/data/models/route/route_compare.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';

/// Cliente de `POST /route/compare`: compara rutas en auto, moto, bicicleta
/// y a pie. La primera opción de la lista es la más rápida.
class RouteApiService {
  RouteApiService(this._dio);

  final Dio _dio;

  Future<ApiResponseDto<List<RouteOption>>> compare(
    RouteCompareRequest request,
  ) {
    return _request(
      () => _dio.post<dynamic>('/route/compare', data: request.toJson()),
      (value) {
        if (value is! List) {
          throw const FormatException('La API devolvió datos inválidos.');
        }
        return value
            .map((item) => RouteOption.fromJson(_asJsonMap(item)))
            .toList(growable: false);
      },
    );
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
        'Ocurrió un error inesperado en la red.',
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

    if (statusCode == 401 || statusCode == 403) {
      if (serverMessage.isNotEmpty) {
        return AuthFailure(AuthFailureCode.unauthorized, serverMessage);
      }
      return const AuthFailure(
        AuthFailureCode.unauthorized,
        'No tienes permisos para realizar esta acción.',
      );
    }

    if (statusCode == 400 || statusCode == 422) {
      return AuthFailure(
        AuthFailureCode.validation,
        serverMessage.isEmpty ? 'Revisa los datos ingresados.' : serverMessage,
      );
    }

    if (serverMessage.isNotEmpty) {
      return AuthFailure(AuthFailureCode.server, serverMessage);
    }
    return const AuthFailure(
      AuthFailureCode.server,
      'El servicio no está disponible en este momento.',
    );
  }

  String _extractServerMessage(Object? body) {
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
