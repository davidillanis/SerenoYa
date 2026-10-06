import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/core/widgets/responsive_body.dart';
import 'package:sereno_ya/ui/officer/view_models/officer_detail_view_model.dart';
import 'package:sereno_ya/ui/officer/widgets/officer_incident_card.dart';

// Detail uses the same quiet cards and type hierarchy as the existing citizen
// screens, with the operational action after the evidence and report facts.
class OfficerDetailScreen extends StatelessWidget {
  const OfficerDetailScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final model = context.watch<OfficerDetailViewModel>();
    final item = model.item;
    return PopScope(
      canPop: !model.saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Detalle del incidente')),
        body: ResponsiveBody(
          maxWidth: 720,
          child: model.loading
              ? const Center(child: CircularProgressIndicator())
              : item == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(model.error ?? 'Incidente no disponible'),
                      TextButton(
                        onPressed: model.load,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: model.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      OfficerLabels(item: item),
                      const SizedBox(height: 16),
                      Text(
                        item.incident.category?.name ?? 'Incidente ciudadano',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      if (model.error != null)
                        Text(
                          model.error!,
                          style: TextStyle(color: context.appColors.error),
                        ),
                      _section(
                        context,
                        'Descripción',
                        item.incident.description.isEmpty
                            ? 'Sin descripción'
                            : item.incident.description,
                      ),
                      _section(
                        context,
                        'Ciudadano',
                        [
                          'Identificador: ${item.citizenId ?? 'No disponible'}',
                          'Teléfono: ${item.citizenPhone ?? 'No disponible'}',
                        ].join('\n'),
                      ),
                      _section(
                        context,
                        'Ubicación',
                        [
                          item.incident.referenceAddress ?? 'Sin referencia',
                          if (item.hasCoordinates)
                            '${item.incident.latitude}, ${item.incident.longitude}',
                        ].join('\n'),
                      ),
                      OutlinedButton.icon(
                        onPressed: item.hasCoordinates
                            ? () => openIncidentMap(context, item)
                            : null,
                        icon: const Icon(Icons.near_me_outlined),
                        label: const Text('Ver en el mapa'),
                      ),
                      const SizedBox(height: 16),
                      _section(
                        context,
                        'Fecha y hora',
                        item.incident.createdAt == null
                            ? 'No disponible'
                            : DateFormat('dd/MM/yyyy HH:mm')
                                  .format(item.incident.createdAt!),
                      ),
                      Text(
                        'Evidencia',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (item.incident.evidence?.fileUrl.isNotEmpty == true)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            item.incident.evidence!.fileUrl,
                            height: 240,
                            fit: BoxFit.contain,
                            loadingBuilder: (_, child, progress) =>
                                progress == null
                                ? child
                                : const SizedBox(
                                    height: 240,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                            errorBuilder: (_, _, _) => const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('No se pudo mostrar la evidencia.'),
                            ),
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('No hay evidencia disponible.'),
                        ),
                      for (final event in [
                        ('Aceptado', item.incident.acceptedAt),
                        ('Llegada registrada', item.incident.arrivedAt),
                        ('Atendido', item.incident.attendedAt),
                        ('Cancelado', item.incident.cancelledAt),
                      ])
                        if (event.$2 != null)
                          _section(
                            context,
                            event.$1,
                            DateFormat('dd/MM/yyyy HH:mm').format(event.$2!),
                          ),
                      if (_actionLabel(item.status) case final String label)
                        FilledButton.icon(
                          onPressed: model.saving
                              ? null
                              : () => _act(context, model),
                          icon: model.saving
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(label),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, String value) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: context.appColors.textSecondary),
          ),
          const SizedBox(height: 8),
          SelectableText(value),
        ],
      ),
    ),
  );

  String? _actionLabel(OfficerIncidentStatus status) => switch (status) {
    OfficerIncidentStatus.pending => 'Aceptar y enviar respuesta',
    OfficerIncidentStatus.enRoute => 'Registrar llegada',
    OfficerIncidentStatus.attending => 'Marcar como atendido',
    _ => null,
  };

  Future<void> _act(BuildContext context, OfficerDetailViewModel model) async {
    int? minutes;
    if (model.item!.status == OfficerIncidentStatus.pending) {
      minutes = await requestArrivalTime(context);
      if (minutes == null || !context.mounted) return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_actionLabel(model.item!.status)!),
          content: const Text(
            'Se actualizará el estado del incidente para el ciudadano.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    final error = await model.act(etaMinutes: minutes);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Respuesta enviada correctamente.')),
    );
  }
}
