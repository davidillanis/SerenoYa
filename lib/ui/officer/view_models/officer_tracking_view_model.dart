import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository.dart';
import 'package:sereno_ya/data/repositories/officer/officer_repository.dart';
import 'package:sereno_ya/data/repositories/route/route_compare_repository.dart';
import 'package:sereno_ya/data/services/maps/citizen_location_service.dart';
import 'package:sereno_ya/models/auth/auth_state.dart';
import 'package:sereno_ya/ui/officer/view_models/officer_route_view_model.dart';

/// Conserva los recorridos durante la sesión, independientemente del mapa.
/// Solo un incidente puede ocupar el GPS; cerrar sesión libera todos los datos.
class OfficerTrackingViewModel extends ChangeNotifier {
  OfficerTrackingViewModel({
    required AuthRepository authRepository,
    required this._routeRepository,
    required this._officerRepository,
    this._locationServiceFactory,
  }) {
    _onAuthState(authRepository.state);
    _authSubscription = authRepository.states.listen(_onAuthState);
  }

  final RouteCompareRepository _routeRepository;
  final OfficerRepository _officerRepository;
  final CitizenLocationService Function()? _locationServiceFactory;
  late final StreamSubscription<AuthState> _authSubscription;
  final _routes = <String, OfficerRouteViewModel>{};
  String? _userId;
  bool _disposed = false;
  OfficerRouteViewModel? _activeRoute;
  Future<void>? _pendingStop;
  OfficerRouteViewModel? get activeRoute => _activeRoute;

  OfficerRouteViewModel routeFor(OfficerIncident item) {
    return _routes.putIfAbsent(item.id, () {
      late final OfficerRouteViewModel model;
      model = OfficerRouteViewModel(
        _routeRepository,
        item,
        officerRepository: _officerRepository,
        locationService: _locationServiceFactory?.call(),
        canTrack: () =>
            !_disposed &&
            _userId != null &&
            (_activeRoute == null || identical(_activeRoute, model)),
        waitForPreviousStop: () => _pendingStop ?? Future<void>.value(),
      );
      model.addListener(_onRouteChanged);
      return model;
    });
  }

  /// Conserva los recorridos iniciados para no repetir la comparación al
  /// reabrirlos, incluso si el GPS fue detenido o ya se registró la llegada.
  void releaseRoute(OfficerRouteViewModel model) {
    if (model.started || !identical(_routes[model.item.id], model)) return;
    _routes.remove(model.item.id);
    model.removeListener(_onRouteChanged);
    model.dispose();
  }

  void _onRouteChanged() {
    final active = _routes.values.where((route) => route.tracking).firstOrNull;
    if (identical(active, _activeRoute)) return;
    final previous = _activeRoute;
    if (previous != null) _pendingStop = previous.locationStopped;
    _activeRoute = active;
    notifyListeners();
  }

  void _onAuthState(AuthState state) {
    // Renovar el token no interrumpe un recorrido ni crea otra sesión GPS.
    if (state.status == AuthStatus.refreshing) return;
    final userId = state.isAuthenticated ? state.session?.user.id : null;
    if (_userId == userId) return;
    _userId = userId;
    _clearRoutes();
    notifyListeners();
  }

  void _clearRoutes() {
    final active = _activeRoute;
    for (final route in _routes.values) {
      route.removeListener(_onRouteChanged);
      route.dispose();
    }
    _routes.clear();
    if (active != null) _pendingStop = active.locationStopped;
    _activeRoute = null;
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_authSubscription.cancel());
    _clearRoutes();
    super.dispose();
  }
}
