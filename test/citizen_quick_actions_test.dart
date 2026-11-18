import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/services/local/citizen/police_station_catalog.dart';
import 'package:sereno_ya/data/services/maps/nearby_police_service.dart';
import 'package:sereno_ya/data/services/officer/contact_service.dart';
import 'package:sereno_ya/ui/auth/view_models/session_view_model.dart';
import 'package:sereno_ya/ui/citizen/citizen_home_screen.dart';
import 'package:sereno_ya/ui/citizen/home/citizen_home_tab.dart';
import 'package:sereno_ya/ui/citizen/home/emergency_numbers_screen.dart';
import 'package:sereno_ya/ui/citizen/home/nearby_police_stations_screen.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:sereno_ya/ui/core/theme/theme.dart';

import 'auth_view_models_test.dart' show RecordingAuthRepository;

class _NearbyPolice extends NearbyPoliceService {
  int calls = 0;
  Completer<bool>? pending;
  bool opens = true;
  Object? failure;
  String? destination;

  @override
  Future<bool> openDirections(String destination) async {
    calls++;
    this.destination = destination;
    if (failure != null) throw failure!;
    return pending?.future ?? opens;
  }
}

class _Contact extends ContactService {
  String? called;
  bool opens = true;

  @override
  Future<bool> call(String phone) async {
    called = phone;
    return opens;
  }
}

void main() {
  test(
    'la búsqueda usa las coordenadas sin un lugar fijo ni teléfono inventado',
    () {
      final uri = nearbyPoliceUri(-13.65, -73.36);
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/search/');
      expect(uri.queryParameters['query'], contains('-13.65,-73.36'));
      expect(uri.queryParameters['query'], contains('comisarías'));
    },
  );

  test('la ruta usa la sede elegida como destino en Google Maps', () {
    final uri = policeDirectionsUri(
      'Comisaría PNP Andahuaylas, Avenida Perú 189',
    );
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters['destination'], contains('Avenida Perú 189'));
  });

  test('el directorio local incluye cuatro sedes con ubicación', () {
    expect(andahuaylasPoliceStations, hasLength(4));
    expect(
      andahuaylasPoliceStations.map((station) => station.district),
      containsAll(<String>['Andahuaylas', 'San Jerónimo', 'Talavera']),
    );
    for (final station in andahuaylasPoliceStations) {
      expect(station.address, isNotEmpty);
      expect(station.mapQuery, contains(station.name));
    }
  });

  for (final brightness in Brightness.values) {
    testWidgets('tres acciones rápidas funcionan en ${brightness.name}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = _NearbyPolice();
      final session = SessionViewModel(RecordingAuthRepository());
      addTearDown(session.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<SessionViewModel>.value(
          value: session,
          child: MaterialApp(
            theme: buildAppTheme(brightness, ThemeVariant.normal),
            home: Scaffold(body: CitizenHomeTab(nearbyPoliceService: service)),
          ),
        ),
      );
      expect(find.text('SOS'), findsOneWidget);
      expect(find.text('Serenazgo San Jerónimo'), findsNothing);
      expect(find.byType(ActionCard), findsNWidgets(3));
      expect(find.text('Usaremos tu ubicación'), findsOneWidget);
      expect(find.text('Ver direcciones y rutas en Maps'), findsOneWidget);

      await tester.ensureVisible(find.text('Comisarías cercanas'));
      await tester.tap(find.text('Comisarías cercanas'));
      await tester.pumpAndSettle();
      expect(find.text('Comisarías de Andahuaylas'), findsOneWidget);
      expect(find.text('Comisaría PNP Andahuaylas'), findsOneWidget);
      expect(find.text('Comisaría PNP San Jerónimo'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Comisaría PNP Talavera'), 200);
      expect(find.text('Comisaría PNP Talavera'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Comisaría de Familia Andahuaylas'),
        200,
      );
      expect(find.text('Comisaría de Familia Andahuaylas'), findsOneWidget);

      final familyCard = find.ancestor(
        of: find.text('Comisaría de Familia Andahuaylas'),
        matching: find.byType(Card),
      );
      final directions = find.descendant(
        of: familyCard,
        matching: find.text('Cómo llegar'),
      );
      await tester.tap(directions);
      await tester.pump();
      expect(service.calls, 1);
      expect(service.destination, contains('Jirón Carmen 542'));
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Números de emergencia'));
      await tester.tap(find.text('Números de emergencia'));
      await tester.pumpAndSettle();
      expect(find.text('Serenazgo San Jerónimo'), findsOneWidget);
      expect(find.textContaining('990 223 044'), findsOneWidget);
      expect(find.text('PNP San Jerónimo'), findsOneWidget);
      expect(find.textContaining('980 122 039'), findsOneWidget);
      expect(find.text('Defensa Civil'), findsOneWidget);
      expect(find.textContaining('920 052 070'), findsOneWidget);
      expect(find.text('Centro de Salud'), findsOneWidget);
      expect(find.textContaining('948 993 737'), findsOneWidget);
      expect(find.text('Central de Bomberos'), findsOneWidget);
      expect(find.textContaining('953 624 686'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Consejos de seguridad'));
      await tester.tap(find.text('Consejos de seguridad'));
      await tester.pumpAndSettle();
      expect(find.text('En la calle'), findsOneWidget);
      expect(find.text('Ante una situación de riesgo'), findsOneWidget);
      expect(find.text('Al reportar un incidente'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'no abre dos rutas a la vez e informa si Maps no está disponible',
    (tester) async {
      final service = _NearbyPolice()..pending = Completer<bool>();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.light, ThemeVariant.normal),
          home: NearbyPoliceStationsScreen(nearbyPoliceService: service),
        ),
      );
      final directions = find.text('Cómo llegar').first;
      await tester.tap(directions);
      await tester.pump();
      expect(find.text('Abriendo Maps…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(directions);
      expect(service.calls, 1);
      service.pending!.complete(false);
      await tester.pump();
      expect(
        find.textContaining('No se pudo abrir Google Maps'),
        findsOneWidget,
      );
      expect(find.widgetWithText(SnackBarAction, 'REINTENTAR'), findsOneWidget);

      service.failure = Exception('Maps no disponible');
      await tester.tap(directions);
      await tester.pump();
      expect(
        find.text('No se pudo abrir la ruta. Vuelve a intentar.'),
        findsOneWidget,
      );
      expect(service.calls, 2);
    },
  );

  testWidgets(
    'los números abren el marcador y muestran un error si no está disponible',
    (tester) async {
      final contact = _Contact();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.light, ThemeVariant.normal),
          home: EmergencyNumbersScreen(contactService: contact),
        ),
      );
      await tester.tap(find.textContaining('990 223 044'));
      await tester.pump();
      expect(contact.called, '990223044');
      contact.opens = false;
      await tester.tap(find.textContaining('980 122 039'));
      await tester.pump();
      expect(contact.called, '980122039');
      expect(
        find.text('No se pudo abrir el marcador telefónico.'),
        findsOneWidget,
      );
    },
  );
}
