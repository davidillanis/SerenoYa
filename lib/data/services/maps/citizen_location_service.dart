import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CitizenLocationService {
  Future<LatLng> currentLocation() async {
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
        'Permite acceder a tu ubicación para elegir el lugar del incidente.',
      );
    }
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
}

class LocationFailure implements Exception {
  const LocationFailure(this.message);
  final String message;
}
