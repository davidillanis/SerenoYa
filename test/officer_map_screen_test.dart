import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:sereno_ya/ui/core/theme/theme.dart';
import 'package:sereno_ya/ui/officer/officer_map_screen.dart';
import 'package:sereno_ya/ui/officer/widgets/officer_incident_card.dart';

OfficerIncident incident({bool coordinates = true}) =>
    OfficerIncident.fromJson({
      'id': 'map-test',
      'status': 'REQUESTED',
      'description': 'Incidente de prueba',
      'referenceAddress': 'Referencia del incidente',
      if (coordinates) 'latitude': -13.65,
      if (coordinates) 'longitude': -73.36,
    });

void main() {
  for (final brightness in Brightness.values) {
    for (final width in [320.0, 1000.0]) {
      testWidgets('abre y cierra el mapa interno ${brightness.name} $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: MaterialApp(
              theme: buildAppTheme(brightness, ThemeVariant.normal),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: OfficerIncidentCard(item: incident(), onOpen: () {}),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Ver en el mapa'));
        await tester.pumpAndSettle();
        expect(find.byType(OfficerMapScreen), findsOneWidget);
        expect(find.text('Referencia del incidente'), findsOneWidget);
        expect(
          find.text('El mapa no está disponible en este momento.'),
          findsOneWidget,
        );
        expect(find.byType(GoogleMap), findsNothing);
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('MAP_SCREENSHOTS')) {
          await tester.runAsync(() async {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File('/tmp/officer-map-${brightness.name}-$width.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(OfficerMapScreen), findsNothing);
        expect(find.byType(OfficerIncidentCard), findsOneWidget);
      });
    }
  }

  testWidgets('sin coordenadas no crea un mapa ni inventa una ubicación', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: OfficerMapScreen(item: incident(coordinates: false))),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Este incidente no tiene una ubicación disponible.'),
      findsOneWidget,
    );
    expect(find.byType(GoogleMap), findsNothing);
  });

  testWidgets('desactiva el acceso al mapa cuando faltan coordenadas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light, ThemeVariant.normal),
        home: Scaffold(
          body: OfficerIncidentCard(
            item: incident(coordinates: false),
            onOpen: () {},
          ),
        ),
      ),
    );
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
  });

  testWidgets('muestra alternativa en escritorio nativo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: OfficerMapScreen(item: incident())),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('El mapa está disponible en Android, iOS y la versión web.'),
      findsOneWidget,
    );
    expect(find.byType(GoogleMap), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
