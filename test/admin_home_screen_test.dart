import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';
import 'package:sereno_ya/data/services/api/admin/admin_user_api_service.dart';
import 'package:sereno_ya/data/services/api/citizen/incidents_api_service.dart';
import 'package:sereno_ya/data/services/api/incident_api_service.dart';
import 'package:sereno_ya/data/services/local/citizen/incident_local_data_source.dart';
import 'package:sereno_ya/models/auth/auth_session.dart';
import 'package:sereno_ya/models/auth/auth_state.dart';
import 'package:sereno_ya/models/auth/authenticated_user.dart';
import 'package:sereno_ya/models/auth/user_role.dart';
import 'package:sereno_ya/ui/admin/admin_home_screen.dart';
import 'package:sereno_ya/ui/admin/categories/view_models/admin_categories_view_model.dart';
import 'package:sereno_ya/ui/admin/incidents/view_models/admin_incidents_view_model.dart';
import 'package:sereno_ya/ui/admin/users/view_models/admin_users_view_model.dart';
import 'package:sereno_ya/ui/auth/view_models/session_view_model.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:sereno_ya/ui/core/theme/theme.dart';

import 'auth_view_models_test.dart' show RecordingAuthRepository;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('las tabs conservan las listas en $brightness', (tester) async {
      var userListRequests = 0;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/user-role/list-details') userListRequests++;
            final content = options.path == '/incidents/categories/list'
                ? <Object>[
                    {
                      'id': 'category-1',
                      'name': 'Robo',
                      'description': 'Robo en la vía pública',
                      'enabled': true,
                    },
                  ]
                : <Object>[];
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'isSuccess': true,
                  'message': 'Successful operation',
                  'errors': null,
                  'data': {
                    'content': content,
                    'page': 0,
                    'size': 15,
                    'totalElements': content.length,
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
        incidentApiService: IncidentApiService(dio),
        localDataSource: _NoopIncidentLocalDataSource(),
      );
      final sessionViewModel = SessionViewModel(_AuthenticatedAuthRepository());
      final incidentsViewModel = AdminIncidentsViewModel(repository);
      final categoriesViewModel = AdminCategoriesViewModel(
        IncidentsApiService(dio),
        repository,
      );
      final usersViewModel = AdminUsersViewModel(AdminUserApiService(dio));
      addTearDown(sessionViewModel.dispose);
      addTearDown(incidentsViewModel.dispose);
      addTearDown(categoriesViewModel.dispose);
      addTearDown(usersViewModel.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SessionViewModel>.value(
              value: sessionViewModel,
            ),
            ChangeNotifierProvider<AdminIncidentsViewModel>.value(
              value: incidentsViewModel,
            ),
            ChangeNotifierProvider<AdminCategoriesViewModel>.value(
              value: categoriesViewModel,
            ),
            ChangeNotifierProvider<AdminUsersViewModel>.value(
              value: usersViewModel,
            ),
          ],
          child: MaterialApp(
            theme: buildAppTheme(brightness, ThemeVariant.normal),
            home: const AdminHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Incidencias'), findsOneWidget);
      expect(find.text('Categorías'), findsOneWidget);
      expect(find.text('Usuarios'), findsOneWidget);
      expect(find.text('Incidencias registradas'), findsOneWidget);

      await tester.tap(find.text('Categorías'));
      await tester.pumpAndSettle();
      expect(find.text('Catálogo de categorías'), findsOneWidget);
      expect(find.text('Robo'), findsOneWidget);
      expect(find.text('Activa'), findsOneWidget);

      await tester.tap(find.byTooltip('Editar categoría'));
      await tester.pumpAndSettle();
      expect(find.text('Editar categoría'), findsOneWidget);
      expect(find.text('Categoría activa'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Usuarios'));
      await tester.pumpAndSettle();
      expect(find.text('Directorio de usuarios'), findsOneWidget);
      expect(userListRequests, 1);

      await tester.tap(find.text('Incidencias'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usuarios'));
      await tester.pumpAndSettle();
      expect(find.text('Directorio de usuarios'), findsOneWidget);
      expect(userListRequests, 1);
    });
  }
}

class _AuthenticatedAuthRepository extends RecordingAuthRepository {
  @override
  AuthState get state => const AuthState(
    status: AuthStatus.authenticated,
    session: AuthSession(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      user: AuthenticatedUser(
        id: 'admin-1',
        email: 'admin@example.com',
        firstName: 'Ana',
        lastName: 'Quispe',
        roles: [UserRole.administrator],
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
