import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/data/repositories/route/route_compare_repository.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/officer/officer_map_screen.dart';
import 'package:sereno_ya/ui/officer/view_models/officer_route_view_model.dart';

// Operational cards: action first, 16px inset, 8px rhythm, theme surfaces and
// semantic status colors. Location and elapsed time remain visible at a glance.
class OfficerIncidentCard extends StatelessWidget {
  const OfficerIncidentCard({
    super.key,
    required this.item,
    required this.onOpen,
    this.onAccept,
    this.busy = false,
  });
  final OfficerIncident item;
  final VoidCallback onOpen;
  final VoidCallback? onAccept;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final incident = item.incident;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.appColors.borderVariant),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OfficerLabels(item: item),
            const SizedBox(height: 12),
            Text(
              incident.category?.name ?? 'Incidente ciudadano',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              incident.description.isEmpty
                  ? 'Sin descripción'
                  : incident.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: context.appColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    incident.referenceAddress?.isNotEmpty == true
                        ? incident.referenceAddress!
                        : 'Ubicación enviada por GPS',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              elapsedLabel(incident.createdAt),
              style: TextStyle(color: context.appColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Ver detalle y evidencia'),
            ),
            if (onAccept != null &&
                item.status == OfficerIncidentStatus.pending)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : onAccept,
                  icon: busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Aceptar y enviar respuesta'),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: item.hasCoordinates
                    ? () => openIncidentMap(context, item)
                    : null,
                icon: const Icon(Icons.near_me_outlined),
                label: const Text('Ver en el mapa'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OfficerLabels extends StatelessWidget {
  const OfficerLabels({super.key, required this.item});
  final OfficerIncident item;
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusColor = switch (item.status) {
      OfficerIncidentStatus.pending => colors.warning,
      OfficerIncidentStatus.attended => colors.success,
      OfficerIncidentStatus.enRoute ||
      OfficerIncidentStatus.attending => colors.info,
      _ => colors.textSecondary,
    };
    final priorityColor = switch (item.priority) {
      IncidentPriority.high => colors.error,
      IncidentPriority.medium => colors.warning,
      IncidentPriority.low => colors.success,
      _ => colors.textSecondary,
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _label(item.status.label, statusColor),
        _label(item.priorityLabel, priorityColor),
      ],
    );
  }

  Widget _label(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    ),
  );
}

String elapsedLabel(DateTime? date, {DateTime? now}) {
  if (date == null) return 'Fecha no disponible';
  final duration = (now ?? DateTime.now()).difference(date);
  if (duration.inMinutes < 1) return 'Reportado hace un momento';
  if (duration.inHours < 1) return 'Hace ${duration.inMinutes} min';
  if (duration.inDays < 1) return 'Hace ${duration.inHours} h';
  return 'Hace ${duration.inDays} días';
}

Future<void> openIncidentMap(BuildContext context, OfficerIncident item) async {
  // La comparación de rutas es opcional: sin repositorio disponible el mapa
  // muestra solo el marcador, como antes.
  RouteCompareRepository? routes;
  try {
    routes = context.read<RouteCompareRepository>();
  } catch (_) {
    routes = null;
  }
  final repository = routes;
  OfficerRouteViewModel? routeModel;
  if (repository != null && item.hasCoordinates) {
    routeModel = OfficerRouteViewModel(repository, item)..load();
  }
  try {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => OfficerMapScreen(item: item, routeModel: routeModel),
      ),
    );
  } finally {
    routeModel?.dispose();
  }
}
