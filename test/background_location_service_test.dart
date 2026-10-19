import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sereno_ya/data/services/maps/citizen_location_service.dart';

class _Geolocator extends GeolocatorPlatform {
  final positions = StreamController<Position>.broadcast();
  LocationSettings? settings;
  LocationPermission permission = LocationPermission.whileInUse;
  bool enabled = true;
  int permissionRequests = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => enabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    permissionRequests++;
    return permission;
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    settings = locationSettings;
    return positions.stream;
  }
}

void main() {
  late GeolocatorPlatform previous;
  late _Geolocator platform;

  setUp(() {
    previous = GeolocatorPlatform.instance;
    platform = _Geolocator();
    GeolocatorPlatform.instance = platform;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() async {
    GeolocatorPlatform.instance = previous;
    debugDefaultTargetPlatformOverride = null;
    await platform.positions.close();
  });

  test(
    'el seguimiento Android solicita servicio persistente y libera el stream',
    () async {
      final service = CitizenLocationService(backgroundTracking: true);
      final subscription = service.watchLocation().listen((_) {});
      await Future<void>.delayed(Duration.zero);
      final settings = platform.settings! as AndroidSettings;
      final notification = settings.foregroundNotificationConfig!;
      expect(settings.accuracy, LocationAccuracy.high);
      expect(settings.distanceFilter, 10);
      expect(settings.intervalDuration, const Duration(seconds: 5));
      expect(notification.enableWakeLock, isTrue);
      expect(notification.setOngoing, isTrue);
      expect(notification.notificationTitle, contains('Seguimiento activo'));
      expect(platform.positions.hasListener, isTrue);
      expect(platform.permissionRequests, 0);
      await subscription.cancel();
      expect(platform.positions.hasListener, isFalse);
    },
  );

  test('la ubicación habitual no activa el servicio en primer plano', () async {
    final subscription = CitizenLocationService().watchLocation().listen(
      (_) {},
    );
    await Future<void>.delayed(Duration.zero);
    expect(platform.settings, isNot(isA<AndroidSettings>()));
    await subscription.cancel();
  });

  test(
    'iOS conserva la configuración de ubicación sin servicio Android',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final subscription = CitizenLocationService(backgroundTracking: true)
          .watchLocation()
          .listen((_) {});
      await Future<void>.delayed(Duration.zero);
      expect(platform.settings, isNot(isA<AndroidSettings>()));
      await subscription.cancel();
    },
  );

  for (final permission in [
    LocationPermission.denied,
    LocationPermission.deniedForever,
  ]) {
    test('sin permiso $permission no abre el stream nativo', () async {
      platform.permission = permission;
      await expectLater(
        CitizenLocationService(backgroundTracking: true).watchLocation().first,
        throwsA(isA<LocationFailure>()),
      );
      expect(platform.settings, isNull);
      expect(platform.positions.hasListener, isFalse);
    });
  }

  test('sin GPS habilitado no inicia el seguimiento', () async {
    platform.enabled = false;
    await expectLater(
      CitizenLocationService(backgroundTracking: true).watchLocation().first,
      throwsA(isA<LocationFailure>()),
    );
    expect(platform.settings, isNull);
  });
}
