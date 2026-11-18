import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/citizen/incident.dart';
import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/data/models/citizen/incident_create_request.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';
import 'package:sereno_ya/data/services/maps/citizen_location_service.dart';
import 'package:sereno_ya/models/auth/result.dart';
import 'package:sereno_ya/ui/auth/view_models/session_view_model.dart';
import 'package:sereno_ya/ui/citizen/home/citizen_home_tab.dart';
import 'package:sereno_ya/ui/citizen/home/view_models/quick_sos_view_model.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:sereno_ya/ui/core/theme/theme.dart';

import 'auth_view_models_test.dart' show RecordingAuthRepository;

void main() {
  test(
    'SOS envía GPS y la imagen referencial con categoryName directo',
    () async {
      final repository = _SosRepository();
      final model = QuickSosViewModel(
        repository,
        locationService: _SosLocationService(),
      );
      addTearDown(model.dispose);

      expect(await model.submit(), isTrue);
      expect(repository.request?.categoryName, 'Emergencia');
      expect(repository.request?.toJson()['categoryName'], 'Emergencia');
      expect(repository.categoryRequests, 0);
      expect(repository.request?.evidences, hasLength(1));
      expect(
        repository.request?.evidences.single.fileUrl,
        'https://cdn-icons-png.flaticon.com/128/9356/9356599.png',
      );
      expect(repository.request?.evidences.single.fileName, '9356599.png');
      expect(repository.request?.evidences.single.fileType, 'image/png');
      expect(repository.request?.toJson()['evidences'], [
        {
          'fileUrl': 'https://cdn-icons-png.flaticon.com/128/9356/9356599.png',
          'fileName': '9356599.png',
          'fileType': 'image/png',
        },
      ]);
      expect(repository.request?.latitude, -13.65);
      expect(repository.request?.currentLong, -73.36);
      expect(model.usedFallbackLocation, isFalse);
    },
  );

  test('SOS marca el punto de referencia cuando falla el GPS', () async {
    final repository = _SosRepository();
    final model = QuickSosViewModel(
      repository,
      locationService: _SosLocationService(fail: true),
    );
    addTearDown(model.dispose);

    expect(await model.submit(), isTrue);
    expect(model.usedFallbackLocation, isTrue);
    expect(
      repository.request?.latitude,
      QuickSosViewModel.fallbackLocation.latitude,
    );
    expect(repository.request?.description, contains('no verificada'));
    expect(
      repository.request?.referenceAddress,
      contains('ubicación real desconocida'),
    );
  });

  test('crea SOS sin consultar categorías', () async {
    final repository = _SosRepository();
    final model = QuickSosViewModel(
      repository,
      locationService: _SosLocationService(),
    );
    addTearDown(model.dispose);

    expect(await model.submit(), isTrue);
    expect(repository.request?.categoryName, 'Emergencia');
    expect(repository.categoryRequests, 0);
  });

  testWidgets('el botón SOS presenta configurar y crear incidencia', (
    tester,
  ) async {
    final session = SessionViewModel(RecordingAuthRepository());
    final repository = _SosRepository();
    final model = QuickSosViewModel(
      repository,
      locationService: _SosLocationService(),
    );
    addTearDown(session.dispose);
    addTearDown(model.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: session),
          ChangeNotifierProvider.value(value: model),
        ],
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light, ThemeVariant.normal),
          home: const Scaffold(body: CitizenHomeTab()),
        ),
      ),
    );
    await tester.tap(find.text('SOS'));
    await tester.pumpAndSettle();

    expect(find.text('Configurar'), findsOneWidget);
    expect(find.text('Crear incidencia'), findsOneWidget);
    expect(find.textContaining('ubicación no verificada'), findsOneWidget);
    expect(find.textContaining('imagen referencial'), findsOneWidget);
    expect(repository.request, isNull);

    await tester.tap(find.text('Crear incidencia'));
    await tester.pumpAndSettle();
    expect(repository.request?.categoryName, 'Emergencia');
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('SOS enviado correctamente.'), findsOneWidget);
  });
}

class _SosRepository implements IncidentRepository {
  IncidentCreateRequest? request;
  int categoryRequests = 0;

  @override
  Future<Result<List<IncidentCategory>>> getCategories() async {
    categoryRequests++;
    throw StateError('El SOS no debe consultar categorías');
  }

  @override
  Future<Result<Incident>> createIncident(IncidentCreateRequest request) async {
    this.request = request;
    return Result.success(
      Incident(
        id: 'incident-1',
        status: 'REQUESTED',
        description: request.description,
        latitude: request.latitude,
        longitude: request.longitude,
        currentLat: request.currentLat,
        currentLong: request.currentLong,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SosLocationService extends CitizenLocationService {
  _SosLocationService({this.fail = false});

  final bool fail;

  @override
  Future<LatLng> currentLocation() async {
    if (fail) throw const LocationFailure('GPS no disponible');
    return const LatLng(-13.65, -73.36);
  }
}
