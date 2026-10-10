import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/ui/citizen/report_incident/report_incident_screen.dart';
import 'package:sereno_ya/ui/core/theme/theme.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sereno_ya/data/models/citizen/incident.dart';
import 'package:sereno_ya/data/models/citizen/incident_create_request.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';
import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';
import 'package:sereno_ya/data/services/api/file/image_api_service.dart';
import 'package:sereno_ya/data/services/maps/citizen_location_service.dart';
import 'package:sereno_ya/models/auth/result.dart';
import 'package:sereno_ya/ui/citizen/report_incident/view_models/report_incident_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final brightness in Brightness.values) {
    testWidgets('prepara ubicación y permite reintentar en $brightness', (
      tester,
    ) async {
      final service = _LocationService();
      final model = ReportIncidentViewModel(
        _Repository(),
        _Storage(),
        locationService: service,
      );
      addTearDown(model.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: model,
          child: MaterialApp(
            theme: buildAppTheme(brightness, ThemeVariant.normal),
            home: const ReportIncidentScreen(),
          ),
        ),
      );
      expect(service.calls, 1);
      await tester.pump();
      expect(
        find.text('Obteniendo tu ubicación mientras completas el reporte...'),
        findsOneWidget,
      );
      service.result.completeError(const LocationFailure('Activa el GPS'));
      await tester.pumpAndSettle();
      final retry = find.text('Reintentar ubicación');
      await tester.ensureVisible(retry);
      service.result = Completer<LatLng>();
      await tester.tap(retry);
      await tester.pump();
      expect(service.calls, 2);
      service.result.complete(const LatLng(-13.65, -73.36));
      await tester.pumpAndSettle();
      expect(find.text('Ajustar ubicación en el mapa'), findsOneWidget);
      await tester.pump();
      expect(service.calls, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  test('envía el punto elegido en lugar del GPS inicial', () async {
    const channel = MethodChannel('plugins.flutter.io/image_picker');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => '/tmp/evidence.jpg');
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final repository = _Repository();
    final model = ReportIncidentViewModel(repository, _Storage());
    addTearDown(model.dispose);
    model.setSelectedCategory(
      IncidentCategory(id: 'category', name: 'Incendio', description: ''),
    );
    await model.pickImage(ImageSource.gallery);
    await model.submitIncident(
      description: 'Incendio',
      referenceAddress: 'Plaza',
      location: const LatLng(-13.64, -73.35),
    );
    expect(repository.request?.categoryName, 'Incendio');
    expect(repository.request?.latitude, -13.64);
    expect(repository.request?.longitude, -73.35);
    expect(repository.request?.evidences, hasLength(1));
  });
  test('envía varias evidencias en el mismo reporte', () async {
    const channel = MethodChannel('plugins.flutter.io/image_picker');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => '/tmp/evidence.jpg');
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final repository = _Repository();
    final model = ReportIncidentViewModel(repository, _Storage());
    addTearDown(model.dispose);
    model.setSelectedCategory(
      IncidentCategory(id: 'category', name: 'Incendio', description: ''),
    );
    await model.pickImage(ImageSource.gallery);
    await model.pickImage(ImageSource.camera);
    expect(model.evidenceCount, 2);
    await model.submitIncident(
      description: 'Incendio',
      referenceAddress: 'Plaza',
      location: const LatLng(-13.64, -73.35),
    );
    expect(repository.request?.evidences, hasLength(2));
    model.removeImageAt(0);
    expect(model.evidenceCount, 1);
  });
  test('obtiene el GPS sin enviar y evita solicitudes duplicadas', () async {
    final service = _LocationService();
    final model = ReportIncidentViewModel(
      _Repository(),
      StorageService(),
      locationService: service,
    );
    addTearDown(model.dispose);
    final pending = model.locateCitizen();
    expect(model.isLocating, isTrue);
    expect(await model.locateCitizen(), isNull);
    service.result.complete(const LatLng(-13.65, -73.36));
    expect(await pending, const LatLng(-13.65, -73.36));
    expect(model.isLocating, isFalse);
    expect(model.errorMessage, isNull);
    expect(service.calls, 1);
  });

  test('muestra el error de permiso y permite volver a intentar', () async {
    final service = _LocationService();
    final model = ReportIncidentViewModel(
      _Repository(),
      StorageService(),
      locationService: service,
    );
    addTearDown(model.dispose);
    await Future<void>.delayed(Duration.zero);
    final pending = model.locateCitizen();
    service.result.completeError(const LocationFailure('Activa el GPS'));
    expect(await pending, isNull);
    expect(model.errorMessage, 'Activa el GPS');
    expect(model.isLocating, isFalse);
    service.result = Completer<LatLng>();
    final retry = model.locateCitizen();
    service.result.complete(const LatLng(-13.64, -73.35));
    expect(await retry, const LatLng(-13.64, -73.35));
    expect(model.errorMessage, isNull);
  });

  test('no notifica tras cerrar la pantalla durante la búsqueda', () async {
    final service = _LocationService();
    final model = ReportIncidentViewModel(
      _Repository(),
      StorageService(),
      locationService: service,
    );
    final pending = model.locateCitizen();
    model.dispose();
    service.result.complete(const LatLng(-13.65, -73.36));
    await pending;
  });
}

class _LocationService extends CitizenLocationService {
  var result = Completer<LatLng>();
  int calls = 0;

  @override
  Future<LatLng> currentLocation() {
    calls++;
    return result.future;
  }
}

class _Repository implements IncidentRepository {
  IncidentCreateRequest? request;
  @override
  Future<Result<Incident>> createIncident(IncidentCreateRequest request) async {
    this.request = request;
    return Result.failure(const AuthFailure(AuthFailureCode.server, 'Prueba'));
  }

  @override
  Future<Result<List<IncidentCategory>>> getCategories() async =>
      Result.success([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Storage extends StorageService {
  @override
  Future<ImageUploadResponse> uploadImage({
    required File file,
    String bucket = 'SERENO_YA',
    String folder = 'GENERAL',
  }) async => const ImageUploadResponse(
    fileKey: 'evidence.jpg',
    publicUrl: 'https://example.com/evidence.jpg',
    contentType: 'image/jpeg',
    sizeBytes: 1,
    category: 'INCIDENTS',
  );
}
