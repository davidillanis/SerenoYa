import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';
import 'package:sereno_ya/data/services/api/citizen/incident_api_service.dart';
import 'package:sereno_ya/data/services/local/citizen/incident_local_data_source.dart';
import 'package:sereno_ya/ui/citizen/incident_detail/view_models/incident_detail_view_model.dart';

void main() {
  test('reutiliza el detalle hasta que se solicita su recarga', () async {
    var requestCount = 0;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestCount++;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'isSuccess': true,
                'message': 'Successful operation',
                'errors': null,
                'data': {
                  'id': 'incident-1',
                  'description': 'Incendio',
                  'status': 'REQUESTED',
                  'latitude': -13.6519,
                  'longitude': -73.365,
                  'createdAt': '2026-09-28T10:00:00',
                },
              },
            ),
          );
        },
      ),
    );
    final repository = IncidentRepository(
      apiService: IncidentApiService(dio),
      localDataSource: _NoopIncidentLocalDataSource(),
    );

    await repository.getIncidentById('incident-1');
    await repository.getIncidentById('incident-1');
    expect(requestCount, 1);
    expect(repository.getCachedIncidentById('incident-1')?.id, 'incident-1');

    final cachedViewModel = IncidentDetailViewModel(repository, 'incident-1');
    addTearDown(cachedViewModel.dispose);
    expect(cachedViewModel.incident?.id, 'incident-1');
    expect(cachedViewModel.isLoading, isFalse);
    expect(requestCount, 1);

    await repository.getIncidentById('incident-1', forceRefresh: true);
    expect(requestCount, 2);
  });
}

class _NoopIncidentLocalDataSource implements IncidentLocalDataSource {
  @override
  Future<void> cacheCategories(List<IncidentCategory> categories) async {}

  @override
  Future<List<IncidentCategory>?> getCachedCategories() async => null;
}
