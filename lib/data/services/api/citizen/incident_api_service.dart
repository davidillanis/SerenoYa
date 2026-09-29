import 'package:dio/dio.dart';
import 'package:sereno_ya/data/models/auth/api_response_dto.dart';
import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/data/models/citizen/incident_create_request.dart';
import 'package:sereno_ya/data/models/citizen/incident.dart';
import 'package:sereno_ya/data/models/page_response.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';

class IncidentApiService {
  IncidentApiService(this._dio);

  final Dio _dio;

  Future<ApiResponseDto<PageResponse<IncidentCategory>>> getCategories() async {
    return _request(
      () => _dio.get<dynamic>(
        '/incidents/categories/list',
        queryParameters: const {
          'fields': 'id,name,description',
          'page': 0,
          'size': 100,
          'sortBy': 'name',
          'direction': 'ASC',
        },
      ),
      (value) => PageResponse<IncidentCategory>.fromJson(
        value,
        IncidentCategory.fromJson,
      ),
    );
  }

  Future<ApiResponseDto<Incident>> createIncident(
    IncidentCreateRequest request,
  ) async {
    return _request(
      () => _dio.post<dynamic>('/incidents/create', data: request.toJson()),
      (value) => Incident.fromJson(_asJsonMap(value)),
    );
  }

  Future<ApiResponseDto<PageResponse<Incident>>> listMyIncidents({
    String? status,
    int page = 0,
    int size = 100,
    String fields =
        'id,status,latitude,longitude,description,referenceAddress,createdAt,'
        'acceptedAt,arrivedAt,attendedAt,cancelledAt,category.name',
  }) async {
    return _request(
      () => _dio.get<dynamic>(
        '/incidents/me/list',
        queryParameters: {
          if (status != null) 'status': status,
          'fields': fields,
          'page': page,
          'size': size,
          'sortBy': 'createdAt',
          'direction': 'DESC',
        },
      ),
      (value) => PageResponse<Incident>.fromJson(value, Incident.fromJson),
    );
  }

  Future<ApiResponseDto<Incident>> getIncidentById(String incidentId) async {
    return _request(
      () => _dio.get<dynamic>(
        '/incidents/byId/$incidentId',
        queryParameters: const {
          'fields':
              'id,status,latitude,longitude,description,referenceAddress,'
              'createdAt,acceptedAt,arrivedAt,attendedAt,cancelledAt,'
              'category.name',
        },
      ),
      (value) => Incident.fromJson(_asJsonMap(value)),
    );
  }

  Future<ApiResponseDto<Incident>> updateStatus({
    required String incidentId,
    required String status,
  }) async {
    return _request(
      () => _dio.put<dynamic>(
        '/incidents/update-status',
        queryParameters: {'incidentId': incidentId, 'status': status},
      ),
      (value) => Incident.fromJson(_asJsonMap(value)),
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

    return const AuthFailure(
      AuthFailureCode.server,
      'El servicio no está disponible en este momento.',
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

  static Map<String, dynamic> _asJsonMap(Object? value) {
    if (value is! Map) {
      throw const FormatException('La API devolvió datos inválidos.');
    }
    return Map<String, dynamic>.from(value);
  }
}
