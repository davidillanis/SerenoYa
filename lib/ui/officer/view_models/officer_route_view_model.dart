import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/data/models/route/route_compare.dart';
import 'package:sereno_ya/data/repositories/officer/officer_repository.dart';
import 'package:sereno_ya/data/repositories/route/route_compare_repository.dart';
import 'package:sereno_ya/data/services/maps/citizen_location_service.dart';

/// Ruta del sereno hacia el incidente
/// (`POST /incident/incident-compare/{id}`).
/// Usa el GPS actual como origen y el incidente como destino; la primera
/// opción del backend es la más rápida y queda seleccionada por defecto.
/// Cuando el seguimiento está activo y el sereno llega al lugar, registra
/// la llegada (`POST /incident/onSite/{id}`) de forma automática.
class OfficerRouteViewModel extends ChangeNotifier {
  OfficerRouteViewModel(
    this._repository,
    this.item, {
    CitizenLocationService? locationService,
    OfficerRepository? officerRepository,
    this.arrivalRadiusMeters = defaultArrivalRadiusMeters,
  }) : _locationService = locationService ?? CitizenLocationService(),
       _officerRepository = officerRepository;

  /// Distancia en metros para considerar que el sereno está en el lugar.
  static const double defaultArrivalRadiusMeters = 50;

  final RouteCompareRepository _repository;
  final OfficerIncident item;
  final CitizenLocationService _locationService;
  final OfficerRepository? _officerRepository;
  final double arrivalRadiusMeters;
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

  /// Llegada automática (`POST /incident/onSite/{id}`), sin botón.
  bool _arrivalInProgress = false;
  bool get markingArrival => _arrivalInProgress;
  bool arrived = false;
  String? arrivalError;

  /// Indica si ya se presionó «Iniciar» (o se reintentó) y por tanto ya se
  /// llamó a `POST /incident/incident-compare/{id}`. Permite diferir la
  /// llamada a la API hasta que el sereno lo pida explícitamente.
  bool _started = false;
  bool _routeStarted = false;
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

  /// La llegada automática solo aplica en aceptados con coordenadas, una vez
  /// iniciado el seguimiento y con repositorio de incidentes disponible.
  bool get canAutoMarkArrival =>
      _officerRepository != null &&
      (item.status == OfficerIncidentStatus.attending || _routeStarted) &&
      item.hasCoordinates &&
      _started;

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
      unawaited(_checkArrival(current));
    }, onError: (_) {});
    if (!routeEnabled) {
      loading = false;
      _notify();
      return;
    }
    // ON_SITE ya inició en el backend: no se puede comparar otra vez.
    if (item.status == OfficerIncidentStatus.attending || _routeStarted) {
      loading = false;
      _notify();
      await _checkArrival(origin!);
      return;
    }
    final result = await _repository.compare(
      incidentId: item.id,
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
      _routeStarted = true;
      _options = result.data!;
      _selected = 0;
    } else {
      error = result.failure!.message;
    }
    _notify();
    if (result.isSuccess) await _checkArrival(origin!);
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

  /// Registra la llegada cuando el GPS está dentro del radio del incidente.
  /// Se ejecuta solo una vez, sin confirmación manual. Un error de red deja
  /// [arrivalError] y reintenta con la siguiente actualización del GPS.
  Future<void> _checkArrival(LatLng current) async {
    if (!canAutoMarkArrival || arrived || _arrivalInProgress) return;
    if (!isWithinArrivalRadius(
      current,
      LatLng(item.incident.latitude, item.incident.longitude),
      arrivalRadiusMeters,
    )) {
      return;
    }
    _arrivalInProgress = true;
    arrivalError = null;
    _notify();
    final result = await _officerRepository!.markOnSite(id: item.id);
    if (_disposed) return;
    _arrivalInProgress = false;
    if (result.isSuccess) {
      arrived = true;
      arrivalError = null;
    } else {
      arrivalError = result.failure!.message;
    }
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

/// Indica si [position] está dentro de [radiusMeters] de [destination`.
bool isWithinArrivalRadius(
  LatLng position,
  LatLng destination,
  double radiusMeters,
) {
  final distanceMeters = Geolocator.distanceBetween(
    position.latitude,
    position.longitude,
    destination.latitude,
    destination.longitude,
  );
  return distanceMeters <= radiusMeters;
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
