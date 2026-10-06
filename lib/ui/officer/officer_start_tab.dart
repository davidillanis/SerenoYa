import 'package:flutter/material.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
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
    return OfficerIncidentsList(
      model: model,
      cardBuilder: cardBuilder,
      header: [
        Text(
          'Tu atención hace la diferencia',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'San Jerónimo · Atención ciudadana',
          style: TextStyle(color: context.appColors.textSecondary),
        ),
        const SizedBox(height: 24),
        Text(
          'Aceptados en esta sesión',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Las asignaciones anteriores no están disponibles en el servicio actual.',
        ),
        const SizedBox(height: 16),
        if (model.accepted.isEmpty)
          const Text('Aún no has aceptado incidentes en esta sesión.'),
        for (final item in model.accepted) cardBuilder(item),
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
