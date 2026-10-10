import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sereno_ya/config/maps_config.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/data/models/route/route_compare.dart';
import 'package:sereno_ya/data/services/maps/maps_loader.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/core/widgets/map_style.dart';
import 'package:sereno_ya/ui/officer/view_models/officer_route_view_model.dart';

class OfficerMapScreen extends StatefulWidget {
  const OfficerMapScreen({super.key, required this.item, this.routeModel});

  final OfficerIncident item;

  /// Comparación de rutas GPS del sereno al incidente. Cuando es `null`
  /// el mapa muestra solo el marcador, como antes.
  final OfficerRouteViewModel? routeModel;

  @override
  State<OfficerMapScreen> createState() => _OfficerMapScreenState();
}

class _OfficerMapScreenState extends State<OfficerMapScreen> {
  Future<void>? _initialization;
  final _mapController = Completer<GoogleMapController>();
  String? _fittedRouteKey;

  @override
  void initState() {
    super.initState();
    if (widget.item.hasCoordinates &&
        MapsConfig.isSupported &&
        MapsConfig.apiKey.isNotEmpty) {
      _initialization = loadGoogleMaps(MapsConfig.apiKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final incident = widget.item.incident;
    final routeModel = widget.routeModel;
    return Scaffold(
      appBar: AppBar(title: const Text('Ubicación del incidente')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_outlined),
                title: Text(incident.category?.name ?? 'Incidente ciudadano'),
                subtitle: Text(
                  incident.referenceAddress?.isNotEmpty == true
                      ? incident.referenceAddress!
                      : 'Ubicación reportada por el ciudadano',
                ),
              ),
            ),
            if (routeModel != null && widget.item.hasCoordinates)
              ListenableBuilder(
                listenable: routeModel,
                builder: (context, _) => _routeSection(context, routeModel),
              ),
            Expanded(
              child: routeModel == null
                  ? _map(context, null)
                  : ListenableBuilder(
                      listenable: routeModel,
                      builder: (context, _) {
                        _fitRoute(routeModel);
                        return _map(context, routeModel);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeSection(BuildContext context, OfficerRouteViewModel routes) {
    // Sin ruta comparada (p. ej. pendiente) solo se muestra la ubicación
    // del sereno en el mapa, sin sección de opciones.
    if (!routes.routeEnabled) return const SizedBox.shrink();
    // En ACCEPTED / ON_SITE la llamada a `POST /route/compare` se difiere
    // hasta que el sereno presione «Iniciar».
    if (routes.needsStart) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Obtén la ruta más rápida y activa el seguimiento hasta el lugar.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: context.appColors.textSecondary),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: routes.load,
              icon: const Icon(Icons.navigation_outlined),
              label: const Text('Iniciar'),
            ),
          ],
        ),
      );
    }
    if (routes.loading && routes.options.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('Buscando la ruta más rápida…')),
          ],
        ),
      );
    }
    if (routes.error != null && routes.options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: [
            Expanded(child: Text(routes.error!)),
            TextButton(onPressed: routes.load, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (routes.options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ruta desde tu ubicación',
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: context.appColors.textSecondary),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < routes.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_optionLabel(routes.options[i], i == 0)),
                      selected: routes.selected == i,
                      onSelected: (_) => routes.select(i),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _optionLabel(RouteOption option, bool isFastest) {
    final distance = option.distanceKm == null
        ? ''
        : ' · ${option.distanceKm!.toStringAsFixed(1)} km';
    final fastest = isFastest ? ' · más rápida' : '';
    return '${option.mode.label} · ${option.effectiveMinutes} min$distance$fastest';
  }

  Widget _map(BuildContext context, OfficerRouteViewModel? routes) {
    if (!widget.item.hasCoordinates) {
      return _message('Este incidente no tiene una ubicación disponible.');
    }
    if (!MapsConfig.isSupported) {
      return _message(
        'El mapa está disponible en Android, iOS y la versión web.',
      );
    }
    if (MapsConfig.apiKey.isEmpty) {
      return _message('El mapa no está disponible en este momento.');
    }
    final incident = widget.item.incident;
    final destination = LatLng(incident.latitude, incident.longitude);
    final markers = {
      Marker(
        markerId: MarkerId(widget.item.id),
        position: destination,
        infoWindow: InfoWindow(
          title: incident.category?.name ?? 'Incidente ciudadano',
          snippet: incident.referenceAddress,
        ),
      ),
    };
    final polylines = <Polyline>{};
    final points = routes?.selectedPoints ?? const <LatLng>[];
    if (points.length > 1) {
      polylines.add(
        Polyline(
          polylineId: PolylineId(
            'route-${routes!.selectedOption!.mode.apiValue}',
          ),
          points: points,
          color: context.appColors.primary,
          width: 5,
        ),
      );
    }
    final origin = routes?.origin;
    if (origin != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('officer-origin'),
          position: origin,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Tu ubicación'),
        ),
      );
    }
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _message(
            'No se pudo cargar el mapa. Revisa tu conexión.',
            retry: true,
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: destination,
                zoom: 16,
              ),
              onMapCreated: (controller) {
                if (!_mapController.isCompleted) {
                  _mapController.complete(controller);
                }
                if (routes != null) _fitRoute(routes);
              },
              style: Theme.of(context).brightness == Brightness.dark
                  ? darkMapStyle(context)
                  : null,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              myLocationEnabled: routes?.origin != null,
              compassEnabled: true,
              markers: markers,
              polylines: polylines,
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'officer-my-location',
                    tooltip: 'Ir a mi ubicación',
                    onPressed: () => _goToMyLocation(routes),
                    child: const Icon(Icons.my_location_outlined),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.small(
                    heroTag: 'officer-incident-location',
                    tooltip: 'Ir al lugar del incidente',
                    onPressed: _goToIncident,
                    child: const Icon(Icons.location_on_outlined),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Centra la cámara en la ubicación actual del sereno (seguimiento).
  /// Si aún no hay ubicación, invita a presionar «Iniciar» primero.
  Future<void> _goToMyLocation(OfficerRouteViewModel? routes) async {
    final origin = routes?.origin;
    if (origin == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Presiona «Iniciar» para activar tu ubicación.'),
        ),
      );
      return;
    }
    if (!_mapController.isCompleted) return;
    try {
      final controller = await _mapController.future;
      await controller.animateCamera(CameraUpdate.newLatLngZoom(origin, 16));
    } catch (_) {
      // La cámara puede no estar lista; se conserva el encuadre actual.
    }
  }

  /// Centra la cámara en el lugar del incidente.
  Future<void> _goToIncident() async {
    if (!widget.item.hasCoordinates || !_mapController.isCompleted) return;
    final incident = widget.item.incident;
    try {
      final controller = await _mapController.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(incident.latitude, incident.longitude),
          16,
        ),
      );
    } catch (_) {
      // La cámara puede no estar lista; se conserva el encuadre actual.
    }
  }

  /// Encuadra la cámara a la ruta seleccionada cuando el mapa y los puntos
  /// ya están listos. Se ejecuta como efecto post-frame, no durante el build.
  void _fitRoute(OfficerRouteViewModel routes) {
    final points = routes.selectedPoints;
    if (points.length < 2 || !_mapController.isCompleted) return;
    final key =
        '${routes.selected}:${points.length}:${points.first}:'
        '${points.last}';
    if (key == _fittedRouteKey) return;
    _fittedRouteKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_mapController.isCompleted) return;
      var minLat = points.first.latitude;
      var maxLat = minLat;
      var minLng = points.first.longitude;
      var maxLng = minLng;
      for (final point in points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }
      try {
        await _mapController.future.then(
          (controller) => controller.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(minLat, minLng),
                northeast: LatLng(maxLat, maxLng),
              ),
              64,
            ),
          ),
        );
      } catch (_) {
        // La cámara puede no estar lista; se conserva el encuadre inicial.
      }
    });
  }

  Widget _message(String text, {bool retry = false}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, size: 40),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center),
          if (retry)
            TextButton(
              onPressed: () => setState(() {
                _initialization = loadGoogleMaps(MapsConfig.apiKey);
              }),
              child: const Text('Reintentar'),
            ),
        ],
      ),
    ),
  );
}
