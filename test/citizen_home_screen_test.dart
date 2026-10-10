import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';
import 'package:sereno_ya/data/services/api/citizen/incidents_api_service.dart';
import 'package:sereno_ya/data/services/local/citizen/incident_local_data_source.dart';
import 'package:sereno_ya/models/auth/auth_session.dart';
import 'package:sereno_ya/models/auth/auth_state.dart';
import 'package:sereno_ya/models/auth/authenticated_user.dart';
import 'package:sereno_ya/models/auth/user_role.dart';
import 'package:sereno_ya/ui/auth/view_models/session_view_model.dart';
import 'package:sereno_ya/ui/citizen/citizen_home_screen.dart';
import 'package:sereno_ya/ui/citizen/incident_tracking/view_models/incident_tracking_view_model.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:sereno_ya/ui/core/theme/theme.dart';

import 'auth_view_models_test.dart' show RecordingAuthRepository;

void main() {
  testWidgets('volver a Seguimiento conserva la lista sin otra solicitud', (
    tester,
  ) async {
    var listRequestCount = 0;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/incidents/me/list') listRequestCount++;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'isSuccess': true,
                'message': 'Successful operation',
                'errors': null,
                'data': {
                  'content': <Object>[],
                  'page': 0,
                  'size': 100,
                  'totalElements': 0,
                  'totalPages': 1,
                },
              },
            ),
          );
        },
      ),
    );
    final repository = IncidentRepository(
      apiService: IncidentsApiService(dio),
      localDataSource: _NoopIncidentLocalDataSource(),
    );
    final sessionViewModel = SessionViewModel(_AuthenticatedAuthRepository());
    final trackingViewModel = IncidentTrackingViewModel(
      repository: repository,
      session: sessionViewModel.state.session,
    );
    addTearDown(sessionViewModel.dispose);
    addTearDown(trackingViewModel.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SessionViewModel>.value(
            value: sessionViewModel,
          ),
          ChangeNotifierProvider<IncidentTrackingViewModel>.value(
            value: trackingViewModel,
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light, ThemeVariant.normal),
          home: const CitizenHomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(listRequestCount, 1);

    await tester.tap(find.text('Seguimiento'));
    await tester.pumpAndSettle();
    expect(listRequestCount, 1);

    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seguimiento'));
    await tester.pumpAndSettle();
    expect(listRequestCount, 1);
  });
}

class _AuthenticatedAuthRepository extends RecordingAuthRepository {
  @override
  AuthState get state => const AuthState(
    status: AuthStatus.authenticated,
    session: AuthSession(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      user: AuthenticatedUser(
        id: 'user-1',
        email: 'citizen@example.com',
        firstName: 'Dani',
        lastName: 'Quispe',
        roles: [UserRole.citizen],
      ),
    ),
  );
}

class _NoopIncidentLocalDataSource implements IncidentLocalDataSource {
  @override
  Future<void> cacheCategories(List<IncidentCategory> categories) async {}

  @override
  Future<List<IncidentCategory>?> getCachedCategories() async => null;
}
