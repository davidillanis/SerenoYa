import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/data/services/officer/contact_service.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/core/widgets/evidence_gallery.dart';
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
                      _citizenSection(context, model),
                      if (item.showsCitizenInfo && model.citizen != null)
                        _CitizenContactButtons(
                          item: item,
                          phone: model.citizen!.phone,
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
                            ? () => openIncidentMap(
                                context,
                                item,
                                officerRepository: model.repository,
                              )
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
                        'Evidencia${item.incident.evidences.length > 1 ? 's (${item.incident.evidences.length})' : ''}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      EvidenceGallery(evidences: item.incident.evidences),
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

  Widget _citizenSection(BuildContext context, OfficerDetailViewModel model) {
    final citizen = model.citizen;
    final imageUrl = citizen?.imageUrl?.trim();
    final imageUri = imageUrl == null ? null : Uri.tryParse(imageUrl);
    final hasImage =
        imageUri != null &&
        (imageUri.scheme == 'https' || imageUri.scheme == 'http') &&
        imageUri.host.isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ciudadano', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (!model.item!.showsCitizenInfo)
              const Text('Disponible una vez aceptado el incidente.')
            else if (model.citizenError != null) ...[
              Text(
                model.citizenError!,
                style: TextStyle(color: context.appColors.error),
              ),
              TextButton(
                onPressed: model.load,
                child: const Text('Reintentar'),
              ),
            ] else if (citizen == null)
              const Text('Información del ciudadano no disponible.')
            else ...[
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    child: hasImage
                        ? ClipOval(
                            child: Image.network(
                              imageUrl!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.person_outline),
                            ),
                          )
                        : const Icon(Icons.person_outline),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      citizen.fullName.isEmpty
                          ? 'Nombre no disponible'
                          : citizen.fullName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SelectableText(
                'Teléfono: ${citizen.phone?.trim().isNotEmpty == true ? citizen.phone!.trim() : 'No disponible'}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _actionLabel(OfficerIncidentStatus status) => switch (status) {
    OfficerIncidentStatus.pending => 'Aceptar y enviar respuesta',
    _ => null,
  };

  Future<void> _act(BuildContext context, OfficerDetailViewModel model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_actionLabel(model.item!.status)!),
        content: const Text(
          'Se usará tu ubicación actual para registrar la aceptación.',
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
    final error = await model.act();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Respuesta enviada correctamente.')),
    );
  }
}

/// Contacto directo con el ciudadano: llamada y WhatsApp.
/// Solo se muestra en incidentes aceptados, cuando el teléfono ya está
/// disponible. Sin teléfono no hay acción que lanzar y los botones se
/// deshabilitan.
class _CitizenContactButtons extends StatelessWidget {
  const _CitizenContactButtons({required this.item, required this.phone});
  final OfficerIncident item;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    final hasPhone = telUri(phone ?? '') != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: hasPhone ? () => _call(context, phone!) : null,
              icon: const Icon(Icons.call_outlined),
              label: const Text('Llamar'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: hasPhone ? () => _message(context, phone!) : null,
              icon: const Icon(Icons.chat_outlined),
              label: const Text('WhatsApp'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _call(BuildContext context, String phone) async {
    final ok = await const ContactService().call(phone);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo iniciar la llamada.')),
      );
    }
  }

  Future<void> _message(BuildContext context, String phone) async {
    final category = item.incident.category?.name;
    final ok = await const ContactService().whatsapp(
      phone,
      message:
          'Hola, le escribe el Serenazgo de San Jerónimo por su reporte'
          '${category != null ? ' de $category' : ''}.',
    );
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
      );
    }
  }
}
