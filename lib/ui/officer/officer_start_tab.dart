import 'package:flutter/material.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/ui/officer/view_models/officer_incidents_view_model.dart';
import 'package:sereno_ya/ui/officer/widgets/officer_incidents_list.dart';

class OfficerStartTab extends StatelessWidget {
  const OfficerStartTab({
    super.key,
    required this.model,
    required this.cardBuilder,
  });
  final OfficerIncidentsViewModel model;
  final Widget Function(OfficerIncident) cardBuilder;
  @override
  Widget build(BuildContext context) {
    // Evita duplicar la tarjeta recién aceptada en sesión, que también
    // llega por `list-me-sereno` una vez que el backend la asigna.
    final acceptedIds = model.acceptedIds;
    final mine = [
      for (final item in model.mineIncidents)
        if (!acceptedIds.contains(item.id)) item,
    ];
    return OfficerIncidentsList(
      model: model,
      cardBuilder: cardBuilder,
      header: [
        Text(
          'Tu atención hace la diferencia',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        for (final item in model.accepted) cardBuilder(item),
        const SizedBox(height: 24),
        Text('Mis incidentes', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (model.mineBusy && mine.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (model.mineError != null && mine.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(model.mineError!),
                  TextButton(
                    onPressed: model.loadMine,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          )
        else if (mine.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No tienes incidentes asignados.'),
          )
        else
          for (final item in mine) cardBuilder(item),
        if (model.mineHasMore)
          TextButton(
            onPressed: model.mineBusy ? null : model.loadMoreMine,
            child: const Text('Cargar más asignados'),
          ),
        const SizedBox(height: 24),
        Text(
          'Incidentes pendientes',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
