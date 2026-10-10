import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';
import 'package:sereno_ya/data/services/api/citizen/incidents_api_service.dart';
import 'package:sereno_ya/data/services/local/citizen/incident_local_data_source.dart';
import 'package:sereno_ya/ui/citizen/incident_detail/incident_detail_screen.dart';
import 'package:sereno_ya/ui/citizen/incident_detail/view_models/incident_detail_view_model.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:sereno_ya/ui/core/theme/theme.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('muestra el detalle en $brightness sin desbordamientos', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.binding.setSurfaceSize(const Size(320, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = IncidentRepository(
        apiService: IncidentsApiService(_detailDio()),
        localDataSource: _NoopIncidentLocalDataSource(),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => IncidentDetailViewModel(repository, 'incident-1'),
          child: MaterialApp(
            theme: buildAppTheme(Brightness.light, ThemeVariant.normal),
            darkTheme: buildAppTheme(Brightness.dark, ThemeVariant.normal),
            themeMode: ThemeMode.system,
            home: const IncidentDetailScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Detalle de incidencia'), findsOneWidget);
      expect(find.text('Incendio'), findsOneWidget);
      expect(find.text('Solicitada'), findsOneWidget);
      expect(find.text('Evidencia no disponible'), findsOneWidget);
      expect(find.byTooltip('Actualizar incidencia'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Dio _detailDio() {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
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
                'description': 'Incendio en vivienda',
                'status': 'REQUESTED',
                'latitude': -13.6519,
                'longitude': -73.365,
                'referenceAddress': 'Av. Principal',
                'createdAt': '2026-09-28T10:00:00',
                'category': {'name': 'Incendio'},
              },
            },
          ),
        );
      },
    ),
  );
  return dio;
}

class _NoopIncidentLocalDataSource implements IncidentLocalDataSource {
  @override
  Future<void> cacheCategories(List<IncidentCategory> categories) async {}

  @override
  Future<List<IncidentCategory>?> getCachedCategories() async => null;
}
