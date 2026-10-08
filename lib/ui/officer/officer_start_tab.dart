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
