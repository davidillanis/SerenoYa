import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/ui/citizen/incident_tracking/view_models/incident_tracking_view_model.dart';
import 'package:sereno_ya/data/models/citizen/incident.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:sereno_ya/routing/route_names.dart';
import 'package:sereno_ya/ui/citizen/incident_tracking/widgets/incident_status_badge.dart';

class IncidentTrackingTab extends StatelessWidget {
  const IncidentTrackingTab({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<IncidentTrackingViewModel>();

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: viewModel.isLoading && viewModel.incidents.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  viewModel.loadActiveIncidents(forceRefresh: true),
              child:
                  viewModel.errorMessage != null && viewModel.incidents.isEmpty
                  ? _buildErrorState(context, viewModel.errorMessage!)
                  : viewModel.incidents.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: viewModel.incidents.length,
                      itemBuilder: (context, index) {
                        final incident = viewModel.incidents[index];
                        return _IncidentCard(
                          incident: incident,
                          onOpen: () => context.push(
                            RouteNames.incidentDetail(incident.id),
                          ),
                          onCancel: () =>
                              _confirmCancel(context, viewModel, incident),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.track_changes_outlined,
            size: 80,
            color: context.appColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes incidencias en curso',
            style: TextStyle(
              fontSize: 18,
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las incidencias que reportes aparecerán aquí.',
            style: TextStyle(color: context.appColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: context.appColors.error),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context
                  .read<IncidentTrackingViewModel>()
                  .loadActiveIncidents(forceRefresh: true),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    IncidentTrackingViewModel viewModel,
    Incident incident,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Incidencia'),
        content: const Text(
          '¿Estás seguro de que deseas cancelar este reporte?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: context.appColors.error,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await viewModel.cancelIncident(incident.id);
      if (context.mounted && viewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage!),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    }
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({
    required this.incident,
    required this.onOpen,
    required this.onCancel,
  });

  final Incident incident;
  final VoidCallback onOpen;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IncidentStatusBadge(status: incident.status),
                  Text(
                    incident.createdAt != null
                        ? DateFormat('dd/MM HH:mm').format(incident.createdAt!)
                        : '',
                    style: TextStyle(
                      color: context.appColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.appColors.infoLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.report_problem,
                      color: context.appColors.info,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incident.category?.name ?? 'Incidencia',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          incident.description.isNotEmpty
                              ? incident.description
                              : 'Sin descripción',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.appColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: context.appColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      incident.referenceAddress?.isNotEmpty == true
                          ? incident.referenceAddress!
                          : 'Ubicación enviada por GPS',
                      style: TextStyle(
                        color: context.appColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (incident.status == 'REQUESTED' ||
                      incident.status == 'ACCEPTED')
                    TextButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Cancelar'),
                      style: TextButton.styleFrom(
                        foregroundColor: context.appColors.error,
                      ),
                    )
                  else
                    Text(
                      'El sereno ya está en el lugar',
                      style: TextStyle(
                        color: context.appColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
