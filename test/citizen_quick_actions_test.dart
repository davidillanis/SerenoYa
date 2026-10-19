import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/services/maps/citizen_location_service.dart';
import 'package:sereno_ya/data/services/maps/nearby_police_service.dart';
import 'package:sereno_ya/data/services/officer/contact_service.dart';
import 'package:sereno_ya/ui/auth/view_models/session_view_model.dart';
import 'package:sereno_ya/ui/citizen/citizen_home_screen.dart';
import 'package:sereno_ya/ui/citizen/home/citizen_home_tab.dart';
import 'package:sereno_ya/ui/citizen/home/emergency_numbers_screen.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:sereno_ya/ui/core/theme/theme.dart';

import 'auth_view_models_test.dart' show RecordingAuthRepository;

class _NearbyPolice extends NearbyPoliceService {
  int calls = 0;
  Completer<bool>? pending;
  bool opens = true;
  Object? failure;

  @override
  Future<bool> openNearby() async {
    calls++;
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

      await tester.ensureVisible(find.text('Comisarías cercanas'));
      await tester.tap(find.text('Comisarías cercanas'));
      await tester.pump();
      expect(service.calls, 1);

      await tester.ensureVisible(find.text('Números de emergencia'));
      await tester.tap(find.text('Números de emergencia'));
      await tester.pumpAndSettle();
      expect(find.text('Policía Nacional'), findsOneWidget);
      expect(find.text('105'), findsOneWidget);
      expect(find.text('Bomberos'), findsOneWidget);
      expect(find.text('116'), findsOneWidget);
      expect(find.text('SAMU'), findsOneWidget);
      expect(find.text('106'), findsOneWidget);
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

  testWidgets('no inicia dos búsquedas a la vez e informa si falta ubicación', (
    tester,
  ) async {
    final service = _NearbyPolice()..pending = Completer<bool>();
    final session = SessionViewModel(RecordingAuthRepository());
    addTearDown(session.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<SessionViewModel>.value(
        value: session,
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light, ThemeVariant.normal),
          home: Scaffold(body: CitizenHomeTab(nearbyPoliceService: service)),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Comisarías cercanas'));
    await tester.tap(find.text('Comisarías cercanas'));
    await tester.pump();
    expect(find.text('Buscando tu ubicación…'), findsOneWidget);
    await tester.tap(find.text('Comisarías cercanas'));
    expect(service.calls, 1);
    service.pending!.complete(false);
    await tester.pump();
    expect(find.textContaining('No se pudo abrir Google Maps'), findsOneWidget);

    service.failure = const LocationFailure('Activa la ubicación');
    await tester.tap(find.text('Comisarías cercanas'));
    await tester.pump();
    expect(find.text('Activa la ubicación'), findsOneWidget);
    expect(service.calls, 2);
  });

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
      await tester.tap(find.text('105'));
      await tester.pump();
      expect(contact.called, '105');
      contact.opens = false;
      await tester.tap(find.text('116'));
      await tester.pump();
      expect(contact.called, '116');
      expect(
        find.text('No se pudo abrir el marcador telefónico.'),
        findsOneWidget,
      );
    },
  );
}
