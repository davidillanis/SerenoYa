import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository.dart';
import 'package:sereno_ya/data/repositories/route/route_compare_repository.dart';
import 'package:sereno_ya/data/services/maps/citizen_location_service.dart';
import 'package:sereno_ya/models/auth/auth_session.dart';
import 'package:sereno_ya/models/auth/auth_state.dart';
import 'package:sereno_ya/models/auth/authenticated_user.dart';
import 'package:sereno_ya/models/auth/user_role.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:sereno_ya/ui/core/theme/theme.dart';
import 'package:sereno_ya/ui/officer/view_models/officer_tracking_view_model.dart';
import 'package:sereno_ya/ui/officer/widgets/officer_incident_card.dart';

import 'officer_route_test.dart'
    show
        AtSiteLocationService,
        FakeLocationService,
        FakeOfficerRepository,
        FakeRouteCompareRepository;

OfficerIncident _incident({
  String id = 'tracking-test',
  String status = 'ACCEPTED',
}) => OfficerIncident.fromJson({
  'id': id,
  'status': status,
  'latitude': -13.65,
  'longitude': -73.36,
});

class _AuthRepository extends Fake implements AuthRepository {
  final events = StreamController<AuthState>.broadcast(sync: true);

  @override
  AuthState state = const AuthState.unauthenticated();

  @override
  Stream<AuthState> get states => events.stream;

  void emit(AuthState value) {
    state = value;
    events.add(value);
  }

  void signIn(String id) => emit(
    AuthState(
      status: AuthStatus.authenticated,
      session: AuthSession(
        accessToken: 'test',
        refreshToken: 'test',
        user: AuthenticatedUser(
          id: id,
          email: '',
          firstName: '',
          lastName: '',
          roles: const [UserRole.officer],
        ),
      ),
    ),
  );

  @override
  Future<void> logout() async => emit(const AuthState.unauthenticated());
}

class _WaitingLocation extends CitizenLocationService {
  final movements = StreamController<LatLng>.broadcast();

  @override
  Stream<LatLng> watchLocation({int distanceFilterMeters = 10}) =>
      movements.stream;
}

class _SlowStoppingLocation extends FakeLocationService {
  final stopped = Completer<void>();

  @override
  Stream<LatLng> watchLocation({int distanceFilterMeters = 10}) =>
      Stream.multi((controller) {
        final subscription = super.watchLocation().listen(
          controller.add,
          onError: controller.addError,
        );
        controller.onCancel = () async {
          await stopped.future;
          await subscription.cancel();
        };
      });
}

void main() {
  late _AuthRepository auth;
  late FakeRouteCompareRepository routes;
  late FakeOfficerRepository officer;
  late FakeLocationService location;
  late OfficerTrackingViewModel tracking;

  setUp(() {
    auth = _AuthRepository()..signIn('officer-a');
    routes = FakeRouteCompareRepository();
    officer = FakeOfficerRepository();
    location = FakeLocationService();
    tracking = OfficerTrackingViewModel(
      authRepository: auth,
      routeRepository: routes,
      officerRepository: officer,
      locationServiceFactory: () => location,
    );
  });

  tearDown(() async {
    tracking.dispose();
    await location.movements.close();
    await auth.events.close();
  });

  test(
    'reabrir el mapa conserva recorrido y selección sin comparar otra vez',
    () async {
      final model = tracking.routeFor(_incident());
      await model.load();
      model.select(1);
      tracking.releaseRoute(model);
      final reopened = tracking.routeFor(_incident(status: 'ON_SITE'));
      expect(reopened, same(model));
      expect(reopened.selected, 1);
      expect(tracking.activeRoute, same(model));
      await reopened.load();
      expect(routes.compareCalls, 1);
      location.movements.add(const LatLng(-13.64, -73.36));
      await Future<void>.delayed(Duration.zero);
      expect(reopened.origin, const LatLng(-13.64, -73.36));
    },
  );

  test(
    'solo admite otro incidente después de detener el seguimiento activo',
    () async {
      final first = tracking.routeFor(_incident());
      final second = tracking.routeFor(_incident(id: 'second'));
      final starting = first.load();
      // La exclusión empieza con el botón, antes de obtener el primer GPS.
      await second.load();
      expect(second.tracking, isFalse);
      expect(second.error, contains('Ya hay otro incidente'));
      await starting;
      expect(routes.compareCalls, 1);
      first.stopTracking();
      await Future<void>.delayed(Duration.zero);
      await second.load();
      expect(second.tracking, isTrue);
      expect(second.error, isNull);
      expect(tracking.activeRoute, same(second));
      expect(routes.compareCalls, 2);
    },
  );

  test(
    'el siguiente incidente espera a que se libere el GPS anterior',
    () async {
      final slowLocation = _SlowStoppingLocation();
      var created = 0;
      final owner = OfficerTrackingViewModel(
        authRepository: auth,
        routeRepository: routes,
        officerRepository: officer,
        locationServiceFactory: () => created++ == 0 ? slowLocation : location,
      );
      final first = owner.routeFor(_incident());
      final second = owner.routeFor(_incident(id: 'second'));
      await first.load();
      first.stopTracking();
      final starting = second.load();
      await Future<void>.delayed(Duration.zero);
      expect(slowLocation.movements.hasListener, isTrue);
      expect(location.movements.hasListener, isFalse);
      slowLocation.stopped.complete();
      await starting;
      expect(slowLocation.movements.hasListener, isFalse);
      expect(location.movements.hasListener, isTrue);
      expect(owner.activeRoute, same(second));
      owner.dispose();
      await slowLocation.movements.close();
    },
  );

  test('renovar el token conserva el GPS y cerrar sesión lo cancela', () async {
    final model = tracking.routeFor(_incident());
    await model.load();
    final session = auth.state.session;
    auth.emit(AuthState(status: AuthStatus.refreshing, session: session));
    auth.emit(AuthState(status: AuthStatus.authenticated, session: session));
    expect(tracking.activeRoute, same(model));
    expect(location.movements.hasListener, isTrue);
    await auth.logout();
    await Future<void>.delayed(Duration.zero);
    expect(tracking.activeRoute, isNull);
    expect(model.tracking, isFalse);
    expect(location.movements.hasListener, isFalse);
    location.movements.add(const LatLng(-13.65, -73.36));
    await Future<void>.delayed(Duration.zero);
    expect(officer.onSiteCalls, 0);
    await model.load();
    expect(routes.compareCalls, 1);
  });

  test(
    'cambiar de usuario descarta los recorridos de la sesión anterior',
    () async {
      final model = tracking.routeFor(_incident());
      await model.load();
      auth.signIn('officer-b');
      await Future<void>.delayed(Duration.zero);
      expect(model.tracking, isFalse);
      expect(location.movements.hasListener, isFalse);
      expect(tracking.routeFor(_incident()), isNot(same(model)));
      expect(tracking.activeRoute, isNull);
    },
  );

  test(
    'un error del stream libera el GPS y permite reintentar la llegada',
    () async {
      final model = tracking.routeFor(_incident());
      await model.load();
      location.movements.addError(const LocationFailure('GPS desactivado'));
      await Future<void>.delayed(Duration.zero);
      expect(model.error, 'GPS desactivado');
      expect(model.tracking, isFalse);
      expect(tracking.activeRoute, isNull);
      expect(location.movements.hasListener, isFalse);
      await model.load();
      location.movements.add(const LatLng(-13.65, -73.36));
      await Future<void>.delayed(Duration.zero);
      expect(model.arrived, isTrue);
      expect(model.tracking, isFalse);
      expect(routes.compareCalls, 1);
      expect(officer.onSiteCalls, 1);
    },
  );

  test(
    'cerrar sesión durante la comparación ignora su respuesta tardía',
    () async {
      routes.pending = Completer<void>();
      final model = tracking.routeFor(_incident());
      final loading = model.load();
      await Future<void>.delayed(Duration.zero);
      expect(routes.compareCalls, 1);
      await auth.logout();
      routes.pending!.complete();
      await loading;
      expect(tracking.activeRoute, isNull);
      expect(model.options, isEmpty);
      expect(location.movements.hasListener, isFalse);
      expect(officer.onSiteCalls, 0);
    },
  );

  test('el GPS se detiene solo cuando se confirma la llegada', () async {
    officer.pending = Completer<void>();
    final model = tracking.routeFor(_incident());
    await model.load();
    location.movements.add(const LatLng(-13.65, -73.36));
    await Future<void>.delayed(Duration.zero);
    expect(model.markingArrival, isTrue);
    expect(model.tracking, isTrue);
    expect(location.movements.hasListener, isTrue);
    location.movements.add(const LatLng(-13.65, -73.36));
    await Future<void>.delayed(Duration.zero);
    expect(officer.onSiteCalls, 1);
    officer.pending!.complete();
    await Future<void>.delayed(Duration.zero);
    expect(model.arrived, isTrue);
    expect(model.tracking, isFalse);
    expect(tracking.activeRoute, isNull);
    expect(location.movements.hasListener, isFalse);
  });

  test(
    'cerrar sesión cancela el GPS incluso con una llegada en curso',
    () async {
      officer.pending = Completer<void>();
      final model = tracking.routeFor(_incident());
      await model.load();
      location.movements.add(const LatLng(-13.65, -73.36));
      await Future<void>.delayed(Duration.zero);
      expect(model.markingArrival, isTrue);
      await auth.logout();
      officer.pending!.complete();
      await Future<void>.delayed(Duration.zero);
      expect(model.arrived, isFalse);
      expect(tracking.activeRoute, isNull);
      expect(location.movements.hasListener, isFalse);
    },
  );

  test('conserva la confirmación de llegada si se pierde el GPS durante la petición', () async {
    officer.pending = Completer<void>();
    final model = tracking.routeFor(_incident());
    await model.load();
    location.movements.add(const LatLng(-13.65, -73.36));
    await Future<void>.delayed(Duration.zero);
    location.movements.addError(const LocationFailure('GPS desactivado'));
    await Future<void>.delayed(Duration.zero);
    expect(model.tracking, isFalse);
    await model.load();
    expect(officer.onSiteCalls, 1);
    officer.pending!.complete();
    await Future<void>.delayed(Duration.zero);
    expect(model.arrived, isTrue);
    expect(model.error, isNull);
    expect(model.markingArrival, isFalse);
    expect(location.movements.hasListener, isFalse);
  });

  test('detener mientras espera el primer GPS cancela el inicio', () async {
    final waiting = _WaitingLocation();
    final owner = OfficerTrackingViewModel(
      authRepository: auth,
      routeRepository: routes,
      officerRepository: officer,
      locationServiceFactory: () => waiting,
    );
    final model = owner.routeFor(_incident());
    final loading = model.load();
    await Future<void>.delayed(Duration.zero);
    expect(waiting.movements.hasListener, isTrue);
    model.stopTracking();
    await loading;
    expect(waiting.movements.hasListener, isFalse);
    expect(routes.compareCalls, 0);
    expect(owner.activeRoute, isNull);
    owner.dispose();
    await waiting.movements.close();
  });

  testWidgets(
    'reintenta la llegada sin nuevos movimientos y luego apaga el GPS',
    (tester) async {
      final atSite = AtSiteLocationService();
      final owner = OfficerTrackingViewModel(
        authRepository: auth,
        routeRepository: routes,
        officerRepository: officer..fail = true,
        locationServiceFactory: () => atSite,
      );
      final model = owner.routeFor(_incident());
      await model.load();
      expect(model.arrivalError, 'Sin conexión');
      expect(model.tracking, isTrue);
      officer.fail = false;
      await tester.pump(const Duration(seconds: 15));
      expect(model.arrived, isTrue);
      expect(model.tracking, isFalse);
      expect(officer.onSiteCalls, 2);
      expect(atSite.movements.hasListener, isFalse);
      await tester.pump(const Duration(seconds: 30));
      expect(officer.onSiteCalls, 2);
      owner.dispose();
      await atSite.movements.close();
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'continúa fuera del mapa y con la app pausada: ${brightness.name}',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<RouteCompareRepository>.value(value: routes),
              ChangeNotifierProvider<OfficerTrackingViewModel>.value(
                value: tracking,
              ),
            ],
            child: MaterialApp(
              theme: buildAppTheme(brightness, ThemeVariant.normal),
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => openIncidentMap(context, _incident()),
                    child: const Text('Abrir mapa'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Abrir mapa'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Iniciar Seguimiento'));
        await tester.pumpAndSettle();
        final model = tracking.activeRoute!;
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(model.tracking, isTrue);
        expect(location.movements.hasListener, isTrue);
        await tester.tap(find.text('Abrir mapa'));
        await tester.pumpAndSettle();
        expect(find.text('Detener seguimiento'), findsOneWidget);
        expect(find.text('Iniciar Seguimiento'), findsNothing);
        expect(routes.compareCalls, 1);
        await tester.pageBack();
        await tester.pumpAndSettle();
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        location.movements.add(const LatLng(-13.65, -73.36));
        await tester.pump();
        expect(officer.onSiteCalls, 1);
        expect(model.arrived, isTrue);
        expect(location.movements.hasListener, isFalse);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.tap(find.text('Abrir mapa'));
        await tester.pumpAndSettle();
        expect(
          find.text('Llegada registrada automáticamente.'),
          findsOneWidget,
        );
        expect(find.text('Iniciar Seguimiento'), findsNothing);
        expect(find.text('Detener seguimiento'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
