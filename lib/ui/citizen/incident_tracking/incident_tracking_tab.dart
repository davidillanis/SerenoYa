import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/ui/citizen/incident_tracking/view_models/incident_tracking_view_model.dart';
import 'package:sereno_ya/data/models/citizen/incident.dart';
import 'package:go_router/go_router.dart';
import 'package:sereno_ya/routing/route_names.dart';
import 'package:sereno_ya/ui/citizen/widgets/incident_summary_card.dart';

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
                  ? _buildScrollableState(
                      _buildErrorState(context, viewModel.errorMessage!),
                    )
                  : viewModel.incidents.isEmpty
                  ? _buildScrollableState(_buildEmptyState(context))
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: viewModel.incidents.length,
                      itemBuilder: (context, index) {
                        final incident = viewModel.incidents[index];
                        return IncidentSummaryCard(
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

  Widget _buildScrollableState(Widget child) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
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
