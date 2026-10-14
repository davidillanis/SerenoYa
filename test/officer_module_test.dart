import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/data/models/page_dto.dart';
import 'package:sereno_ya/data/repositories/officer/officer_repository.dart';
import 'package:sereno_ya/data/services/api/incident_api_service.dart';
import 'package:sereno_ya/data/services/maps/citizen_location_service.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';
import 'package:sereno_ya/models/auth/auth_session.dart';
import 'package:sereno_ya/models/auth/authenticated_user.dart';
import 'package:sereno_ya/models/auth/result.dart';
import 'package:sereno_ya/models/auth/user_role.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:sereno_ya/ui/core/theme/theme.dart';
import 'package:sereno_ya/ui/officer/officer_home_screen.dart';
import 'package:sereno_ya/ui/officer/officer_detail_screen.dart';
import 'package:sereno_ya/ui/officer/officer_start_tab.dart';
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

class FakeLocationService extends CitizenLocationService {
  @override
  Future<LatLng> currentLocation() async => const LatLng(-13.65, -73.36);
}

class FailingLocationService extends CitizenLocationService {
  @override
  Future<LatLng> currentLocation() async {
    throw const LocationFailure('Sin ubicación');
  }
}

void main() {
  test(
    'evita aceptar dos veces y actualiza aceptados al cerrar en el servidor',
    () async {
      final repository = FakeRepository();
      final model = OfficerIncidentsViewModel(
        repository,
        session,
        locationService: FakeLocationService(),
      );
      await Future<void>.delayed(Duration.zero);
      final first = model.acceptIncident('incident-test');
      expect(await model.acceptIncident('incident-test'), isNotNull);
      await first;
      expect(repository.acceptCount, 1);
      expect(model.accepted, hasLength(1));
      repository.currentStatus = 'ATTENDED';
      await model.loadInitial(forceRefresh: true);
      expect(model.accepted, isEmpty);
      model.dispose();
    },
  );

  test('sin GPS la aceptación informa el error sin llamar a la API', () async {
    final repository = FakeRepository();
    final model = OfficerIncidentsViewModel(
      repository,
      session,
      locationService: FailingLocationService(),
    );
    await Future<void>.delayed(Duration.zero);
    expect(await model.acceptIncident('incident-test'), 'Sin ubicación');
    expect(repository.acceptCount, 0);
    model.dispose();
  });

  test('sin sesión no consulta métricas ni acepta incidentes', () async {
    final repository = FakeRepository();
    final model = OfficerIncidentsViewModel(
      repository,
      null,
      locationService: FakeLocationService(),
    );
    await model.loadMetrics();
    expect(await model.acceptIncident('incident-test'), isNotNull);
    expect(repository.acceptCount, 0);
    expect(model.totals, isEmpty);
    expect(model.mineIncidents, isEmpty);
    expect(model.mineError, isNotNull);
    model.dispose();
  });

  test('el inicio carga mis incidentes en curso con list-me-sereno', () async {
    final repository = FakeRepository();
    final model = OfficerIncidentsViewModel(
      repository,
      session,
      locationService: FakeLocationService(),
    );
    await Future<void>.delayed(Duration.zero);
    expect(model.mineBusy, isFalse);
    expect(model.mineError, isNull);
    expect(model.mineIncidents, hasLength(2));
    // Se consultan ambos estados activos del sereno.
    expect(repository.lastMineStatus, OfficerIncidentStatus.attending);
    expect(
      model.mineIncidents.map((item) => item.status),
      containsAll([
        OfficerIncidentStatus.enRoute,
        OfficerIncidentStatus.attending,
      ]),
    );
    expect(model.mineHasMore, isTrue);
    await model.loadMoreMine();
    expect(model.mineIncidents, hasLength(2));
    model.dispose();
  });

  test('el inicio solo conserva aceptados en curso en la sesión', () async {
    final repository = FakeRepository();
    final model = OfficerIncidentsViewModel(
      repository,
      session,
      locationService: FakeLocationService(),
    );
    await Future<void>.delayed(Duration.zero);
    await model.acceptIncident('incident-test');
    expect(model.accepted.single.status, OfficerIncidentStatus.enRoute);
    // Si el incidente sale de ACCEPTED, deja de mostrarse en el inicio.
    repository.currentStatus = 'ON_SITE';
    await model.loadInitial(forceRefresh: true);
    expect(model.accepted, isEmpty);
    model.dispose();
  });

  testWidgets('el inicio solo muestra en curso y pendientes', (tester) async {
    final model = OfficerIncidentsViewModel(
      MixedMineRepository(),
      session,
      locationService: FakeLocationService(),
    );
    addTearDown(model.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light, ThemeVariant.normal),
        home: Scaffold(
          body: ListenableBuilder(
            listenable: model,
            builder: (_, _) => OfficerStartTab(
              model: model,
              cardBuilder: (item) => Text('tarjeta-${item.status.name}'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mis incidentes en curso'), findsOneWidget);
    expect(find.text('tarjeta-enRoute'), findsOneWidget);
    expect(find.text('tarjeta-attending'), findsOneWidget);
    expect(find.text('tarjeta-attended'), findsNothing);
    // Los pendientes generales (REQUESTED) se siguen mostrando.
    expect(find.text('Incidentes pendientes'), findsOneWidget);
    expect(find.text('tarjeta-pending'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('el historial muestra lo mínimo sin mapa ni detalle', (
    tester,
  ) async {
    final model = OfficerIncidentsViewModel(
      FakeRepository(),
      session,
      locationService: FakeLocationService(),
    );
    addTearDown(model.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: model,
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light, ThemeVariant.normal),
          home: const OfficerHomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // El inicio conserva el acceso al detalle y al mapa.
    expect(find.text('Ver en el mapa'), findsWidgets);
    expect(find.text('Ver detalle y evidencia'), findsWidgets);
    await tester.tap(find.text('Reportes'));
    await tester.pumpAndSettle();
    // El historial solo muestra la información mínima indispensable.
    expect(find.text('Ver en el mapa'), findsNothing);
    expect(find.text('Ver detalle y evidencia'), findsNothing);
    expect(find.text('Atención ciudadana'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
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
      expect(item('REQUESTED').citizenPhone, isNull);
      expect(item('REQUESTED').citizenId, isNull);
      expect(item('REQUESTED').showsCitizenInfo, isFalse);
      expect(item('ACCEPTED').citizenPhone, '000000000');
      expect(item('ACCEPTED').showsCitizenInfo, isTrue);
      expect(
        elapsedLabel(
          DateTime(2026, 10, 5, 9),
          now: DateTime(2026, 10, 5, 9, 23),
        ),
        'Hace 23 min',
      );
    },
  );

  test('el detalle expone la primera evidencia del listado', () {
    final withEvidence = OfficerIncident.fromJson({
      ...incidentJson('ACCEPTED'),
      'evidences': [
        {
          'id': 'ev-1',
          'fileUrl': 'https://ejemplo.test/ev-1.jpg',
          'fileName': 'ev-1.jpg',
          'fileType': 'image/jpeg',
        },
      ],
    });
    expect(withEvidence.incident.evidences, hasLength(1));
    expect(
      withEvidence.incident.evidence?.fileUrl,
      'https://ejemplo.test/ev-1.jpg',
    );
    expect(item('REQUESTED').incident.evidence, isNull);
  });

  test(
    'servicio usa los contratos v2 de listado, detalle, mis casos y aceptación',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(request);
            final Object data;
            if (request.path == '/incident/accept') {
              data = {
                'incidentId': 'incident-test',
                'assignmentId': 'assignment-test',
                'serenoId': 'test-officer',
                'status': 'ACCEPTED',
              };
            } else if (request.path.contains('/byId-sereno/')) {
              data = incidentJson('ACCEPTED');
            } else {
              data = {
                'content': [incidentJson('REQUESTED')],
                'page': 2,
                'size': 15,
                'totalElements': 31,
                'totalPages': 3,
              };
            }
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
      final repository = OfficerRepository(IncidentApiService(dio));
      final result = await repository.list(
        status: OfficerIncidentStatus.pending,
        page: 2,
      );
      expect(result.data!.totalElements, 31);
      expect(requests.last.path, '/incident/list');
      expect(requests.last.queryParameters['status'], 'REQUESTED');
      expect(requests.last.queryParameters['page'], 2);
      expect(requests.last.queryParameters['sortBy'], 'id');
      expect(requests.last.queryParameters['direction'], 'DESC');
      expect(
        requests.last.queryParameters['fields'],
        contains('citizen.userEntity.phone'),
      );
      expect(
        requests.last.queryParameters['fields'],
        contains('evidences.fileUrl'),
      );
      expect(
        requests.last.queryParameters['fields'],
        isNot(contains('priority')),
      );

      await repository.listMine(status: OfficerIncidentStatus.attended);
      expect(requests.last.path, '/incident/list-me-sereno');
      expect(requests.last.queryParameters['status'], 'ATTENDED');

      final found = await repository.detail('incident-test');
      expect(found.isSuccess, isTrue);
      expect(found.data!.status, OfficerIncidentStatus.enRoute);
      expect(requests.last.path, '/incident/byId-sereno/incident-test');
      expect(requests.last.queryParameters.containsKey('id'), isFalse);
      expect(
        requests.last.queryParameters['fields'],
        contains('citizen.userEntity.phone'),
      );
      expect(
        requests.last.queryParameters['fields'],
        contains('evidences.fileUrl'),
      );

      await repository.accept(
        id: 'incident-test',
        latitude: -13.65,
        longitude: -73.36,
      );
      expect(requests.last.path, '/incident/accept');
      expect(requests.last.data['incidentId'], 'incident-test');
      expect(requests.last.data['acceptedLatitude'], -13.65);
      expect(requests.last.data['acceptedLongitude'], -73.36);

      final onSite = await repository.markOnSite(id: 'incident-test');
      expect(onSite.isSuccess, isTrue);
      expect(requests.last.path, '/incident/onSite/incident-test');
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
      final result = await OfficerRepository(IncidentApiService(dio)).list();
      expect(result.isSuccess, isFalse);
      expect(result.failure!.code, AuthFailureCode.network);
    },
  );

  test(
    'descarta respuestas viejas al cambiar de filtro y al desmontarse',
    () async {
      final repository = FakeRepository()
        ..hold = true
        ..holdMine = true;
      final model = OfficerIncidentsViewModel(
        repository,
        session,
        locationService: FakeLocationService(),
      );
      // El constructor encola la lista principal y mis incidentes.
      final old = repository.pending.removeAt(0);
      repository.pending
          .removeAt(0)
          .complete(Result.success(page('REQUESTED')));
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
    final model = OfficerIncidentsViewModel(
      FakeRepository(),
      session,
      locationService: FakeLocationService(),
    );
    await Future<void>.delayed(Duration.zero);
    await model.loadMore();
    expect(model.incidents.length, 1);
    await model.loadMetrics();
    expect(model.totals[OfficerIncidentStatus.pending], 31);
    expect(model.accepted, isEmpty);
    await model.acceptIncident('incident-test');
    expect(model.accepted.single.status, OfficerIncidentStatus.enRoute);
    model.dispose();
  });

  test('detalle acepta pendientes con GPS y bloquea otros estados', () async {
    final repository = FakeRepository();
    final model = OfficerDetailViewModel(
      repository,
      'incident-test',
      locationService: FakeLocationService(),
    );
    await Future<void>.delayed(Duration.zero);
    expect(await model.act(), isNull);
    expect(model.item!.status, OfficerIncidentStatus.enRoute);
    expect(model.acceptedHere, isTrue);
    // La API v2 no expone llegada/atendido: no hay más acciones.
    expect(await model.act(), isNotNull);
    expect(repository.acceptCount, 1);
    model.dispose();
  });

  test('detalle sin GPS informa el error sin aceptar', () async {
    final repository = FakeRepository();
    final model = OfficerDetailViewModel(
      repository,
      'incident-test',
      locationService: FailingLocationService(),
    );
    await Future<void>.delayed(Duration.zero);
    expect(await model.act(), 'Sin ubicación');
    expect(repository.acceptCount, 0);
    model.dispose();
  });

  test(
    'un error al releer una mutación exitosa no deja acciones obsoletas',
    () async {
      final repository = FakeRepository();
      final model = OfficerDetailViewModel(
        repository,
        'incident-test',
        locationService: FakeLocationService(),
      );
      await Future<void>.delayed(Duration.zero);
      repository.detailFails = true;
      expect(await model.act(), isNull);
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
        final model = OfficerIncidentsViewModel(
          FakeRepository(),
          session,
          locationService: FakeLocationService(),
        );
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
        expect(find.text('Mis incidentes en curso'), findsOneWidget);
        // La bolsa general aporta el pendiente con botón de aceptar; mis
        // incidentes en curso (ACCEPTED) no muestran ese botón.
        expect(find.text('Aceptar y enviar respuesta'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.runAsync(
          () => _capture(boundary, 'inicio-${brightness.name}-$width'),
        );
        await tester.tap(find.text('Reportes'));
        await tester.pumpAndSettle();
        expect(find.text('31'), findsNWidgets(4));
        // El historial es mínimo: sin detalle ni mapa.
        expect(find.text('Ver detalle y evidencia'), findsNothing);
        expect(find.text('Ver en el mapa'), findsNothing);
        await tester.runAsync(
          () => _capture(boundary, 'reportes-${brightness.name}-$width'),
        );
        expect(tester.takeException(), isNull);
        // El detalle se abre desde el inicio, no desde el historial.
        await tester.tap(find.text('Inicio'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Ver detalle y evidencia').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ver detalle y evidencia').first);
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
  FakeRepository() : super(IncidentApiService(Dio()));
  String currentStatus = 'REQUESTED';
  bool hold = false;
  bool holdMine = false;
  bool detailFails = false;
  int acceptCount = 0;
  OfficerIncidentStatus? lastMineStatus;
  final pending = <Completer<Result<PageResponse<OfficerIncident>>>>[];
  @override
  Future<Result<PageResponse<OfficerIncident>>> list({
    OfficerIncidentStatus? status,
    int page = 0,
    int size = 15,
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
  Future<Result<PageResponse<OfficerIncident>>> listMine({
    OfficerIncidentStatus? status,
    int page = 0,
    int size = 15,
  }) {
    // [holdMine] permite retener mis casos en pruebas de generación sin
    // afectar a las demás pruebas, donde responde de inmediato.
    if (holdMine) {
      final completer = Completer<Result<PageResponse<OfficerIncident>>>();
      pending.add(completer);
      return completer.future;
    }
    lastMineStatus = status;
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
  Future<Result<bool>> accept({
    required String id,
    required double latitude,
    required double longitude,
  }) async {
    acceptCount++;
    currentStatus = 'ACCEPTED';
    return Result.success(true);
  }
}

/// Mis incidentes con estados mixtos para probar el filtro del inicio.
class MixedMineRepository extends FakeRepository {
  @override
  Future<Result<PageResponse<OfficerIncident>>> listMine({
    OfficerIncidentStatus? status,
    int page = 0,
    int size = 15,
  }) {
    lastMineStatus = status;
    return Future.value(
      Result.success(
        PageResponse(
          content: [
            OfficerIncident.fromJson(incidentJson('ACCEPTED', id: 'en-curso')),
            OfficerIncident.fromJson(incidentJson('ON_SITE', id: 'en-sitio')),
            OfficerIncident.fromJson(incidentJson('ATTENDED', id: 'atendido')),
          ],
          page: page,
          size: 15,
          totalElements: 3,
          totalPages: 1,
        ),
      ),
    );
  }
}
