import 'package:dio/dio.dart';
import 'package:sereno_ya/data/models/auth/api_response_dto.dart';
import 'package:sereno_ya/data/models/incident_assignment.dart';
import 'package:sereno_ya/data/models/incident_status.dart';
import 'package:sereno_ya/data/models/officer/incident_acceptance.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/data/models/page_dto.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';

class IncidentApiService {
  IncidentApiService(this._dio);

  final Dio _dio;

  Future<ApiResponseDto<PageResponse<OfficerIncident>>> list({required String fields,IncidentStatus? status,PageRequestDTO pageRequest = const PageRequestDTO(page: 0,size: 15,sortBy: 'id',direction: EDirection.DESC,),}) => _request(
    () => _dio.get<dynamic>('/incident/list',
      queryParameters: {'fields': fields,'status': ?status?.apiValue,...pageRequest.toMap(),},
    ),
    (value) => PageResponse.fromJson(value, OfficerIncident.fromJson),
  );

  Future<ApiResponseDto<PageResponse<OfficerIncident>>> listMeSereno({required String fields,IncidentStatus? status,PageRequestDTO pageRequest = const PageRequestDTO(page: 0,size: 15,sortBy: 'id',direction: EDirection.DESC,),}) => _request(
    () => _dio.get<dynamic>('/incident/list-me-sereno',
      queryParameters: {'fields': fields,'status': ?status?.apiValue,...pageRequest.toMap(),},
    ),
    (value) => PageResponse.fromJson(value, OfficerIncident.fromJson),
  );

  Future<ApiResponseDto<OfficerIncident>> byIdSereno({required String fields,required String id,}) => _request(
    () => _dio.get<dynamic>(
      '/incident/byId-sereno/$id',
      queryParameters: {'fields': fields, 'id': id},
    ),
    (value) => OfficerIncident.fromJson(_asJsonMap(value)),
  );

  Future<ApiResponseDto<IncidentAcceptance>> accept(IncidentAcceptRequest request,) {
    return _request(
      () => _dio.post<dynamic>('/incident/accept', data: request.toJson()),
      (value) => IncidentAcceptance.fromJson(_asJsonMap(value)),
    );
  }

  Future<ApiResponseDto<T>> _request<T>(Future<Response<dynamic>> Function() action,T Function(Object? value) decodeData,) async {
    try {
      final response = await action();
      final body = response.data;
      if (body is! Map) {
        throw const AuthFailure(AuthFailureCode.server,'La API devolvió una respuesta inválida.',);
      }
      return ApiResponseDto<T>.fromJson(Map<String, dynamic>.from(body),decodeData,);
    } on AuthFailure {
      rethrow;
    } on FormatException catch (error) {
      throw AuthFailure(AuthFailureCode.server, error.message);
    } on DioException catch (error) {
      throw _mapDioFailure(error);
    } on Object {
      throw const AuthFailure(AuthFailureCode.unknown,'Ocurrió un error inesperado en la red.',);
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
      return const AuthFailure(AuthFailureCode.unauthorized,'No tienes permisos para realizar esta acción.',);
    }

    if (statusCode == 400 || statusCode == 422) {
      return AuthFailure(AuthFailureCode.validation,serverMessage.isEmpty ? 'Revisa los datos ingresados.' : serverMessage,);
    }

    if (statusCode == 409) {
      return AuthFailure(AuthFailureCode.validation,serverMessage.isEmpty? 'La incidencia ya no está disponible.': serverMessage,);
    }

    if (serverMessage.isNotEmpty) {
      return AuthFailure(AuthFailureCode.server, serverMessage);
    }
    return const AuthFailure(AuthFailureCode.server,'El servicio no está disponible en este momento.',
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
