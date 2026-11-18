import 'package:flutter/material.dart';
import 'package:sereno_ya/data/models/citizen/police_station.dart';
import 'package:sereno_ya/data/services/local/citizen/police_station_catalog.dart';
import 'package:sereno_ya/data/services/maps/nearby_police_service.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/core/widgets/responsive_body.dart';

class NearbyPoliceStationsScreen extends StatefulWidget {
  const NearbyPoliceStationsScreen({
    super.key,
    this.nearbyPoliceService,
    this.stations = andahuaylasPoliceStations,
  });

  final NearbyPoliceService? nearbyPoliceService;
  final List<PoliceStation> stations;

  @override
  State<NearbyPoliceStationsScreen> createState() =>
      _NearbyPoliceStationsScreenState();
}

class _NearbyPoliceStationsScreenState
    extends State<NearbyPoliceStationsScreen> {
  String? _openingStationId;

  Future<void> _openDirections(PoliceStation station) async {
    if (_openingStationId != null) return;
    setState(() => _openingStationId = station.id);
    String? error;
    try {
      final opened = await (widget.nearbyPoliceService ?? NearbyPoliceService())
          .openDirections(station.mapQuery);
      if (!opened) {
        error = 'No se pudo abrir Google Maps. Revisa si tienes una aplicación de mapas disponible.';
      }
    } catch (_) {
      error = 'No se pudo abrir la ruta. Vuelve a intentar.';
    }
    if (!mounted) return;
    setState(() => _openingStationId = null);
    if (error == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(error),
        action: SnackBarAction(
          label: 'REINTENTAR',
          onPressed: () => _openDirections(station),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Comisarías de Andahuaylas')),
    body: SafeArea(
      child: ResponsiveBody(
        maxWidth: 680,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Directorio local',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: context.appColors.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Elige una sede para abrir la ruta desde tu ubicación en Google Maps.',
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: context.appColors.text, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.appColors.infoLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: context.appColors.info,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Las ubicaciones son referenciales. Google Maps confirmará el punto y calculará la ruta final.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appColors.text,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            for (final station in widget.stations) ...[
              _PoliceStationCard(
                station: station,
                loading: _openingStationId == station.id,
                enabled: _openingStationId == null,
                onDirections: () => _openDirections(station),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    ),
  );
}

class _PoliceStationCard extends StatelessWidget {
  const _PoliceStationCard({
    required this.station,
    required this.loading,
    required this.enabled,
    required this.onDirections,
  });

  final PoliceStation station;
  final bool loading;
  final bool enabled;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.appColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_police_outlined,
                  color: context.appColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.appColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      station.type,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: context.appColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: context.appColors.info,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${station.address} · ${station.district}',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: context.appColors.text, height: 1.35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: enabled ? onDirections : null,
              icon: loading
                  ? SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.appColors.primary,
                      ),
                    )
                  : const Icon(Icons.directions_outlined),
              label: Text(loading ? 'Abriendo Maps…' : 'Cómo llegar'),
            ),
          ),
        ],
      ),
    ),
  );
}
