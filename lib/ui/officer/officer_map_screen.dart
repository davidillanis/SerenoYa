import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sereno_ya/config/maps_config.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/data/services/maps/maps_loader.dart';
import 'package:sereno_ya/ui/core/widgets/map_style.dart';

class OfficerMapScreen extends StatefulWidget {
  const OfficerMapScreen({super.key, required this.item});

  final OfficerIncident item;

  @override
  State<OfficerMapScreen> createState() => _OfficerMapScreenState();
}

class _OfficerMapScreenState extends State<OfficerMapScreen> {
  Future<void>? _initialization;

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
            Expanded(child: _map(context)),
          ],
        ),
      ),
    );
  }

  Widget _map(BuildContext context) {
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
    final position = LatLng(incident.latitude, incident.longitude);
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
        return GoogleMap(
          initialCameraPosition: CameraPosition(target: position, zoom: 16),
          style: Theme.of(context).brightness == Brightness.dark
              ? darkMapStyle(context)
              : null,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          compassEnabled: true,
          markers: {
            Marker(
              markerId: MarkerId(widget.item.id),
              position: position,
              infoWindow: InfoWindow(
                title: incident.category?.name ?? 'Incidente ciudadano',
                snippet: incident.referenceAddress,
              ),
            ),
          },
        );
      },
    );
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
