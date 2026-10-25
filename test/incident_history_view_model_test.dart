import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';
import 'package:sereno_ya/data/services/api/citizen/incidents_api_service.dart';
import 'package:sereno_ya/data/services/api/incident_api_service.dart';
import 'package:sereno_ya/data/services/local/citizen/incident_local_data_source.dart';
import 'package:sereno_ya/models/auth/auth_session.dart';
import 'package:sereno_ya/models/auth/authenticated_user.dart';
import 'package:sereno_ya/models/auth/user_role.dart';
import 'package:sereno_ya/ui/citizen/incident_history/view_models/incident_history_view_model.dart';

void main() {
  test(
    'Todas conserva los seis estados al paginar y permite filtrarlos',
    () async {
      final statuses = [
        'REQUESTED',
        'ACCEPTED',
        'ON_SITE',
        'ATTENDED',
        'CANCELLED_BY_CITIZEN',
        'EXPIRED',
      ];
      final requestedPages = <int>[];
      final requestedStatuses = <String?>[];
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final page = options.queryParameters['page'] as int;
            requestedPages.add(page);
            final status = options.queryParameters['status'] as String?;
            requestedStatuses.add(status);
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'isSuccess': true,
                  'data': {
                    'content': [
                      {
                        'id': 'incident-$page',
                        'status': status ?? statuses[page],
                      },
                    ],
                    'page': page,
                    'size': 15,
                    'totalElements': status == null ? 6 : 1,
                    'totalPages': status == null ? 6 : 1,
                  },
                },
              ),
            );
          },
        ),
      );
      final model = IncidentHistoryViewModel(
        IncidentRepository(
          apiService: IncidentsApiService(dio),
          incidentApiService: IncidentApiService(dio),
          localDataSource: _LocalDataSource(),
        ),
        const AuthSession(
          accessToken: 'test',
          refreshToken: 'test',
          user: AuthenticatedUser(
            id: 'test',
            email: '',
            firstName: '',
            lastName: '',
            roles: [UserRole.citizen],
          ),
        ),
      );
      addTearDown(model.dispose);
      await model.loadInitial();
      expect(requestedPages, [0]);
      expect(model.incidents.single.status, 'REQUESTED');
      while (model.hasMore) {
        await model.loadMore();
      }
      expect(requestedPages, [0, 1, 2, 3, 4, 5]);
      expect(model.incidents.map((item) => item.status), statuses);
      expect(requestedStatuses, everyElement(isNull));
      for (final filter in IncidentHistoryFilter.values.skip(1)) {
        await model.selectFilter(filter);
        expect(requestedStatuses.last, filter.status);
        expect(model.incidents.single.status, filter.status);
      }
    },
  );
}

class _LocalDataSource implements IncidentLocalDataSource {
  @override
  Future<void> cacheCategories(List<IncidentCategory> categories) async {}
  @override
  Future<List<IncidentCategory>?> getCachedCategories() async => null;
}
