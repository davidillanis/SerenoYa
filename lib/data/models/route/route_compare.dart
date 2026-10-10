/// Contrato de `POST /route/compare`.
/// El backend compara rutas en auto, moto, bicicleta y a pie; la primera
/// opción de la lista es la más rápida.
enum RouteMode {
  drive('DRIVE', 'Auto'),
  twoWheeler('TWO_WHEELER', 'Moto'),
  bicycle('BICYCLE', 'Bicicleta'),
  walk('WALK', 'A pie'),
  unknown('', 'No disponible');

  const RouteMode(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static RouteMode parse(String value) => values.firstWhere(
    (mode) => mode.apiValue == value,
    orElse: () => unknown,
  );
}

/// Espejo de `CoordinateDTO`: latitud [-90, 90] y longitud [-180, 180].
class RouteCoordinate {
  const RouteCoordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };
}

/// Espejo de `RouteCompareRequestDTO`.
class RouteCompareRequest {
  const RouteCompareRequest({required this.origin, required this.destination});

  final RouteCoordinate origin;
  final RouteCoordinate destination;

  Map<String, dynamic> toJson() => {
    'originCoordinate': origin.toJson(),
    'destinationCoordinate': destination.toJson(),
  };
}

/// Espejo de `RouteOptionResponseDTO`.
class RouteOption {
  const RouteOption({
    required this.mode,
    this.distanceKm,
    required this.durationMinutes,
    this.trafficDurationMinutes,
    required this.polyline,
  });

  factory RouteOption.fromJson(Map<String, dynamic> json) {
    return RouteOption(
      mode: RouteMode.parse(json['mode']?.toString() ?? ''),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      trafficDurationMinutes: (json['trafficDurationMinutes'] as num?)?.toInt(),
      polyline: json['polyline']?.toString() ?? '',
    );
  }

  final RouteMode mode;
  final double? distanceKm;

  /// Duración sin tráfico, en minutos.
  final int durationMinutes;

  /// Duración con tráfico; `null` en bicicleta y a pie.
  final int? trafficDurationMinutes;

  /// Polilínea codificada para dibujar la ruta en Google Maps.
  final String polyline;

  /// Igual que `effectiveMinutes()` del backend: tráfico si hay, si no base.
  int get effectiveMinutes => trafficDurationMinutes ?? durationMinutes;
}
