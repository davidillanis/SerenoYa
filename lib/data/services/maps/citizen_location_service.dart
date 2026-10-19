import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CitizenLocationService {
  CitizenLocationService({this.backgroundTracking = false});

  /// Solo el seguimiento iniciado por el sereno activa el servicio Android.
  final bool backgroundTracking;

  Future<LatLng> currentLocation() async {
    await _ensurePermission();
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } on TimeoutException {
      throw const LocationFailure(
        'No se pudo obtener tu ubicación a tiempo. Vuelve a intentar.',
      );
    }
  }

  /// Emite la ubicación actual del dispositivo mientras se mueve.
  /// Útil para mostrar al sereno en el mapa de forma efectiva.
  Stream<LatLng> watchLocation({int distanceFilterMeters = 10}) async* {
    await _ensurePermission();
    yield* Geolocator.getPositionStream(
      locationSettings:
          backgroundTracking &&
              !kIsWeb &&
              defaultTargetPlatform == TargetPlatform.android
          ? AndroidSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: distanceFilterMeters,
              intervalDuration: const Duration(seconds: 5),
              foregroundNotificationConfig: const ForegroundNotificationConfig(
                notificationTitle: 'SerenoYa · Seguimiento activo',
                notificationText:
                    'Registraremos tu llegada al incidente. '
                    'Abre SerenoYa para ver o detener el seguimiento.',
                notificationChannelName: 'Seguimiento de incidentes',
                notificationIcon: AndroidResource(name: 'ic_tracking'),
                enableWakeLock: true,
                setOngoing: true,
              ),
            )
          : LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: distanceFilterMeters,
            ),
    ).map((position) => LatLng(position.latitude, position.longitude));
  }

  Future<void> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(
        'Activa la ubicación del dispositivo y vuelve a intentar.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        'Habilita el permiso de ubicación en los ajustes y vuelve a intentar.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        'Permite acceder a tu ubicación para continuar.',
      );
    }
  }
}

class LocationFailure implements Exception {
  const LocationFailure(this.message);
  final String message;
}
