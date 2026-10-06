import 'package:flutter/material.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/officer/view_models/officer_incidents_view_model.dart';
import 'package:sereno_ya/ui/officer/widgets/officer_incidents_list.dart';

class OfficerReportsTab extends StatelessWidget {
  const OfficerReportsTab({
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
          'Resumen de atención',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text('Totales generales de Serenazgo'),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in operationalStatuses)
                SizedBox(
                  width: (constraints.maxWidth - 8) / 2,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${model.totals[status] ?? '—'}',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: context.appColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(status.label),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (model.metricsError != null)
          TextButton.icon(
            onPressed: model.loadMetrics,
            icon: const Icon(Icons.refresh),
            label: Text(model.metricsError!),
          ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Todos'),
              selected: model.filter == null,
              onSelected: (_) => model.selectFilter(null),
            ),
            for (final status in operationalStatuses)
              ChoiceChip(
                label: Text(status.label),
                selected: model.filter == status,
                onSelected: (_) => model.selectFilter(status),
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
