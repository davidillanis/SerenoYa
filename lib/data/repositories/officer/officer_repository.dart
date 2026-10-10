import 'package:sereno_ya/data/models/auth/api_response_dto.dart';
import 'package:sereno_ya/data/models/incident_assignment.dart';
import 'package:sereno_ya/data/models/incident_status.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/data/models/page_dto.dart';
import 'package:sereno_ya/data/services/api/incident_api_service.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';
import 'package:sereno_ya/models/auth/result.dart';

class OfficerRepository {
  OfficerRepository(this._service);
  final IncidentApiService _service;

  static const officerFields =
      'id,status,latitude,longitude,description,referenceAddress,createdAt,'
      'acceptedAt,arrivedAt,attendedAt,cancelledAt,category.name,'
      'citizen.id,citizen.userEntity.phone,'
      'evidences.id,evidences.fileUrl,evidences.fileName,evidences.fileType,'
      'evidences.createdAt';

  /// Bolsa general de incidentes (`GET /incident/list`).
  /// Se usa para los pendientes que cualquier sereno puede aceptar.
  Future<Result<PageResponse<OfficerIncident>>> list({
    OfficerIncidentStatus? status,
    int page = 0,
    int size = 15,
  }) => _run(
    () => _service.list(
      fields: officerFields,
      status: _toIncidentStatus(status),
      pageRequest: PageRequestDTO(
        page: page,
        size: size,
        sortBy: 'id',
        direction: EDirection.DESC,
      ),
    ),
  );

  /// Incidentes del sereno autenticado (`GET /incident/list-me-sereno`).
  /// Se usa para reportes, métricas y aceptados.
  Future<Result<PageResponse<OfficerIncident>>> listMine({
    OfficerIncidentStatus? status,
    int page = 0,
    int size = 15,
  }) => _run(
    () => _service.listMeSereno(
      fields: officerFields,
      status: _toIncidentStatus(status),
      pageRequest: PageRequestDTO(
        page: page,
        size: size,
        sortBy: 'id',
        direction: EDirection.DESC,
      ),
    ),
  );

  /// Detalle del sereno (`GET /incident/byId-sereno/{id}`).
  Future<Result<OfficerIncident>> detail(String id) =>
      _run(() => _service.byIdSereno(fields: officerFields, id: id));

  /// Acepta con la ubicación del sereno (`POST /incident/accept`).
  Future<Result<bool>> accept({
    required String id,
    required double latitude,
    required double longitude,
  }) async {
    final result = await _run(
      () => _service.accept(
        IncidentAcceptRequest(
          incidentId: id,
          acceptedLatitude: latitude,
          acceptedLongitude: longitude,
        ),
      ),
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

IncidentStatus? _toIncidentStatus(OfficerIncidentStatus? status) =>
    switch (status) {
      null => null,
      OfficerIncidentStatus.pending => IncidentStatus.requested,
      OfficerIncidentStatus.enRoute => IncidentStatus.accepted,
      OfficerIncidentStatus.attending => IncidentStatus.onSite,
      OfficerIncidentStatus.attended => IncidentStatus.attended,
      OfficerIncidentStatus.cancelled => IncidentStatus.cancelledByCitizen,
      OfficerIncidentStatus.expired => IncidentStatus.expired,
      OfficerIncidentStatus.unknown => null,
    };
