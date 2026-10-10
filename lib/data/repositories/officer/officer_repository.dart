import 'package:sereno_ya/data/models/auth/api_response_dto.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/data/models/page_response.dart';
import 'package:sereno_ya/data/services/api/citizen/incidents_api_service.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';
import 'package:sereno_ya/models/auth/result.dart';

class OfficerRepository {
  OfficerRepository(this._service);
  final IncidentsApiService _service;

  Future<Result<PageResponse<OfficerIncident>>> list({
    OfficerIncidentStatus? status,
    int page = 0,
  }) => _run(
    () => _service.listOfficerIncidents(status: status?.apiValue, page: page),
  );

  Future<Result<OfficerIncident>> detail(String id) =>
      _run(() => _service.getOfficerIncident(id));

  Future<Result<bool>> accept(String id, int minutes) async {
    final result = await _run(
      () => _service.acceptIncident(incidentId: id, etaMinutes: minutes),
    );
    return result.isSuccess
        ? Result.success(true)
        : Result.failure(result.failure!);
  }

  Future<Result<bool>> update(String id, OfficerIncidentStatus status) async {
    final result = await _run(
      () => _service.updateStatus(incidentId: id, status: status.apiValue),
    );
    return result.isSuccess
        ? Result.success(true)
        : Result.failure(result.failure!);
  }

  Future<Result<T>> _run<T>(Future<ApiResponseDto<T>> Function() action) async {
    try {
      final response = await action();
      if (response.isSuccess && response.data != null) {
        return Result.success(response.data as T);
      }
      return Result.failure(
        AuthFailure(AuthFailureCode.server, response.errorMessage),
      );
    } on AuthFailure catch (error) {
      return Result.failure(error);
    } catch (_) {
      return Result.failure(
        const AuthFailure(
          AuthFailureCode.unknown,
          'No se pudo completar la operación.',
        ),
      );
    }
  }
}
