import 'package:sereno_ya/data/models/route/route_compare.dart';
import 'package:sereno_ya/data/services/api/incident_api_service.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';
import 'package:sereno_ya/models/auth/result.dart';

/// Comparación de rutas (`POST /incident/incident-compare/{id}`) para el
/// módulo de Serenazgo. La primera opción devuelta por el backend es la
/// más rápida.
class RouteCompareRepository {
  RouteCompareRepository(this._service);
  final IncidentApiService _service;

  Future<Result<List<RouteOption>>> compare({
    required String incidentId,
    required RouteCoordinate origin,
    required RouteCoordinate destination,
  }) async {
    try {
      final response = await _service.compare(
        RouteCompareRequest(origin: origin, destination: destination),
        incidentId,
      );
      if (response.isSuccess && response.data != null) {
        return Result.success(response.data!);
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
          'No se pudo comparar las rutas.',
        ),
      );
    }
  }
}
