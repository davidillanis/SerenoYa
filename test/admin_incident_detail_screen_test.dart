import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';
import 'package:sereno_ya/data/services/api/citizen/incidents_api_service.dart';
import 'package:sereno_ya/data/services/api/incident_api_service.dart';
import 'package:sereno_ya/data/services/local/citizen/incident_local_data_source.dart';
import 'package:sereno_ya/ui/admin/incidents/admin_incident_detail_screen.dart';
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
        incidentApiService: IncidentApiService(_detailDio()),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => IncidentDetailViewModel(repository, 'incident-1'),
          child: MaterialApp(
            theme: buildAppTheme(Brightness.light, ThemeVariant.normal),
            darkTheme: buildAppTheme(Brightness.dark, ThemeVariant.normal),
            themeMode: ThemeMode.system,
            home: const AdminIncidentDetailScreen(),
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
  for (final status in [
    'REQUESTED',
    'ATTENDED',
    'EXPIRED',
    'CANCELLED_BY_CITIZEN',
  ]) {
    testWidgets('seguimiento de $status en pantalla estrecha y texto grande', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final dio = _detailDio(status: status);
      final repository = IncidentRepository(
        apiService: IncidentsApiService(dio),
        localDataSource: _NoopIncidentLocalDataSource(),
        incidentApiService: IncidentApiService(dio),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => IncidentDetailViewModel(repository, 'incident-1'),
          child: MaterialApp(
            theme: buildAppTheme(Brightness.light, ThemeVariant.normal),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: const AdminIncidentDetailScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Seguimiento'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Reporte creado'), findsOneWidget);
      expect(find.text('Historial de estados'), findsOneWidget);
      if (status == 'REQUESTED') {
        expect(find.text('Pendiente'), findsNWidgets(3));
        expect(find.text('Plazo para aceptar el reporte'), findsOneWidget);
        expect(find.text('Incidencia expirada'), findsNothing);
      } else if (status == 'ATTENDED') {
        expect(find.text('Aceptado por el sereno'), findsOneWidget);
        expect(find.text('Sereno en camino'), findsOneWidget);
        expect(find.text('Sereno llegó al lugar'), findsOneWidget);
        expect(find.text('Plazo para aceptar el reporte'), findsNothing);
        expect(find.text('Incidencia expirada'), findsNothing);
      } else {
        expect(
          find.text(
            status == 'EXPIRED'
                ? 'Incidencia expirada'
                : 'Incidencia cancelada',
          ),
          findsOneWidget,
        );
        expect(find.text('Pendiente'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }
}

Dio _detailDio({String status = 'REQUESTED'}) {
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
                'assignment': null,
                'statusHistory': [],
                'description': 'Incendio en vivienda',
                'status': status,
                'latitude': -13.6519,
                'longitude': -73.365,
                'referenceAddress': 'Av. Principal',
                'createdAt': '2026-09-28T10:00:00',
                'expiredAt': '2026-09-28T10:30:00',
                if (status == 'ATTENDED') ...{
                  'acceptedAt': '2026-09-28T10:05:00',
                  'arrivedAt': '2026-09-28T10:10:00',
                  'attendedAt': '2026-09-28T10:20:00',
                },
                if (status == 'CANCELLED_BY_CITIZEN')
                  'cancelledAt': '2026-09-28T10:03:00',
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
