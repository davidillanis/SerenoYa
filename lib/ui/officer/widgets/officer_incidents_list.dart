import 'package:flutter/material.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/officer/view_models/officer_incidents_view_model.dart';

class OfficerIncidentsList extends StatelessWidget {
  const OfficerIncidentsList({
    super.key,
    required this.model,
    required this.cardBuilder,
    required this.header,
  });
  final OfficerIncidentsViewModel model;
  final Widget Function(OfficerIncident) cardBuilder;
  final List<Widget> header;
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        ...header,
        if (model.errorMessage != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(model.errorMessage!),
                  TextButton(
                    onPressed: () => model.loadInitial(forceRefresh: true),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        if (model.isBusy)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!model.isBusy &&
            model.errorMessage == null &&
            model.incidents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 48,
                  color: context.appColors.textTertiary,
                ),
                const SizedBox(height: 16),
                const Text('No hay incidentes para mostrar.'),
                const Text('Desliza hacia abajo para actualizar.'),
              ],
            ),
          ),
        for (final item in model.incidents) cardBuilder(item),
        if (model.hasMore)
          TextButton(
            onPressed: model.isBusy ? null : model.loadMore,
            child: const Text('Cargar más reportes'),
          ),
      ],
    );
  }
}
