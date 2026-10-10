import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/data/models/page_response.dart';
import 'package:sereno_ya/data/repositories/officer/officer_repository.dart';
import 'package:sereno_ya/data/services/api/citizen/incidents_api_service.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';
import 'package:sereno_ya/models/auth/auth_session.dart';
import 'package:sereno_ya/models/auth/authenticated_user.dart';
import 'package:sereno_ya/models/auth/result.dart';
import 'package:sereno_ya/models/auth/user_role.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:sereno_ya/ui/core/theme/theme.dart';
import 'package:sereno_ya/ui/officer/officer_home_screen.dart';
import 'package:sereno_ya/ui/officer/officer_detail_screen.dart';
import 'package:sereno_ya/ui/officer/view_models/officer_detail_view_model.dart';
import 'package:sereno_ya/ui/officer/view_models/officer_incidents_view_model.dart';
import 'package:sereno_ya/ui/officer/widgets/officer_incident_card.dart';

const session = AuthSession(
  accessToken: '',
  refreshToken: '',
  user: AuthenticatedUser(
    id: 'test-officer',
    email: '',
    firstName: '',
    lastName: '',
    roles: [UserRole.officer],
  ),
);

Map<String, dynamic> incidentJson(
  String status, {
  String id = 'incident-test',
}) => {
  'id': id,
  'status': status,
  'description': 'Incidente de prueba',
  'latitude': -13.65,
  'longitude': -73.36,
  'referenceAddress': 'Ubicación de prueba',
  'createdAt': '2026-10-05T09:00:00',
  'category': {'id': 'category-test', 'name': 'Atención ciudadana'},
  'citizen': {
    'id': 'citizen-test',
    'userEntity': {'phone': '000000000'},
  },
};
OfficerIncident item(String status) =>
    OfficerIncident.fromJson(incidentJson(status));
PageResponse<OfficerIncident> page(
  String status, {
  int index = 0,
  int total = 31,
}) => PageResponse(
  content: [item(status)],
  page: index,
  size: 15,
  totalElements: total,
  totalPages: 3,
);

void main() {
  test(
    'evita aceptar dos veces y actualiza aceptados al cerrar en el servidor',
    () async {
      final repository = FakeRepository();
      final model = OfficerIncidentsViewModel(repository, session);
      await Future<void>.delayed(Duration.zero);
      final first = model.acceptIncident('incident-test', 12);
      expect(await model.acceptIncident('incident-test', 12), isNotNull);
      await first;
      expect(repository.acceptCount, 1);
      expect(model.accepted, hasLength(1));
      repository.currentStatus = 'ATTENDED';
      await model.loadInitial(forceRefresh: true);
      expect(model.accepted, isEmpty);
      model.dispose();
    },
  );

  test('sin sesión no consulta métricas ni acepta incidentes', () async {
    final repository = FakeRepository();
    final model = OfficerIncidentsViewModel(repository, null);
    await model.loadMetrics();
    expect(await model.acceptIncident('incident-test', 12), isNotNull);
    expect(repository.acceptCount, 0);
    expect(model.totals, isEmpty);
    model.dispose();
  });

  setUpAll(() async {
    const fontDirectory = String.fromEnvironment('OFFICER_FONT_DIR');
    if (fontDirectory.isEmpty) return;
    for (final font in {
      'Roboto': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf',
    }.entries) {
      final loader = FontLoader(font.key)
        ..addFont(
          File('$fontDirectory/${font.value}')
              .readAsBytes()
              .then((bytes) => ByteData.sublistView(bytes)),
        );
      await loader.load();
    }
  });
  test(
    'mapea estados, prioridades y coordenadas ausentes sin inventar datos',
    () {
      expect(item('REQUESTED').status, OfficerIncidentStatus.pending);
      expect(item('ACCEPTED').status, OfficerIncidentStatus.enRoute);
      expect(item('ON_SITE').status, OfficerIncidentStatus.attending);
      expect(item('ATTENDED').status, OfficerIncidentStatus.attended);
      expect(item('NEW_STATUS').status, OfficerIncidentStatus.unknown);
      expect(item('REQUESTED').priority, IncidentPriority.unknown);
      for (final priority in ['HIGH', 'MEDIUM', 'LOW']) {
        expect(
          OfficerIncident.fromJson({
            ...incidentJson('REQUESTED'),
            'priority': priority,
          }).priority,
          isNot(IncidentPriority.unknown),
        );
      }
      expect(
        OfficerIncident.fromJson({'id': 'missing'}).hasCoordinates,
        isFalse,
      );
      expect(
        OfficerIncident.fromJson({...incidentJson('REQUESTED'), 'latitude': 91})
            .hasCoordinates,
        isFalse,
      );
      expect(item('REQUESTED').citizenPhone, '000000000');
      expect(
        elapsedLabel(
          DateTime(2026, 10, 5, 9),
          now: DateTime(2026, 10, 5, 9, 23),
        ),
        'Hace 23 min',
      );
    },
  );

  test(
    'servicio usa los contratos reales de listado, detalle y acciones',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(request);
            final data = request.path == '/incidents/list'
                ? {
                    'content': [incidentJson('REQUESTED')],
                    'page': 2,
                    'size': 15,
                    'totalElements': 31,
                    'totalPages': 3,
                  }
                : request.path.endsWith('/accept')
                ? {
                    'incidentId': 'incident-test',
                    'assignmentId': 'assignment-test',
                    'serenoId': 'test-officer',
                    'etaMinutes': 12,
                    'status': 'ACCEPTED',
                  }
                : incidentJson('ON_SITE');
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: {'isSuccess': true, 'data': data},
              ),
            );
          },
        ),
      );
      final repository = OfficerRepository(IncidentsApiService(dio));
      final result = await repository.list(
        status: OfficerIncidentStatus.pending,
        page: 2,
      );
      expect(result.data!.totalElements, 31);
      expect(requests.last.queryParameters['status'], 'REQUESTED');
      expect(requests.last.queryParameters['page'], 2);
      expect(
        requests.last.queryParameters['fields'],
        contains('citizen.userEntity.phone'),
      );
      expect(
        requests.last.queryParameters['fields'],
        isNot(contains('priority')),
      );
      await repository.detail('incident-test');
      expect(requests.last.path, '/incidents/byId/incident-test');
      await repository.accept('incident-test', 12);
      expect(requests.last.data, {'etaMinutes': 12});
      await repository.update('incident-test', OfficerIncidentStatus.attending);
      expect(requests.last.queryParameters['status'], 'ON_SITE');
    },
  );

  test(
    'repositorio convierte errores de red en resultados recuperables',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) => handler.reject(
            DioException(
              requestOptions: request,
              type: DioExceptionType.connectionError,
            ),
          ),
        ),
      );
      final result = await OfficerRepository(IncidentsApiService(dio)).list();
      expect(result.isSuccess, isFalse);
      expect(result.failure!.code, AuthFailureCode.network);
    },
  );

  test(
    'descarta respuestas viejas al cambiar de filtro y al desmontarse',
    () async {
      final repository = FakeRepository()..hold = true;
      final model = OfficerIncidentsViewModel(repository, session);
      final old = repository.pending.removeAt(0);
      final current = model.selectFilter(OfficerIncidentStatus.attended);
      repository.pending.removeAt(0).complete(Result.success(page('ATTENDED')));
      await current;
      old.complete(Result.success(page('REQUESTED')));
      await Future<void>.delayed(Duration.zero);
      expect(model.incidents.single.status, OfficerIncidentStatus.attended);
      final refresh = model.loadInitial();
      model.dispose();
      repository.pending
          .removeAt(0)
          .complete(Result.success(page('REQUESTED')));
      await refresh;
    },
  );

  test('métricas usan totalElements y paginación elimina duplicados', () async {
    final model = OfficerIncidentsViewModel(FakeRepository(), session);
    await Future<void>.delayed(Duration.zero);
    await model.loadMore();
    expect(model.incidents.length, 1);
    await model.loadMetrics();
    expect(model.totals[OfficerIncidentStatus.pending], 31);
    expect(model.accepted, isEmpty);
    await model.acceptIncident('incident-test', 12);
    expect(model.accepted.single.status, OfficerIncidentStatus.enRoute);
    model.dispose();
  });

  test('detalle valida ETA y ejecuta aceptación, llegada y cierre', () async {
    final repository = FakeRepository();
    final model = OfficerDetailViewModel(repository, 'incident-test');
    await Future<void>.delayed(Duration.zero);
    expect(await model.act(etaMinutes: 0), isNotNull);
    expect(repository.acceptCount, 0);
    expect(await model.act(etaMinutes: 12), isNull);
    expect(model.item!.status, OfficerIncidentStatus.enRoute);
    expect(model.acceptedHere, isTrue);
    await model.act();
    expect(model.item!.status, OfficerIncidentStatus.attending);
    await model.act();
    expect(model.item!.status, OfficerIncidentStatus.attended);
    expect(await model.act(), isNotNull);
    model.dispose();
  });

  test(
    'un error al releer una mutación exitosa no deja acciones obsoletas',
    () async {
      final repository = FakeRepository();
      final model = OfficerDetailViewModel(repository, 'incident-test');
      await Future<void>.delayed(Duration.zero);
      repository.detailFails = true;
      expect(await model.act(etaMinutes: 12), isNull);
      expect(model.item, isNull);
      expect(model.error, isNotNull);
      model.dispose();
    },
  );

  for (final brightness in Brightness.values) {
    for (final width in [320.0, 1000.0]) {
      testWidgets('inicio, reportes y detalle ${brightness.name} a $width px', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final model = OfficerIncidentsViewModel(FakeRepository(), session);
        addTearDown(model.dispose);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: model,
            child: MaterialApp(
              theme: buildAppTheme(brightness, ThemeVariant.normal),
              home: RepaintBoundary(
                key: boundary,
                child: const OfficerHomeScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Aceptar y enviar respuesta'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.runAsync(
          () => _capture(boundary, 'inicio-${brightness.name}-$width'),
        );
        await tester.tap(find.text('Reportes'));
        await tester.pumpAndSettle();
        expect(find.text('31'), findsNWidgets(4));
        await tester.runAsync(
          () => _capture(boundary, 'reportes-${brightness.name}-$width'),
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Ver detalle y evidencia'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ver detalle y evidencia'));
        await tester.pumpAndSettle();
        expect(find.byType(OfficerDetailScreen), findsOneWidget);
        expect(find.text('Ciudadano'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}

// Optional visual artifacts for local review; no network or golden dependency.
Future<void> _capture(GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('OFFICER_SCREENSHOTS')) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await File('/tmp/serenazgo-$name.png')
      .writeAsBytes(bytes!.buffer.asUint8List());
  image.dispose();
}

class FakeRepository extends OfficerRepository {
  FakeRepository() : super(IncidentsApiService(Dio()));
  String currentStatus = 'REQUESTED';
  bool hold = false;
  bool detailFails = false;
  int acceptCount = 0;
  final pending = <Completer<Result<PageResponse<OfficerIncident>>>>[];
  @override
  Future<Result<PageResponse<OfficerIncident>>> list({
    OfficerIncidentStatus? status,
    int page = 0,
  }) {
    if (hold) {
      final completer = Completer<Result<PageResponse<OfficerIncident>>>();
      pending.add(completer);
      return completer.future;
    }
    return Future.value(
      Result.success(
        PageResponse(
          content: [item(status?.apiValue ?? currentStatus)],
          page: page,
          size: 15,
          totalElements: 31,
          totalPages: 3,
        ),
      ),
    );
  }

  @override
  Future<Result<OfficerIncident>> detail(String id) async => detailFails
      ? Result.failure(
          const AuthFailure(AuthFailureCode.network, 'Sin conexión'),
        )
      : Result.success(item(currentStatus));
  @override
  Future<Result<bool>> accept(String id, int minutes) async {
    acceptCount++;
    currentStatus = 'ACCEPTED';
    return Result.success(true);
  }

  @override
  Future<Result<bool>> update(String id, OfficerIncidentStatus status) async {
    currentStatus = status.apiValue;
    return Result.success(true);
  }
}
