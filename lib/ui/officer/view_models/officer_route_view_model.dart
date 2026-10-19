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
    this._officerRepository,
    this._canTrack,
    this._waitForPreviousStop,
    this.arrivalRadiusMeters = defaultArrivalRadiusMeters,
  }) : _locationService =
           locationService ??
           CitizenLocationService(backgroundTracking: item.showsRoute);

  /// Distancia en metros para considerar que el sereno está en el lugar.
  static const double defaultArrivalRadiusMeters = 50;

  final RouteCompareRepository _repository;
  final OfficerIncident item;
  final CitizenLocationService _locationService;
  final OfficerRepository? _officerRepository;
  final bool Function()? _canTrack;
  final Future<void> Function()? _waitForPreviousStop;
  final double arrivalRadiusMeters;
  StreamSubscription<LatLng>? _watch;
  Completer<LatLng?>? _firstPosition;
  Timer? _arrivalRetry;
  Future<void> _watchStopped = Future.value();

  /// Permite que el siguiente incidente espere la liberación del GPS nativo.
  Future<void> get locationStopped => _watchStopped;
  bool _disposed = false;
  int _session = 0;
  bool _compareInProgress = false;
  bool get canStart =>
      !_disposed && !_compareInProgress && !_arrivalInProgress && !arrived;

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
  bool _tracking = false;
  bool get started => _started;
  bool get tracking => _tracking;

  /// La comparación de rutas solo aplica en aceptados o en curso y solo
  /// después de presionar «Iniciar».
  /// La ubicación del sereno ([origin]) se obtiene siempre.
  bool get routeEnabled => item.showsRoute;

  bool get needsStart =>
      routeEnabled &&
      !arrived &&
      !_tracking &&
      !loading &&
      error == null &&
      _options.isEmpty;

  /// La llegada automática solo aplica en aceptados con coordenadas, una vez
  /// iniciado el seguimiento y con repositorio de incidentes disponible.
  bool get canAutoMarkArrival =>
      _officerRepository != null &&
      (item.status == OfficerIncidentStatus.attending || _routeStarted) &&
      item.hasCoordinates &&
      _tracking;

  Future<void> load() async {
    if (loading || !canStart || (_tracking && error == null)) return;
    if (routeEnabled && _canTrack?.call() == false) {
      error =
          'Ya hay otro incidente en seguimiento. '
          'Abre su mapa y detén el seguimiento antes de iniciar este.';
      _notify();
      return;
    }
    final session = ++_session;
    if (routeEnabled) {
      _started = true;
      _tracking = true;
    }
    loading = true;
    error = null;
    _notify();
    late final LatLng? position;
    try {
      // El servicio en primer plano empieza antes de esperar al primer GPS
      // o a la API, para que minimizar durante la carga no lo suspenda.
      // Los mapas sin recorrido solo necesitan una lectura puntual; así no
      // mantienen abierto el stream compartido del seguimiento de Android.
      position = routeEnabled
          ? await _startWatch(session)
          : await _locationService.currentLocation();
    } catch (failure) {
      _locationFailed(failure, session);
      return;
    }
    if (_disposed || session != _session || position == null) return;
    origin = position;
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
    _compareInProgress = true;
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
    _compareInProgress = false;
    // La petición puede haber llegado al servidor aun si se detuvo el GPS.
    // No se vuelve a iniciar el recorrido en el backend al reanudar.
    if (result.isSuccess) _routeStarted = true;
    if (_disposed) return;
    if (session != _session) {
      _notify();
      return;
    }
    loading = false;
    if (result.isSuccess) {
      _options = result.data!;
      _selected = 0;
    } else {
      error = result.failure!.message;
      _tracking = false;
      _cancelWatch();
    }
    _notify();
    if (result.isSuccess) await _checkArrival(origin!);
  }

  Future<LatLng?> _startWatch(int session) async {
    final previousStop = _waitForPreviousStop?.call();
    if (previousStop != null) {
      _watchStopped = Future.wait([_watchStopped, previousStop]).then((_) {});
    }
    await _watchStopped;
    if (_disposed || session != _session) return null;
    final first = Completer<LatLng?>();
    _firstPosition = first;
    _watch = _locationService.watchLocation().listen(
      (current) {
        if (_disposed || session != _session) return;
        origin = current;
        if (!first.isCompleted) {
          first.complete(current);
        } else {
          _notify();
          unawaited(_checkArrival(current));
        }
      },
      onError: (Object failure) {
        if (!first.isCompleted) {
          first.completeError(failure);
        } else {
          _locationFailed(failure, session);
        }
      },
      onDone: () => _locationFailed(
        const LocationFailure(
          'El seguimiento se interrumpió. Vuelve a iniciar.',
        ),
        session,
      ),
    );
    return first.future.timeout(const Duration(seconds: 20));
  }

  void _locationFailed(Object failure, int session) {
    if (_disposed || session != _session) return;
    _session++;
    _tracking = false;
    loading = false;
    _options = [];
    error = switch (failure) {
      LocationFailure() => failure.message,
      LocationServiceDisabledException() =>
        'Activa la ubicación del dispositivo y vuelve a iniciar.',
      PermissionDeniedException() =>
        'Habilita el permiso de ubicación y vuelve a iniciar.',
      TimeoutException() =>
        'No se pudo obtener tu ubicación a tiempo. Vuelve a intentar.',
      _ => 'No se pudo mantener tu ubicación. Vuelve a iniciar el seguimiento.',
    };
    _cancelWatch();
    _notify();
  }

  void _cancelWatch() {
    _arrivalRetry?.cancel();
    _arrivalRetry = null;
    final first = _firstPosition;
    _firstPosition = null;
    if (first != null && !first.isCompleted) first.complete(null);
    final watch = _watch;
    _watch = null;
    if (watch != null) _watchStopped = watch.cancel();
  }

  /// Detiene solo el seguimiento local; no cancela el incidente en el servidor.
  void stopTracking() {
    if (_disposed || !_tracking || _arrivalInProgress) return;
    _session++;
    _tracking = false;
    _cancelWatch();
    origin = null;
    _options = [];
    _selected = 0;
    loading = false;
    error = null;
    arrivalError = null;
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
    _arrivalRetry?.cancel();
    arrivalError = null;
    final session = _session;
    _notify();
    final result = await _officerRepository!.markOnSite(id: item.id);
    if (_disposed) return;
    _arrivalInProgress = false;
    if (result.isSuccess) {
      // Una pérdida de GPS no invalida una llegada ya confirmada por la API.
      arrived = true;
      arrivalError = null;
      error = null;
      _tracking = false;
      _session++;
      _cancelWatch();
    } else if (session == _session && _tracking) {
      arrivalError = result.failure!.message;
      // Reintenta también si el sereno permanece quieto en el destino.
      _arrivalRetry = Timer(const Duration(seconds: 15), () {
        final current = origin;
        if (current != null) unawaited(_checkArrival(current));
      });
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _tracking = false;
    _cancelWatch();
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
