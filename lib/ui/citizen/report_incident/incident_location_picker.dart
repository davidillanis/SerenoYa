import 'package:flutter/material.dart';
import 'package:sereno_ya/ui/core/widgets/map_style.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sereno_ya/config/maps_config.dart';
import 'package:sereno_ya/data/services/maps/maps_loader.dart';

class IncidentLocationPicker extends StatefulWidget {
  const IncidentLocationPicker({super.key, required this.initialLocation});

  final LatLng initialLocation;

  @override
  State<IncidentLocationPicker> createState() => _IncidentLocationPickerState();
}

class _IncidentLocationPickerState extends State<IncidentLocationPicker> {
  late LatLng _selectedLocation = widget.initialLocation;
  late Future<void> _initialization = loadGoogleMaps(MapsConfig.apiKey);
  bool _mapReady = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lugar del incidente')),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Partimos de tu ubicación actual. Toca el mapa o arrastra el marcador hasta el lugar del incidente.',
              ),
            ),
            Expanded(
              child: FutureBuilder<void>(
                future: _initialization,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('No se pudo cargar el mapa.'),
                          TextButton(
                            onPressed: () => setState(() {
                              _mapReady = false;
                              _initialization = loadGoogleMaps(
                                MapsConfig.apiKey,
                              );
                            }),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: widget.initialLocation,
                      zoom: 17,
                    ),
                    onMapCreated: (_) {
                      if (mounted) setState(() => _mapReady = true);
                    },
                    style: Theme.of(context).brightness == Brightness.dark
                        ? darkMapStyle(context)
                        : null,
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
                    onTap: (position) =>
                        setState(() => _selectedLocation = position),
                    markers: {
                      Marker(
                        markerId: const MarkerId('incident'),
                        position: _selectedLocation,
                        draggable: true,
                        onDragEnd: (position) =>
                            setState(() => _selectedLocation = position),
                        infoWindow: const InfoWindow(
                          title: 'Lugar del incidente',
                        ),
                      ),
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _mapReady
                      ? () => Navigator.of(context).pop(_selectedLocation)
                      : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar ubicación y enviar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
