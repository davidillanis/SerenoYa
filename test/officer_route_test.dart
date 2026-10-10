import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/data/models/route/route_compare.dart';
import 'package:sereno_ya/data/repositories/route/route_compare_repository.dart';
import 'package:sereno_ya/data/services/api/route_api_service.dart';
import 'package:sereno_ya/data/services/maps/citizen_location_service.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';
import 'package:sereno_ya/models/auth/result.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:sereno_ya/ui/core/theme/theme.dart';
import 'package:sereno_ya/ui/officer/officer_map_screen.dart';
import 'package:sereno_ya/ui/officer/view_models/officer_route_view_model.dart';

// Ejemplo documentado por Google para polilíneas codificadas:
// (38.5, -120.2), (40.7, -120.95), (43.252, -126.453).
const _encoded = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';

const _options = [
  RouteOption(
    mode: RouteMode.drive,
    distanceKm: 5.23,
    durationMinutes: 12,
    trafficDurationMinutes: 15,
    polyline: _encoded,
  ),
  RouteOption(
    mode: RouteMode.twoWheeler,
    distanceKm: 5.1,
    durationMinutes: 14,
    trafficDurationMinutes: 16,
    polyline: '??',
  ),
  RouteOption(
    mode: RouteMode.bicycle,
    distanceKm: 4.9,
    durationMinutes: 20,
    polyline: '??',
  ),
];

OfficerIncident _incident({String status = 'ACCEPTED'}) =>
    OfficerIncident.fromJson({
      'id': 'route-test',
      'status': status,
      'description': 'Incidente de prueba',
      'latitude': -13.65,
      'longitude': -73.36,
      'referenceAddress': 'Referencia del incidente',
    });

class FakeRouteCompareRepository extends RouteCompareRepository {
  FakeRouteCompareRepository() : super(RouteApiService(Dio()));
  bool fail = false;
  int compareCalls = 0;
  RouteCoordinate? lastOrigin;
  RouteCoordinate? lastDestination;

  @override
  Future<Result<List<RouteOption>>> compare({
    required RouteCoordinate origin,
    required RouteCoordinate destination,
  }) async {
    compareCalls++;
    lastOrigin = origin;
    lastDestination = destination;
    if (fail) {
      return Result.failure(
        const AuthFailure(AuthFailureCode.network, 'Sin conexión'),
      );
    }
    return Result.success(_options);
  }
}

class FakeLocationService extends CitizenLocationService {
  final movements = StreamController<LatLng>();

  @override
  Future<LatLng> currentLocation() async => const LatLng(-13.63, -73.35);

  @override
  Stream<LatLng> watchLocation({int distanceFilterMeters = 10}) =>
      movements.stream;
}

class FailingLocationService extends CitizenLocationService {
  @override
  Future<LatLng> currentLocation() async {
    throw const LocationFailure('Sin ubicación');
  }

  @override
  Stream<LatLng> watchLocation({int distanceFilterMeters = 10}) =>
      Stream.error(const LocationFailure('Sin ubicación'));
}

OfficerRouteViewModel _model({bool fail = false, bool noGps = false}) {
  final repository = FakeRouteCompareRepository()..fail = fail;
  return OfficerRouteViewModel(
    repository,
    _incident(),
    locationService: noGps ? FailingLocationService() : FakeLocationService(),
  );
}

void main() {
  test('decodePolyline decodifica el ejemplo documentado por Google', () {
    final points = decodePolyline(_encoded);
    expect(points, hasLength(3));
    expect(points[0].latitude, closeTo(38.5, 1e-5));
    expect(points[0].longitude, closeTo(-120.2, 1e-5));
    expect(points[1].latitude, closeTo(40.7, 1e-5));
    expect(points[1].longitude, closeTo(-120.95, 1e-5));
    expect(points[2].latitude, closeTo(43.252, 1e-5));
    expect(points[2].longitude, closeTo(-126.453, 1e-5));
    expect(decodePolyline(''), isEmpty);
  });

  test(
    'carga rutas con el GPS como origen y selecciona la más rápida',
    () async {
      final model = _model();
      addTearDown(model.dispose);
      await model.load();
      expect(model.loading, isFalse);
      expect(model.error, isNull);
      expect(model.options, hasLength(3));
      expect(model.selected, 0);
      expect(model.selectedOption!.mode, RouteMode.drive);
      expect(model.selectedPoints, hasLength(3));
      expect(model.origin, const LatLng(-13.63, -73.35));
    },
  );

  test('envía el GPS del sereno y el incidente como destino', () async {
    final repository = FakeRouteCompareRepository();
    final model = OfficerRouteViewModel(
      repository,
      _incident(),
      locationService: FakeLocationService(),
    );
    addTearDown(model.dispose);
    await model.load();
    expect(repository.lastOrigin!.latitude, -13.63);
    expect(repository.lastOrigin!.longitude, -73.35);
    expect(repository.lastDestination!.latitude, -13.65);
    expect(repository.lastDestination!.longitude, -73.36);
  });

  test('permite cambiar de modo y conserva la selección más rápida', () async {
    final model = _model();
    addTearDown(model.dispose);
    await model.load();
    model.select(2);
    expect(model.selected, 2);
    expect(model.selectedOption!.mode, RouteMode.bicycle);
    model.select(99);
    expect(model.selected, 2);
  });

  test('sin GPS informa el error sin llamar a la API', () async {
    final repository = FakeRouteCompareRepository();
    final model = OfficerRouteViewModel(
      repository,
      _incident(),
      locationService: FailingLocationService(),
    );
    addTearDown(model.dispose);
    await model.load();
    expect(model.error, 'Sin ubicación');
    expect(model.options, isEmpty);
    expect(repository.lastOrigin, isNull);
  });

  test('un error de red expone el mensaje con reintento', () async {
    final repository = FakeRouteCompareRepository()..fail = true;
    final model = OfficerRouteViewModel(
      repository,
      _incident(),
      locationService: FakeLocationService(),
    );
    addTearDown(model.dispose);
    await model.load();
    expect(model.error, 'Sin conexión');
    expect(model.options, isEmpty);
    repository.fail = false;
    await model.load();
    expect(model.error, isNull);
    expect(model.options, hasLength(3));
  });

  test('la ruta solo se habilita en aceptados o en curso', () {
    expect(_incident(status: 'REQUESTED').showsRoute, isFalse);
    expect(_incident(status: 'ACCEPTED').showsRoute, isTrue);
    expect(_incident(status: 'ON_SITE').showsRoute, isTrue);
    expect(_incident(status: 'ATTENDED').showsRoute, isFalse);
    expect(_incident(status: 'CANCELLED_BY_CITIZEN').showsRoute, isFalse);
    expect(_incident(status: 'EXPIRED').showsRoute, isFalse);
  });

  test('en pendiente ubica al sereno sin comparar rutas', () async {
    final repository = FakeRouteCompareRepository();
    final model = OfficerRouteViewModel(
      repository,
      _incident(status: 'REQUESTED'),
      locationService: FakeLocationService(),
    );
    addTearDown(model.dispose);
    expect(model.routeEnabled, isFalse);
    await model.load();
    expect(model.loading, isFalse);
    expect(model.error, isNull);
    expect(model.origin, const LatLng(-13.63, -73.35));
    expect(model.options, isEmpty);
    expect(repository.lastOrigin, isNull);
    expect(repository.lastDestination, isNull);
  });

  test('la ubicación del sereno se actualiza mientras se mueve', () async {
    final location = FakeLocationService();
    addTearDown(location.movements.close);
    final model = OfficerRouteViewModel(
      FakeRouteCompareRepository(),
      _incident(),
      locationService: location,
    );
    addTearDown(model.dispose);
    await model.load();
    expect(model.origin, const LatLng(-13.63, -73.35));
    location.movements.add(const LatLng(-13.64, -73.36));
    await Future<void>.delayed(Duration.zero);
    expect(model.origin, const LatLng(-13.64, -73.36));
    expect(model.selectedOption!.mode, RouteMode.drive);
  });

  test('la comparación se difiere hasta presionar «Iniciar»', () async {
    final repository = FakeRouteCompareRepository();
    final model = OfficerRouteViewModel(
      repository,
      _incident(),
      locationService: FakeLocationService(),
    );
    addTearDown(model.dispose);
    expect(model.needsStart, isTrue);
    expect(model.started, isFalse);
    expect(repository.compareCalls, 0);
    await model.load();
    expect(model.started, isTrue);
    expect(model.needsStart, isFalse);
    expect(repository.compareCalls, 1);
  });

  test('en pendiente no se pide iniciar la comparación', () {
    final model = OfficerRouteViewModel(
      FakeRouteCompareRepository(),
      _incident(status: 'REQUESTED'),
      locationService: FakeLocationService(),
    );
    addTearDown(model.dispose);
    expect(model.needsStart, isFalse);
    expect(model.started, isFalse);
  });

  testWidgets('el botón «Iniciar» llama a la API y muestra las rutas', (
    tester,
  ) async {
    final repository = FakeRouteCompareRepository();
    final model = OfficerRouteViewModel(
      repository,
      _incident(),
      locationService: FakeLocationService(),
    );
    addTearDown(model.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light, ThemeVariant.normal),
        home: OfficerMapScreen(item: _incident(), routeModel: model),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.compareCalls, 0);
    expect(find.text('Iniciar'), findsOneWidget);
    expect(find.text('Ruta desde tu ubicación'), findsNothing);
    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();
    expect(repository.compareCalls, 1);
    expect(find.text('Iniciar'), findsNothing);
    expect(find.text('Ruta desde tu ubicación'), findsOneWidget);
    expect(find.textContaining('más rápida'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el mapa ofrece las opciones con la más rápida destacada', (
    tester,
  ) async {
    final model = _model();
    addTearDown(model.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light, ThemeVariant.normal),
        home: OfficerMapScreen(item: _incident(), routeModel: model),
      ),
    );
    await model.load();
    await tester.pumpAndSettle();
    expect(find.text('Ruta desde tu ubicación'), findsOneWidget);
    expect(find.textContaining('más rápida'), findsOneWidget);
    expect(find.textContaining('Moto'), findsOneWidget);
    expect(find.textContaining('Bicicleta'), findsOneWidget);
    await tester.tap(find.textContaining('Moto'));
    await tester.pumpAndSettle();
    expect(model.selected, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en pendiente no ofrece rutas pero ubica al sereno', (
    tester,
  ) async {
    final item = _incident(status: 'REQUESTED');
    final model = OfficerRouteViewModel(
      FakeRouteCompareRepository(),
      item,
      locationService: FakeLocationService(),
    );
    addTearDown(model.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light, ThemeVariant.normal),
        home: OfficerMapScreen(item: item, routeModel: model),
      ),
    );
    await model.load();
    await tester.pumpAndSettle();
    expect(find.text('Ruta desde tu ubicación'), findsNothing);
    expect(find.textContaining('más rápida'), findsNothing);
    expect(model.origin, isNotNull);
    expect(model.options, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el mapa muestra el error de rutas con reintento', (
    tester,
  ) async {
    final repository = FakeRouteCompareRepository()..fail = true;
    final model = OfficerRouteViewModel(
      repository,
      _incident(),
      locationService: FakeLocationService(),
    );
    addTearDown(model.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light, ThemeVariant.normal),
        home: OfficerMapScreen(item: _incident(), routeModel: model),
      ),
    );
    await model.load();
    await tester.pumpAndSettle();
    expect(find.text('Sin conexión'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('más rápida'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
