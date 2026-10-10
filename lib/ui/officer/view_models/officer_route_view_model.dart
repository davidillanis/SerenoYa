import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/data/models/route/route_compare.dart';
import 'package:sereno_ya/data/repositories/route/route_compare_repository.dart';
import 'package:sereno_ya/data/services/maps/citizen_location_service.dart';

/// Ruta del sereno hacia el incidente (`POST /route/compare`).
/// Usa el GPS actual como origen y el incidente como destino; la primera
/// opción del backend es la más rápida y queda seleccionada por defecto.
class OfficerRouteViewModel extends ChangeNotifier {
  OfficerRouteViewModel(
    this._repository,
    this.item, {
    CitizenLocationService? locationService,
  }) : _locationService = locationService ?? CitizenLocationService();

  final RouteCompareRepository _repository;
  final OfficerIncident item;
  final CitizenLocationService _locationService;
  StreamSubscription<LatLng>? _watch;
  bool _disposed = false;

  List<RouteOption> _options = [];
  List<RouteOption> get options => List.unmodifiable(_options);

  int _selected = 0;
  int get selected => _selected;

  RouteOption? get selectedOption =>
      _options.isEmpty ? null : _options[_selected];

  List<LatLng> get selectedPoints => selectedOption == null
      ? const []
      : decodePolyline(selectedOption!.polyline);

  LatLng? origin;
  bool loading = false;
  String? error;

  /// Indica si ya se presionó «Iniciar» (o se reintentó) y por tanto ya se
  /// llamó a `POST /route/compare`. Permite diferir la llamada a la API
  /// hasta que el sereno lo pida explícitamente.
  bool _started = false;
  bool get started => _started;

  /// La comparación de rutas solo aplica en aceptados o en curso y solo
  /// después de presionar «Iniciar».
  /// La ubicación del sereno ([origin]) se obtiene siempre.
  bool get routeEnabled => item.showsRoute;

  bool get needsStart =>
      routeEnabled &&
      !_started &&
      !loading &&
      error == null &&
      _options.isEmpty;

  Future<void> load() async {
    if (loading || _disposed) return;
    if (routeEnabled) _started = true;
    loading = true;
    error = null;
    _notify();
    late final LatLng position;
    try {
      position = await _locationService.currentLocation();
    } on LocationFailure catch (failure) {
      if (_disposed) return;
      loading = false;
      error = failure.message;
      _notify();
      return;
    } catch (_) {
      if (_disposed) return;
      loading = false;
      error = 'No se pudo obtener tu ubicación. Vuelve a intentar.';
      _notify();
      return;
    }
    if (_disposed) return;
    origin = position;
    // Seguimiento efectivo: el marcador del sereno se mueve con él.
    // La comparación se calculó con el punto de partida y no se repite.
    _watch ??= _locationService.watchLocation().listen((current) {
      if (_disposed) return;
      origin = current;
      _notify();
    }, onError: (_) {});
    if (!routeEnabled) {
      loading = false;
      _notify();
      return;
    }
    final result = await _repository.compare(
      origin: RouteCoordinate(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
      destination: RouteCoordinate(
        latitude: item.incident.latitude,
        longitude: item.incident.longitude,
      ),
    );
    if (_disposed) return;
    loading = false;
    if (result.isSuccess) {
      _options = result.data!;
      _selected = 0;
    } else {
      error = result.failure!.message;
    }
    _notify();
  }

  void select(int index) {
    if (_disposed ||
        index == _selected ||
        index < 0 ||
        index >= _options.length) {
      return;
    }
    _selected = index;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _watch?.cancel();
    super.dispose();
  }
}

/// Decodifica una polilínea codificada de Google a coordenadas.
/// Sin dependencias externas: implementa el algoritmo de codificación
/// documentado para `RouteOption.polyline`.
List<LatLng> decodePolyline(String encoded) {
  final points = <LatLng>[];
  var index = 0;
  var latitude = 0;
  var longitude = 0;
  while (index < encoded.length) {
    var shift = 0;
    var result = 0;
    int byte;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    latitude += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    shift = 0;
    result = 0;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    longitude += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    points.add(LatLng(latitude / 1e5, longitude / 1e5));
  }
  return points;
}
